local lfs = require "lfs"
local yaml = require "lyaml"

local utils = {}

function utils.read_file(path)
    local file = io.open(path, "r")
    if not file then return nil end
    local content = file:read("*all")
    file:close()
    return content
end

function utils.write_file(path, content)
    -- Ensure the directory exists before writing the file
    utils.ensure_dir_exists(path:match("(.+)/[^/]*$"))
    local file = io.open(path, "w")
    if not file then return false end
    file:write(content)
    file:close()
    return true
end

function utils.shell(cmd)
    local handle = io.popen(cmd)
    local result = handle:read("*a")
    handle:close()
    return result
end

function utils.extract_yaml_and_content(file_content)
    local yaml_str = file_content:match("^%-%-%-\n(.-)\n%-%-%-\n")
    local content = file_content:gsub("^%-%-%-\n.-\n%-%-%-\n", "")
    return yaml_str and yaml.load(yaml_str) or {}, content
end

function utils.parse_date(date_str)
    local months = {Jan=1, Feb=2, Mar=3, Apr=4, May=5, Jun=6, Jul=7, Aug=8, Sep=9, Oct=10, Nov=11, Dec=12}
    local month, day, year = date_str:match("(%a+)%s+(%d+),%s+(%d+)")
    return month and day and year and os.time({year=tonumber(year), month=months[month], day=tonumber(day)}) or 0
end

function utils.ensure_dir_exists(path)
    local current = ""
    for dir in path:gmatch("([^/]+)") do
        current = current .. dir .. "/"
        lfs.mkdir(current)
    end
end
function utils.copy_dir(src, dest)
    utils.ensure_dir_exists(dest)
    for file in lfs.dir(src) do
        -- Ignore hidden files and directories
        if file:sub(1,1) ~= "." then
            local src_path = src .. "/" .. file
            local dest_path = dest .. "/" .. file
            local attr = lfs.attributes(src_path)
            if attr.mode == "directory" then
                utils.copy_dir(src_path, dest_path)
            else
                local src_file = io.open(src_path, "rb")
                if src_file then
                    local dest_file = io.open(dest_path, "wb")
                    if dest_file then
                        dest_file:write(src_file:read("*all"))
                        dest_file:close()
                    else
                        print("Warning: Could not open destination file for writing: " .. dest_path)
                    end
                    src_file:close()
                else
                    print("Warning: Could not open source file for reading: " .. src_path)
                end
            end
        end
    end
end

function utils.load_yaml(file_path)
    local content = utils.read_file(file_path)
    return content and yaml.load(content) or nil
end

return utils