local utils = require "utils"
local config = require "config"

local projects = {}
function projects.generate_projects_index()
    local naox_projects = utils.load_yaml(config.naox_projects_file)
    local waozi_projects = utils.load_yaml(config.waozi_projects_file)
    local all_projects = {}
    
    for _, project in ipairs(naox_projects) do
        project.category = "NaoX"
        table.insert(all_projects, project)
    end
    
    for _, project in ipairs(waozi_projects) do
        project.category = "Waozi"
        table.insert(all_projects, project)
    end
    
    table.sort(all_projects, function(a, b)
        return a.updated > b.updated
    end)
    
    local project_cards = ""
    for _, project in ipairs(all_projects) do
        local image_src = project.imgSrc or "/assets/default-project.jpg"  -- Use a default image if none is provided
        local image_alt = project.imgAlt or project.name
        project_cards = project_cards .. string.format([[
            <a href="%s" class="project-card">
                <div class="card-image">
                    <img src="%s" alt="%s">
                </div>
                <div class="card-content">
                    <h3>%s</h3>
                    <p class="project-category">%s | %s</p>
                    <p class="project-desc">%s</p>
                    <p class="project-meta">Updated: %s</p>
                </div>
            </a>
        ]], project.url, image_src, image_alt, project.name, project.category, project.version, project.excerpt, project.updated)
    end
    
    local projects_index_template = utils.read_file(config.templates_dir .. "/" .. config.projects_index_template)
    local projects_index = projects_index_template
        :gsub("{{TITLE}}", "All Projects - Waozi")
        :gsub("{{HEADER}}", "All Projects")
        :gsub("{{PROJECT_CARDS}}", project_cards)
    
    utils.write_file(config.dist_dir .. "/proj/index.html", projects_index)
end

return projects
