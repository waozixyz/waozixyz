#!/bin/bash

# Install Lua
apt-get update
apt-get install -y lua5.3 luarocks

# Install Lua packages
luarocks install luafilesystem
luarocks install lyaml

# Set Lua paths
export LUA_PATH="$PWD/src/lua/?.lua;/usr/local/share/lua/5.3/?.lua;/usr/local/share/lua/5.3/?/init.lua"
export LUA_CPATH="/usr/local/lib/lua/5.3/?.so"

# Run the build command
lua src/lua/build.lua
