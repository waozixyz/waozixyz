{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  buildInputs = with pkgs; [
    lua
    luaPackages.luafilesystem
    luaPackages.lyaml
    md4c
  ];

  shellHook = ''
    export LUA_PATH="$PWD/src/lua/?.lua;$LUA_PATH"

    echo "Waozi static site generator environment"
    echo "Available commands:"
    echo "  lua src/lua/build.lua    # Generate the site"
  '';
}