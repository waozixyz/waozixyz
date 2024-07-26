local lfs = require "lfs"
local utils = require "utils"
local config = require "config"

local writings = {}

local function process_markdown_file(file)
    local md_path = config.writings_dir .. "/" .. file
    local html_path = config.dist_dir .. "/writings/" .. file:gsub("%.md$", ".html")

    local md_content = utils.read_file(md_path)
    if not md_content then return nil end

    local metadata, content = utils.extract_yaml_and_content(md_content)
    local html_content = utils.shell(string.format("echo '%s' | md2html --github", content:gsub("'", "'\\''")))
    html_content = html_content:gsub("<!DOCTYPE html>.-<body>", ""):gsub("</body></html>", "")
    html_content = html_content:gsub("<p>(<img [^>]+>) ?(<img [^>]+>)</p>", "<div class='image-row'>%1%2</div>")
    html_content = utils.sanitize_content(html_content)

    local url = file:gsub("%.md$", "")
    local page_content = config.writing_template
    
    local tags_comma_separated = table.concat(metadata.tags or {}, ", ")

    for key, value in pairs(metadata) do
        if key == "tags" then
            page_content = page_content:gsub("{{TAGS_COMMA_SEPARATED}}", tags_comma_separated)
            local tags_html = ""
            for _, tag in ipairs(value) do
                tags_html = tags_html .. string.format('<span class="tag">%s</span>', tag)
            end
            page_content = page_content:gsub("{{#each TAGS}}.-{{/each}}", tags_html)
        else
            page_content = page_content:gsub("{{" .. key:upper() .. "}}", tostring(value))
        end
    end
    
    page_content = page_content:gsub("{{CONTENT}}", html_content):gsub("{{URL}}", url)

    utils.write_file(html_path, page_content)

    return {
        title = metadata.title or "",
        date = metadata.date or "",
        excerpt = metadata.excerpt or "",
        desc = metadata.desc or "",
        readTime = metadata.readTime or "",
        link = file:gsub("%.md$", ".html"),
        tags = metadata.tags or {},
        url = url,
        content = html_content
    }
end

local function generate_atom_feed(processed_writings, common_data)
    local atom_entries = {}
    for _, writing in ipairs(processed_writings) do
        local pub_date = utils.format_rfc3339_date(writing.date)
        local atom_categories = {}
        for _, tag in ipairs(writing.tags or {}) do
            table.insert(atom_categories, string.format('    <category term="%s"/>', utils.escape_xml(tag)))
        end
        atom_categories = table.concat(atom_categories, "\n")

        table.insert(atom_entries, string.format(
            '<entry>\n' ..
            '    <title>%s</title>\n' ..
            '    <link href="%s/writings/%s"/>\n' ..
            '    <id>%s/writings/%s</id>\n' ..
            '    <published>%s</published>\n' ..
            '    <updated>%s</updated>\n' ..
            '    <summary type="html"><![CDATA[%s]]></summary>\n' ..
            '    <content type="html"><![CDATA[%s]]></content>\n' ..
            '%s\n' ..
            '</entry>',
            utils.escape_xml(writing.title or ""),
            common_data.site_url,
            writing.url,
            common_data.site_url,
            writing.url,
            pub_date,
            pub_date, -- Using the same date for updated, as we don't have separate update dates
            writing.desc or "",
            writing.content,
            atom_categories
        ))
    end

    local atom_template = utils.read_file(config.templates_dir .. "/atom.xml")
    local atom_content = atom_template
    atom_content = atom_content:gsub("{{SITE_TITLE}}", common_data.site_title)
    atom_content = atom_content:gsub("{{SITE_URL}}", common_data.site_url)
    atom_content = atom_content:gsub("{{CURRENT_DATE}}", utils.format_rfc3339_date(processed_writings[1].date))
    atom_content = atom_content:gsub("{{AUTHOR_NAME}}", common_data.author_name)
    atom_content = atom_content:gsub("{{ENTRIES}}", table.concat(atom_entries, "\n"))

    return atom_content
end

local function generate_rss_feed(processed_writings, common_data)
    local rss_items = {}
    for _, writing in ipairs(processed_writings) do
        local rfc822_date = utils.format_rfc822_date(writing.date)
        local rss_categories = {}
        for _, tag in ipairs(writing.tags or {}) do
            table.insert(rss_categories, string.format('    <category>%s</category>', utils.escape_xml(tag)))
        end
        rss_categories = table.concat(rss_categories, "\n")

        table.insert(rss_items, string.format(
            '<item>\n' ..
            '    <title>%s</title>\n' ..
            '    <link>%s/writings/%s</link>\n' ..
            '    <guid>%s/writings/%s</guid>\n' ..
            '    <pubDate>%s</pubDate>\n' ..
            '    <description><![CDATA[%s]]></description>\n' ..
            '%s\n' ..
            '</item>',
            utils.escape_xml(writing.title or ""),
            common_data.site_url,
            writing.url,
            common_data.site_url,
            writing.url,
            rfc822_date,
            writing.content,
            rss_categories
        ))
    end

    local rss_template = utils.read_file(config.templates_dir .. "/rss.xml")
    local rss_content = rss_template
    rss_content = rss_content:gsub("{{SITE_TITLE}}", common_data.site_title)
    rss_content = rss_content:gsub("{{SITE_URL}}", common_data.site_url)
    rss_content = rss_content:gsub("{{SITE_DESCRIPTION}}", common_data.site_description)
    rss_content = rss_content:gsub("{{CURRENT_DATE_RFC822}}", utils.format_rfc822_date(processed_writings[1].date))
    rss_content = rss_content:gsub("{{ITEMS}}", table.concat(rss_items, "\n"))

    return rss_content
end

function writings.process_writings()
    local processed_writings = {}
    for file in lfs.dir(config.writings_dir) do
        if file:match("%.md$") then
            local writing = process_markdown_file(file)
            if writing and writing.date then
                table.insert(processed_writings, writing)
            end
        end
    end
    table.sort(processed_writings, function(a, b)
        if utils.parse_date(a.date) == utils.parse_date(b.date) then
            return table.concat(a.tags or {}) < table.concat(b.tags or {})
        end
        return utils.parse_date(a.date) > utils.parse_date(b.date)
    end)

    -- Prepare common data
    local common_data = {
        site_title = config.site_title,
        site_url = config.site_url,
        site_description = config.site_description,
        current_date = os.date("!%Y-%m-%dT%H:%M:%SZ"),
        current_date_rfc822 = os.date("!%a, %d %b %Y %H:%M:%S GMT"),
        author_name = config.author_name
    }

    -- Generate feeds
    local atom_content = generate_atom_feed(processed_writings, common_data)
    local rss_content = generate_rss_feed(processed_writings, common_data)

    utils.write_file(config.dist_dir .. "/feed.atom", atom_content)
    utils.write_file(config.dist_dir .. "/feed.xml", rss_content)

    return processed_writings
end

return writings
