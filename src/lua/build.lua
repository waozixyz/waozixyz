local lfs = require "lfs"
local yaml = require "lyaml"
local utils = require "utils"
local config = require "config"
local setup = require "setup"
local writings = require "writings"
local projects = require "projects"
local html_generation = require "html_generation"

local function main()
    -- Load templates
    config.main_template = utils.read_file(config.templates_dir .. "/" .. config.main_template)
    config.writing_template = utils.read_file(config.templates_dir .. "/" .. config.writing_template)

    -- Setup
    setup.create_directories()
    setup.copy_static_files()

    -- Process content
    local processed_writings = writings.process_writings()
    local writing_section = html_generation.generate_writing_section(processed_writings)
    local projects_section = html_generation.generate_projects_section()
    
    -- Generate HTML
    html_generation.update_main_index(writing_section, projects_section)
    html_generation.generate_writings_index(processed_writings)
    projects.generate_projects_index()

    print("Site generation complete. Output is in the '" .. config.dist_dir .. "' folder.")
end

-- Error handling
local status, err = pcall(main)
if not status then
    print("An error occurred during site generation:")
    print(err)
    os.exit(1)
end