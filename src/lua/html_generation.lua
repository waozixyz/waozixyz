local utils = require "utils"
local config = require "config"

local html_generation = {}

function html_generation.generate_writing_section(writings)
    local writing_section = "<section id=\"writings\" class=\"writings fade-in\"><h3>Writings - Thoughts Adrift in the Digital Sea</h3><div class=\"writing-grid\">"
    for i = 1, math.min(config.max_writings, #writings) do
        local w = writings[i]
        writing_section = writing_section .. string.format(
            "<a href=\"writings/%s\" class=\"writing-card\"><div><h4>%s</h4><p class=\"writing-meta\">Published: %s | %s</p><p class=\"writing-excerpt\">%s</p></div></a>",
            w.link, w.title, w.date, w.readTime, w.desc
        )
    end
    return writing_section .. "</div><a href=\"writings/\" class=\"more-btn\">More Writings</a></section>"
end

function html_generation.update_main_index(writing_section, projects_section)
    local index_path = config.index_file
    local index_content = utils.read_file(index_path)
    if not index_content then
        print("Error: Could not read index file at " .. index_path)
        return
    end
    index_content = index_content:gsub('<section id="writings" class="writings fade%-in">.-</section>', writing_section)
    index_content = index_content:gsub('<section id="projects" class="projects fade%-in">.-</section>', projects_section)
    utils.write_file(config.dist_dir .. "/index.html", index_content)
end
function html_generation.generate_writings_index(writings)
    local writings_index_template = utils.read_file(config.templates_dir .. "/" .. config.writings_index_template)
    
    local writing_cards = ""
    for _, w in ipairs(writings) do
        local image_src = w.imgSrc or "/assets/default-cover.jpg"  -- Use a default image if none is provided
        local image_alt = w.imgAlt or w.title
        writing_cards = writing_cards .. string.format([[
            <a href="%s" class="writing-card">
                <div class="card-image">
                    <img src="%s" alt="%s">
                </div>
                <div class="card-content">
                    <h3>%s</h3>
                    <p class="writing-desc">%s</p>
                    <p class="writing-meta">Published: %s | %s</p>
                </div>
            </a>
        ]], w.link, image_src, image_alt, w.title, w.desc, w.date, w.readTime)
    end

    local writings_index = writings_index_template
        :gsub("{{TITLE}}", "Waozi Writings - Digital Reflections")
        :gsub("{{HEADER}}", "Waozi Writings")
        :gsub("{{SUBHEADER}}", "Thoughts adrift in the digital sea")
        :gsub("{{WRITING_CARDS}}", writing_cards)
        :gsub("{{BACK_LINK}}", "../index.html")
        :gsub("{{BACK_TEXT}}", "Back to Waozi")

    utils.write_file(config.dist_dir .. "/writings/index.html", writings_index)
end
function html_generation.generate_project_cards(projects, max_display)
    table.sort(projects, function(a, b) return a.updated > b.updated end)
    local cards = ""
    for i = 1, math.min(max_display, #projects) do
        local project = projects[i]
        cards = cards .. string.format([[
            <a href="%s" class="app-card">
                <h3>%s</h3>
                <p class="app-meta">%s | %s | Updated: %s</p>
                <p class="app-excerpt">%s</p>
            </a>
        ]], project.url, project.name, project.description, project.version, project.updated, project.excerpt)
    end
    return cards
end

function html_generation.generate_projects_section()
    local naox_projects = utils.load_yaml(config.naox_projects_file)
    local waozi_projects = utils.load_yaml(config.waozi_projects_file)
    
    local all_projects = {}
    for _, project in ipairs(naox_projects) do
        table.insert(all_projects, project)
    end
    for _, project in ipairs(waozi_projects) do
        table.insert(all_projects, project)
    end
    
    table.sort(all_projects, function(a, b) return a.updated > b.updated end)
    
    local project_cards = html_generation.generate_project_cards(all_projects, config.max_projects_display)
    
    return string.format([[
        <section id="projects" class="projects fade-in">
            <article class="projects">
                <h2>Projects</h2>
                <div class="app-grid">
                    %s
                </div>
                <a href="proj/" class="more-btn">More Projects</a>
            </article>
        </section>
    ]], project_cards)
end

return html_generation
