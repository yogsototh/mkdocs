let
  pkgs = import (fetchTarball https://github.com/NixOS/nixpkgs/archive/17.09.tar.gz) {};
in with pkgs; {
  simpleEnv = stdenv.mkDerivation {
    name = "simple-env";
    version = "1";
    buildInputs = [ pandoc stack ];
  };
}

