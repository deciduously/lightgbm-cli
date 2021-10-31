# Workstation Management With Nix Flakes: Build a Cmake C++ Package

Last time, we looked at how to produce a development shell using Nix Flakes that contained the Python interpreter alongside a few dependencies the project required. In this post, we'll produce a compiled binary, using source code hosted on GitHub, for other people to include in their own environments.

## The Target

For this demonstration, I'll be packaging the [LightGBM](https://github.com/microsoft/LightGBM) CLI tool. Nixpkgs already provides derivations for the native libraries for Python and R, which will suffice for most users, but I didn't see one to build the CLI tool directly (and, of coure, will submit mine upstream as well).

Per [the documentation](https://lightgbm.readthedocs.io/en/latest/Installation-Guide.html), building this application from source is relatively straightforward:

```
git clone --recursive https://github.com/microsoft/LightGBM
cd LightGBM
mkdir build
cd build
cmake ..
make -j4
```

There's a few things we can learn: this git repository has submodules, meaning we need to use `--recrusive`, and the build can be parallelized. These instructions also have you create a build directory, but with Nix we can skip that. The whole build will take place in a purpose-made build directory.

## The Flake

As before, I'll show the full flake first. We'll walk through it in pieces below.

```nix
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
          src = fetchgit {
            url = "https://github.com/microsoft/LightGBM";
            rev = "v3.3.1";
            sha256 = "pBrsey0RpxxvlwSKrOJEBQp7Hd9Yzr5w5OdUuyFpgF8=";
            fetchSubmodules = true;
          };
          nativeBuildInputs = [
            clang
            cmake
          ];
          buildPhase = "make -j $NIX_BUILD_CORES";
          installPhase = ''
            mkdir -p $out/bin
            mv $TMP/LightGBM/lightgbm $out/bin
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
```

If you read the last post, much of this looks the same. We have `inputs` and `outputs`, we have a `let..in` section where we define variables, and we have a `devShell` in the output.

The new bits are the `lightgbm-cli` variable, defined using `stdenv.mkDerivation`, and the `defaultApp` and `defaultPackage` keys in the `outputs` section.

## The Walkthrough

I won't repeat the explanations of the shared elements, take a look at the [previous post](https://dev.to/deciduously/workspace-management-with-nix-flakes-jupyter-notebook-example-2kke) for the full explanations. This post will focuse on the `mkDerivation` section.

The `pkgs.stdenv.mkDerivation` function is a wrapper around the low-level Nix concept of a `derivation`. See the [Nix Pills](https://nixos.org/guides/nix-pills/our-first-derivation.html) for a thorough walkthrough of how to work with them. Using `mkDerivation` sets some sensible defautls and provides more tools on top of this base to greatly streamlne the process, but it's important to know that under the hood this `derivation` concept is what ultimately gets evaluated.

First, we set the package name. You can directly set a `name`, but the preferred way to handle this is to separatele set the package name, or `pname`, and the version. Nix will then combine them into a full `name` key for you with the format `${pname}-${version}`.

No need for a configurePhase...

if you didn't need submoduls...

if you pinned to a revision...

            #rev = "d4851c3381495d9a065d49e848fbf291a408477d";

$TMP/LightGBM-d4581c3/lightgbm

```
          # if we didnt need submodules...
          #src = fetchFromGithub {
            # ...
          #};
```

Before you run your derivation the first time, you probably won't know the sha256 hash of the source repository. While you could download it separately and use the `nix hash-path path/to/clone` command, I find it more convenient to provide a bad hash first and let Nix tell you what it should be. There's even a built-in feature for this:

```nix
sha256 = lib.fakeSha256;
```

On the first run, you'll get an error like this:

```
$ nix build
error: hash mismatch in fixed-output derivation '/nix/store/5ysvmxay83fnc14w5r2s450i39byd4ks-source.drv':
         specified: sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=
            got:    sha256-aCz+B6rGjYisGif0/XS8N2M//hDCXji5xUXlHs5YnjM=
error: 1 dependencies of derivation '/nix/store/jaip55q9ix8hq4l7srd9kigxlq7nimyr-lightgbm-cli-3.3.1.drv' failed to build
```

It downloaded the repository, checked the hash, and (thankfully) noticed it's not the same as as the `fakeSha256` has you provided. Conveniently, it tells us what the hash _should_ be, so you can change your code:

```diff
- sha256 = libfakeSha256;
+ sha256 = "pBrsey0RpxxvlwSKrOJEBQp7Hd9Yzr5w5OdUuyFpgF8=";
```

The returned value has the `sha256` prefix, so we can use the more general (and more preferred) `hash` key.

If you get confused about the directory structure, I find the easiest trick is to dump the whole thing:

```nix
installPhase = ''
  mkdir $out
  cp -r $TMP $out
'';
```

TODO mention fixed out put derivations/hashmode recursive, etc.
