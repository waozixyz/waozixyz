#!/bin/bash

# Define versions
LUA_VERSION=5.3.6
LUAROCKS_VERSION=3.8.0
LUA_INSTALL_DIR=$HOME/.lua
LUAROCKS_INSTALL_DIR=$HOME/.luarocks

# Create install directories
mkdir -p $LUA_INSTALL_DIR
mkdir -p $LUAROCKS_INSTALL_DIR

# Install Lua
echo "Installing Lua..."
curl -R -O http://www.lua.org/ftp/lua-$LUA_VERSION.tar.gz
tar zxf lua-$LUA_VERSION.tar.gz
cd lua-$LUA_VERSION
make linux test
make install INSTALL_TOP=$LUA_INSTALL_DIR

# Set Lua environment variables
export PATH=$LUA_INSTALL_DIR/bin:$PATH
export LUA_PATH="$LUA_INSTALL_DIR/share/lua/5.3/?.lua;$LUA_INSTALL_DIR/share/lua/5.3/?/init.lua;;"
export LUA_CPATH="$LUA_INSTALL_DIR/lib/lua/5.3/?.so;;"

cd ..

# Install Luarocks
echo "Installing Luarocks..."
curl -R -O https://luarocks.org/releases/luarocks-$LUAROCKS_VERSION.tar.gz
tar zxpf luarocks-$LUAROCKS_VERSION.tar.gz
cd luarocks-$LUAROCKS_VERSION
./configure --prefix=$LUAROCKS_INSTALL_DIR --with-lua=$LUA_INSTALL_DIR
make build
make install

# Set Luarocks environment variables
export PATH=$LUAROCKS_INSTALL_DIR/bin:$PATH

# Install Lua packages
echo "Installing Lua packages..."
luarocks install luafilesystem
luarocks install lyaml

# Set Lua paths for the installed packages
export LUA_PATH="$PWD/src/lua/?.lua;$LUAROCKS_INSTALL_DIR/share/lua/5.3/?.lua;$LUAROCKS_INSTALL_DIR/share/lua/5.3/?/init.lua"
export LUA_CPATH="$LUAROCKS_INSTALL_DIR/lib/lua/5.3/?.so"

# Run the build command
echo "Running the build command..."
lua src/lua/build.lua
