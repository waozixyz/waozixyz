{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  buildInputs = with pkgs; [
    lua
    luaPackages.luafilesystem
    luaPackages.lyaml
    md4c
  ];

  shellHook = ''
    echo "Waozi static site generator environment"
    echo "Available commands:"
    echo "  lua generate_site.lua    # Generate the site"
    echo "  md2html --help           # Show md4c usage"
  '';

  # If you want to add any environment variables, you can do so here
  # LUA_PATH = "${pkgs.luaPackages.luafilesystem}/share/lua/${pkgs.lua.luaversion}/?.lua;;";
}

