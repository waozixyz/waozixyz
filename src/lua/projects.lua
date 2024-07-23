local utils = require "utils"
local config = require "config"

local projects = {}

function projects.generate_projects_index()
    local naox_projects = utils.load_yaml(config.naox_projects_file)
    local other_projects = utils.load_yaml(config.other_projects_file)
    local all_projects = {}
    
    for _, project in ipairs(naox_projects) do
        project.category = "NaoX"
        table.insert(all_projects, project)
    end
    
    for _, project in ipairs(other_projects) do
        project.category = "Other"
        table.insert(all_projects, project)
    end
    
    table.sort(all_projects, function(a, b)
        return a.updated > b.updated
    end)
    
    local project_list = ""
    for _, project in ipairs(all_projects) do
        project_list = project_list .. string.format([[
            <li>
                <a href="%s">%s</a> - %s | %s | Updated: %s
                <p>%s</p>
            </li>
        ]], project.url, project.name, project.category, project.version, project.updated, project.excerpt)
    end
    
    local projects_index_template = utils.read_file(config.templates_dir .. "/" .. config.projects_index_template)
    local projects_index = projects_index_template
        :gsub("{{TITLE}}", "All Projects - Waozi")
        :gsub("{{HEADER}}", "All Projects")
        :gsub("{{PROJECT_LIST}}", project_list)
    
    utils.write_file(config.dist_dir .. "/proj/index.html", projects_index)
end

return projects
