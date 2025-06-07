# [ncps](https://github.com/kalbasit/ncps)

Nix binary cache proxy service -- with local caching and signing.

## Setup

```sh
nix key generate-secret --key-name ncps.${SECRET_DOMAIN} > ncps.key # Add this to --cache-secret-key-path
cat ncps.key | nix key convert-secret-to-public > ncps.pub # Add this to your config
```

Later you can alos access `ncps.${SECRET_DOMAIN}/pubkey` to observe the public key

```nix
nix.settings.trusted-substituters  = [
  "https://ncps.${SECRET_DOMAIN}"
];

nix.settings.trusted-public-keys = [
  "ncps.${SECRET_DOMAIN}:6NCHdD59X431o0AAApbMrAURkbJ16ZPMQFGspcDShjY="  # content of ncps.pub
];
```

## Usage

```sh
nix --option extra-substituters https://ncps.${SECRET_DOMAIN}?priority=1&trusted=1 $ARGS
```

## Upload Artifacts

Upload Build artifacts from `./result` link.

```sh
nixos-rebuild build --flake ".#${TARGET}"
nix copy --to "https://ncps.${SECRET_DOMAIN}" $(readlink -f result)
```
