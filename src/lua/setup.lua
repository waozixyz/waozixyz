local utils = require "utils"
local config = require "config"

local setup = {}

function setup.create_directories()
    utils.shell("mkdir -p " .. config.dist_dir .. "/writings")
    utils.shell("mkdir -p " .. config.dist_dir .. "/proj")
end

function setup.copy_proj_files()
    utils.copy_dir(config.proj_dir, config.dist_dir .. "/proj")
end

function setup.copy_static_files()
    utils.shell("cp -r " .. config.static_dir .. "/* " .. config.dist_dir)
end

return setup
