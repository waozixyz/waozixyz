local lfs = require "lfs"
local yaml = require "lyaml"

-- Load configuration
local function load_config()
    local config_file = io.open("config.yaml", "r")
    if not config_file then error("Could not open config.yaml") end
    local config_writings = config_file:read("*all")
    config_file:close()
    return yaml.load(config_writings)
end

local config = load_config()

-- Use configuration values
local src_dir = config.src_dir
local dist_dir = config.dist_dir
local writings_dir = config.writings_dir
local templates_dir = config.templates_dir
local static_dir = config.static_dir
local proj_dir = config.proj_dir
local main_template_file = templates_dir .. "/" .. config.main_template
local writing_template_file = templates_dir .. "/" .. config.writing_template
local index_file = src_dir .. "/" .. config.index_file
local max_writings = config.max_writings

-- Utility functions
local function read_file(path)
    local file = io.open(path, "r")
    if not file then return nil end
    local content = file:read("*all")
    file:close()
    return content
end

local function write_file(path, content)
    local file = io.open(path, "w")
    if not file then return false end
    file:write(content)
    file:close()
    return true
end

local function shell(cmd)
    local handle = io.popen(cmd)
    local result = handle:read("*a")
    handle:close()
    return result
end

local function extract_yaml_and_content(file_content)
    local yaml_str = file_content:match("^%-%-%-\n(.-)\n%-%-%-\n")
    local content = file_content:gsub("^%-%-%-\n.-\n%-%-%-\n", "")
    return yaml_str and yaml.load(yaml_str) or {}, content
end

local function parse_date(date_str)
    local months = {Jan=1, Feb=2, Mar=3, Apr=4, May=5, Jun=6, Jul=7, Aug=8, Sep=9, Oct=10, Nov=11, Dec=12}
    local month, day, year = date_str:match("(%a+)%s+(%d+),%s+(%d+)")
    return month and day and year and os.time({year=tonumber(year), month=months[month], day=tonumber(day)}) or 0
end

-- Setup functions
local function create_directories()
    shell("mkdir -p " .. dist_dir .. "/writings")
    shell("mkdir -p " .. dist_dir .. "/proj")
end

local function copy_proj_files()
    local function is_hidden(path)
        return path:match("/%.") ~= nil
    end

    local function copy_dir(src, dest)
        shell("mkdir -p " .. dest)
        for file in lfs.dir(src) do
            if file ~= "." and file ~= ".." then
                local src_path = src .. "/" .. file
                local dest_path = dest .. "/" .. file
                local attr = lfs.attributes(src_path)
                if attr.mode == "directory" and not is_hidden(src_path) then
                    copy_dir(src_path, dest_path)
                elseif attr.mode == "file" and not is_hidden(src_path) then
                    shell("cp '" .. src_path .. "' '" .. dest_path .. "'")
                end
            end
        end
    end

    copy_dir(proj_dir, dist_dir .. "/proj")
end
local function copy_static_files()
    shell("cp -r " .. static_dir .. "/* " .. dist_dir)
end

local function copy_index()
    shell("cp " .. index_file .. " " .. dist_dir .. "/" .. config.index_file)
end

-- Main execution
create_directories()
copy_static_files()
copy_proj_files()
copy_index()

local main_template = read_file(main_template_file)
local writing_template = read_file(writing_template_file)

-- Process markdown files
local writings = {}
for file in lfs.dir(writings_dir) do
    if file:match("%.md$") then
        local md_path = writings_dir .. "/" .. file
        local html_path = dist_dir .. "/writings/" .. file:gsub("%.md$", ".html")

        local md_content = read_file(md_path)
        if md_content then
            local metadata, content = extract_yaml_and_content(md_content)
            local html_content = shell(string.format("echo '%s' | md2html --github", content:gsub("'", "'\\''")))
            html_content = html_content:gsub("<!DOCTYPE html>.-<body>", ""):gsub("</body></html>", "")
            html_content = html_content:gsub("<p>(<img [^>]+>) ?(<img [^>]+>)</p>", "<div class='image-row'>%1%2</div>")

            local url = file:gsub("%.md$", "")
            local page_content = writing_template
            for key, value in pairs(metadata) do
                page_content = page_content:gsub("{{" .. key:upper() .. "}}", value)
            end
            page_content = page_content:gsub("{{CONTENT}}", html_content):gsub("{{URL}}", url)

            write_file(html_path, page_content)

            table.insert(writings, {
                title = metadata.title,
                date = metadata.date,
                excerpt = metadata.excerpt or "",
                desc = metadata.desc or "",
                readTime = metadata.readTime or "",
                link = file:gsub("%.md$", ".html"),
                url = url
            })
        end
    end
end

-- Sort writings by date
table.sort(writings, function(a, b) return parse_date(a.date) > parse_date(b.date) end)

-- Generate HTML for the writing section
local writing_section = "<section class=\"writings\"><h3>Writings - Thoughts Adrift in the Digital Sea</h3><div class=\"writing-grid\">"
for i = 1, math.min(max_writings, #writings) do
    local w = writings[i]
    writing_section = writing_section .. string.format(
        "<div class=\"writing-card\"><h4><a href=\"writings/%s\">%s</a></h4><p class=\"writing-meta\">Published: %s | %s</p><p class=\"writing-excerpt\">%s</p></div>",
        w.link, w.title, w.date, w.readTime, w.desc
    )
end
writing_section = writing_section .. "</div><a href=\"writings/\" class=\"more-btn\">More Writings</a></section>"

-- Update main index.html
local index_content = read_file(dist_dir .. "/" .. config.index_file)
index_content = index_content:gsub('<section class="writings">.-</section>', writing_section)
write_file(dist_dir .. "/" .. config.index_file, index_content)

-- Generate writings index page
local writings_index = [[
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Waozi Writings - Digital Reflections</title>
    <link rel="stylesheet" href="../style.css">
    <link rel="icon" type="image/png" href="/favicon.png">
</head>
<body>
    <h1>Waozi Writings</h1>
    <p>Thoughts adrift in the digital sea</p>
    <ul>
]]

for _, w in ipairs(writings) do
    writings_index = writings_index .. string.format("<li><a href=\"%s\">%s</a> - %s</li>", w.link, w.title, w.date)
end

writings_index = writings_index .. [[
    </ul>
    <a href="../index.html">Back to Waozi</a>
</body>
</html>
]]

write_file(dist_dir .. "/writings/index.html", writings_index)

print("Site generation complete. Output is in the '" .. dist_dir .. "' folder.")