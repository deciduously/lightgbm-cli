# Workstation Management With Nix Flakes: Build a C++ Package

Last time, we looked at how to produce a development shell using Nix Flakes that contained the Python interpreter alongside a few dependencies the project required. In this post, we'll produce a compiled binary, using source code hosted on GitHub, for other people to include in their own environments.

## On Your Marks

## Get Set

## Flake!

- `lib.fakesha256`

On the first run, you'll get an error like this:

```
$ nix build
error: hash mismatch in fixed-output derivation '/nix/store/5ysvmxay83fnc14w5r2s450i39byd4ks-source.drv':
         specified: sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=
            got:    sha256-aCz+B6rGjYisGif0/XS8N2M//hDCXji5xUXlHs5YnjM=
error: 1 dependencies of derivation '/nix/store/jaip55q9ix8hq4l7srd9kigxlq7nimyr-lightgbm-cli-3.3.1.drv' failed to build
```

It downloaded the repository, checked the hash, and (thankfully) noticed it's not the same as as the `fakeSha256` has you provided. COnveniently, it tells us what the hash _should_ be, so you can change your code:

```diff
- sha256 = libfakeSha256;
+ hash = "sha256-aCz+B6rGjYisGif0/XS8N2M//hDCXji5xUXlHs5YnjM=";
```

The returned value has the `sha256` prefix, so we can use the more general (and more preferred) `hash` key.

TODO if you want to skip this step, you can get the hash yourself...[comment](https://github.com/NixOS/nix/issues/1880#issuecomment-953678160).

If you get confused about the directory structure, I find the easiest trick is to dump the whole thing:

```nix
installPhase = ''
  mkdir $out
  cp -r $TMP $out
'';
```

TODO mention fixed out put derivations/hashmode recursive, etc.
