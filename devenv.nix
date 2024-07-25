{ pkgs, ... }:

{
  packages = with pkgs; [
    lua
    luaPackages.luafilesystem
    luaPackages.lyaml
    md4c
  ];

  enterShell = ''
    export LUA_PATH="$PWD/src/lua/?.lua;${pkgs.luaPackages.lyaml}/share/lua/5.2/?.lua;${pkgs.luaPackages.lyaml}/share/lua/5.2/?/init.lua;$LUA_PATH"
    export LUA_CPATH="${pkgs.luaPackages.lyaml}/lib/lua/5.2/?.so;$LUA_CPATH"

    echo "Waozi static site generator environment"
    echo "Available commands:"
    echo "  build    # Generate the site in the dist directory"
  '';

  scripts.build = {
    exec = ''
      lua src/lua/build.lua
    '';
    description = "Generate the site in the dist directory";
  };
}