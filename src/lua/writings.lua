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
        content = html_content or "" -- Add this line
    }
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
    local atom_entries = {}
    local rss_items = {}

    for _, writing in ipairs(processed_writings) do
        local pub_date = os.date("!%Y-%m-%dT%H:%M:%SZ", utils.parse_date(writing.date))
        local rfc822_date = os.date("!%a, %d %b %Y %H:%M:%S GMT", utils.parse_date(writing.date))
        
        local categories = {}
        for _, tag in ipairs(writing.tags or {}) do
            table.insert(categories, string.format('    <category term="%s"/>', utils.escape_xml(tag)))
        end
        categories = table.concat(categories, "\n")

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
            pub_date,
            writing.desc or "",
            writing.content or "",
            categories
        ))

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
            writing.content or "",
            categories
        ))
    end

    -- Generate Atom feed
    local atom_template = utils.read_file(config.templates_dir .. "/atom.xml")
    local atom_content = string.gsub(atom_template, "{{(%w+)}}", common_data)
    atom_content = atom_content:gsub("{{ENTRIES}}", table.concat(atom_entries, "\n"))

    -- Generate RSS feed
    local rss_template = utils.read_file(config.templates_dir .. "/rss.xml")
    local rss_content = string.gsub(rss_template, "{{(%w+)}}", common_data)
    rss_content = rss_content:gsub("{{ITEMS}}", table.concat(rss_items, "\n"))

    utils.write_file(config.dist_dir .. "/feed.atom", atom_content)
    utils.write_file(config.dist_dir .. "/feed.xml", rss_content)

    return processed_writings
end

return writings