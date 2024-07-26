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
        local entry = rss_template:match("<entry>.-</entry>")
        if entry then
            entry = entry:gsub("{{title}}", writing.title or "")
            entry = entry:gsub("{{SITE_URL}}", config.site_url)  -- Add this line
            entry = entry:gsub("{{url}}", writing.url or "")
            entry = entry:gsub("{{date}}", writing.date or "")
            entry = entry:gsub("{{desc}}", writing.desc or "")
            entry = entry:gsub("{{content}}", writing.content or "")
            
            local categories = ""
            for _, tag in ipairs(writing.tags or {}) do
                categories = categories .. string.format('<category term="%s"/>', tag)
            end
            entry = entry:gsub("{{#each tags}}.-{{/each}}", categories)
            
            entries = entries .. entry
        end
    end
    rss_content = rss_content:gsub("{{#each ENTRIES}}.-{{/each}}", entries)

    -- Replace any remaining {{SITE_URL}} placeholders in the main template
    rss_content = rss_content:gsub("{{SITE_URL}}", config.site_url)

    utils.write_file(config.dist_dir .. "/feed.atom", rss_content)

    return processed_writings
end


return writings