{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  buildInputs = with pkgs; [
    libGL
    libGLU
    glib
  ];

  shellHook = ''
    export LD_LIBRARY_PATH=${pkgs.libGL}/lib:${pkgs.glib.out}/lib:$LD_LIBRARY_PATH
  '';
}
