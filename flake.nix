{
  inputs = {
    nixpkgs = {
      url = "github:nixos/nixpkgs/nixos-unstable";
    };
    flake-utils = {
      url = "github:numtide/flake-utils";
    };
  };
  outputs = { nixpkgs, flake-utils, ... }: flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = import nixpkgs {
        inherit system;
      };
      lightgbm-cli = (with pkgs; stdenv.mkDerivation {
          pname = "lightgbm-cli";
          version = "3.3.1";
          # if we didnt need submodules...
          #src = fetchFromGithub {
            # ...
          #};
          src = fetchgit {
            url = "https://github.com/microsoft/LightGBM";
            rev = "d4851c3381495d9a065d49e848fbf291a408477d";
            # use this first
            #sha256 = lib.fakeSha256;
            sha256 = "pBrsey0RpxxvlwSKrOJEBQp7Hd9Yzr5w5OdUuyFpgF8=";
            fetchSubmodules = true;
          };
          nativeBuildInputs = [
            clang
            cmake
          ];
          configurePhase = ''
            cmake .
          '';
          buildPhase = ''
            make -j $NIX_BUILD_CORES
          '';
          installPhase = ''
            mkdir -p $out/bin
            mv $TMP/LightGBM-d4851c3/lightgbm $out/bin
          '';
        }
      );
    in rec {
      defaultApp = flake-utils.lib.mkApp {
        drv = defaultPackage;
      };
      defaultPackage = lightgbm-cli;
      devShell = pkgs.mkShell {
        buildInputs = with pkgs; [
          lightgbm-cli
        ];
      };
    }
  );
}
