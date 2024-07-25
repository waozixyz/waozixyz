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
    for key, value in pairs(metadata) do
        page_content = page_content:gsub("{{" .. key:upper() .. "}}", value)
    end
    page_content = page_content:gsub("{{CONTENT}}", html_content):gsub("{{URL}}", url)

    utils.write_file(html_path, page_content)

    return {
        title = metadata.title,
        date = metadata.date,
        excerpt = metadata.excerpt or "",
        desc = metadata.desc or "",
        readTime = metadata.readTime or "",
        link = file:gsub("%.md$", ".html"),
        url = url
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
    table.sort(processed_writings, function(a, b) return utils.parse_date(a.date) > utils.parse_date(b.date) end)
    return processed_writings
end

return writings
