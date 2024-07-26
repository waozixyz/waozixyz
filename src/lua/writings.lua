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
    -- Generate RSS feed
    local rss_template = utils.read_file(config.templates_dir .. "/atom.xml")
    local rss_content = rss_template
    rss_content = rss_content:gsub("{{SITE_TITLE}}", config.site_title)
    rss_content = rss_content:gsub("{{SITE_URL}}", config.site_url)
    rss_content = rss_content:gsub("{{CURRENT_DATE}}", os.date("!%Y-%m-%dT%H:%M:%SZ"))
    rss_content = rss_content:gsub("{{AUTHOR_NAME}}", config.author_name)

    local entries = ""
    for _, writing in ipairs(processed_writings) do
        local categories = ""
        for _, tag in ipairs(writing.tags or {}) do
            categories = categories .. string.format('    <category term="%s"/>\n', utils.escape_xml(tag))
        end

        local entry = string.format(
            '<entry>\n' ..
            '    <title>%s</title>\n' ..
            '    <link href="%s/writings/%s"/>\n' ..
            '    <id>%s/writings/%s</id>\n' ..
            '    <published>%s</published>\n' ..
            '    <updated>%s</updated>\n' ..
            '    <summary type="html"><![CDATA[%s]]></summary>\n' ..
            '    <content type="html"><![CDATA[%s]]></content>\n' ..
            '%s' ..
            '</entry>\n',
            utils.escape_xml(writing.title or ""),
            config.site_url,
            writing.url,
            config.site_url,
            writing.url,
            os.date("!%Y-%m-%dT%H:%M:%SZ", utils.parse_date(writing.date)),
            os.date("!%Y-%m-%dT%H:%M:%SZ", utils.parse_date(writing.date)),
            writing.desc or "",
            writing.content or "",
            categories
        )
        
        entries = entries .. entry
    end

    rss_content = rss_content:gsub("{{ENTRIES}}", entries)

    utils.write_file(config.dist_dir .. "/feed.atom", rss_content)

    return processed_writings
end

return writings