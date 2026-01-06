{
  pkgs ? import <nixpkgs> { },
}:

pkgs.mkShell {
  name = "develop";

  buildInputs = with pkgs; [
    sqlite
    nushell
    gum
    unixtools.column
  ];

  shellHook = ''
    nu -e "source shell.nu"
    exit 0
  '';
}
