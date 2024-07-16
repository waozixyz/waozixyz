local lfs = require "lfs"
local yaml = require "lyaml"

local markdown_dir = "writings/markdown"
local html_dir = "writings"
local template_file = "template.html"
local index_file = "index.html"
local max_writings = 2


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

-- Table to store writing summaries
local writings = {}

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
            
            -- Store writing summary
            table.insert(writings, {
                title = metadata.title,
                date = metadata.date,
                excerpt = metadata.excerpt or "",
                desc = metadata.desc or "",
                readTime = metadata.readTime or "",
                link = file:gsub("%.md$", ".html")
            })
        end
    end
end



-- Sort writings by date (assuming date is in a sortable format)
table.sort(writings, function(a, b) return a.date > b.date end)

-- Generate HTML for the writing section
local writing_section = [[
<section class="writings">
    <h3>Writings - Thoughts Adrift in the Digital Sea</h3>
    <div class="writing-grid">
]]

-- Add up to 3 most recent writings
do 
    i = #writings
    while i > #writings - max_writings do
        local writing = writings[i]
        writing_section = writing_section .. string.format([[
            <div class="writing-card">
                <h4><a href="writings/%s">%s</a></h4>
                <p class="writing-meta">Published: %s | %s</p>
                <p class="writing-excerpt">%s</p>
            </div>
        ]], writing.link, writing.title, writing.date, writing.readTime, writing.desc)
        i = i - 1
    end
end


writing_section = writing_section .. [[
    </div>
    <a href="writings/" class="more-btn">More Writings</a>
</section>
]]

-- Read the main index.html file
local index_content = read_file(index_file)

-- Replace the entire writings section
index_content = index_content:gsub('<section class="writings">.-</section>', writing_section)

-- Write the updated index.html file
write_file(index_file, index_content)



-- Generate the writings index page
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

do 
    i = #writings
    while i > 0 do
        local writing = writings[i]
        writings_index = writings_index .. string.format([[
            <li><a href="%s">%s</a> - %s</li>
        ]], writing.link, writing.title, writing.date)
        i = i - 1
    end
end

writings_index = writings_index .. [[
    </ul>
    <a href="../index.html">Back to Waozi</a>
</body>
</html>
]]

-- Write the writings index page
write_file(html_dir .. "/index.html", writings_index)

print("Site generation complete.")