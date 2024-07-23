#!/bin/bash

# Download and install Lua
LUAROCKS_VERSION=3.8.0
LUA_VERSION=5.3.6
LUAROCKS_ROOT=$HOME/.luarocks

mkdir -p $LUAROCKS_ROOT

# Install Lua
curl -R -O http://www.lua.org/ftp/lua-$LUA_VERSION.tar.gz
tar zxf lua-$LUA_VERSION.tar.gz
cd lua-$LUA_VERSION
make linux test
make install INSTALL_TOP=$LUAROCKS_ROOT

cd ..

# Install Luarocks
curl -R -O https://luarocks.org/releases/luarocks-$LUAROCKS_VERSION.tar.gz
tar zxpf luarocks-$LUAROCKS_VERSION.tar.gz
cd luarocks-$LUAROCKS_VERSION
./configure --prefix=$LUAROCKS_ROOT --with-lua=$LUAROCKS_ROOT
make build
make install

export PATH=$LUAROCKS_ROOT/bin:$PATH

# Install Lua packages
luarocks install luafilesystem
luarocks install lyaml

# Set Lua paths
export LUA_PATH="$PWD/src/lua/?.lua;$LUAROCKS_ROOT/share/lua/5.3/?.lua;$LUAROCKS_ROOT/share/lua/5.3/?/init.lua"
export LUA_CPATH="$LUAROCKS_ROOT/lib/lua/5.3/?.so"

# Run the build command
lua src/lua/build.lua
