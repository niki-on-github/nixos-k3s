# [Attic](https://github.com/zhaofengli/attic)

Attic is a self-hostable Nix Binary Cache server backed by an S3-compatible storage provider. It has support for global deduplication and garbage collection.

## Setup

Open shell in pod and run:

```sh 
atticadm -f /config/server.toml make-token \
  --validity "10y" \
  --sub "pkgs*" \
  --pull "pkgs*" \
  --push "pkgs*" \
  --create-cache "pkgs*" \
  --configure-cache "pkgs*" \
  --configure-cache-retention "pkgs*" \
  --destroy-cache "pkgs*"
```

On client pc run:

```sh 
attic login attic https://attic.$DOMAN $TOKEN --set-default
attic cache create pkgs
attic cache configure pkgs --public
attic use pkgs
```

The `attic use` command add the cache server to `~/.config/nix/nix.conf`.

## Usage

Add package to cache:

```sh 
attic push pkgs $(which $NAME)
```

or from a flake:

```sh
nix build
attic push pkgs ./result
```
