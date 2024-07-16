local lfs = require "lfs"
local yaml = require "lyaml"

local markdown_dir = "writings/markdown"
local html_dir = "writings"
local template_file = "template.html"

-- Read the template file
local function read_file(path)
    local file = io.open(path, "r")
    if not file then return nil end
    local content = file:read("*all")
    file:close()
    return content
end

-- Write content to a file
local function write_file(path, content)
    local file = io.open(path, "w")
    if not file then return false end
    file:write(content)
    file:close()
    return true
end

-- Execute shell command and return output
local function shell(cmd)
    local handle = io.popen(cmd)
    local result = handle:read("*a")
    handle:close()
    return result
end

-- Function to extract YAML metadata and content
local function extract_yaml_and_content(file_content)
    local yaml_str = file_content:match("^%-%-%-\n(.-)\n%-%-%-\n")
    local content = file_content:gsub("^%-%-%-\n.-\n%-%-%-\n", "")
    
    if yaml_str then
        return yaml.load(yaml_str), content
    else
        return {}, content
    end
end

local template = read_file(template_file)

-- Prepare the index file
local index_content = [[
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Waozi Writings - Digital Reflections</title>
    <link rel="stylesheet" href="../style.css">
</head>
<body>
    <h1>Waozi Writings</h1>
    <p>Thoughts adrift in the digital sea</p>
    <ul>
]]

-- Process each Markdown file
for file in lfs.dir(markdown_dir) do
    if file:match("%.md$") then
        local md_path = markdown_dir .. "/" .. file
        local html_path = html_dir .. "/" .. file:gsub("%.md$", ".html")
        
        local md_content = read_file(md_path)
        if md_content then
            -- Extract YAML metadata and content
            local metadata, content = extract_yaml_and_content(md_content)
            
            -- Convert Markdown to HTML using md4c
            local html_content = shell(string.format("echo '%s' | md2html --github", content:gsub("'", "'\\''")))
            
            -- Remove the auto-generated HTML, head, and body tags
            html_content = html_content:gsub("<!DOCTYPE html>.-<body>", ""):gsub("</body></html>", "")
            
            -- Apply template
            local page_content = template
            for key, value in pairs(metadata) do
                page_content = page_content:gsub("{{" .. key:upper() .. "}}", value)
            end
            page_content = page_content:gsub("{{CONTENT}}", html_content)
            
            -- Write the HTML file
            write_file(html_path, page_content)
            
            -- Add to index
            index_content = index_content .. string.format('        <li><a href="%s">%s</a> - %s</li>\n', 
                                                           file:gsub("%.md$", ".html"), metadata.title, metadata.date)
        end
    end
end

-- Finish and write the index file
index_content = index_content .. [[
    </ul>
    <a href="../index.html">Back to Waozi</a>
</body>
</html>
]]

write_file(html_dir .. "/index.html", index_content)

print("Site generation complete.")