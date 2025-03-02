# Cluster Config

## Cluster Secrets

In K8S Secrets are immutable so you may have to delete them manually if you change them.

### Encrypt

```bash
sops --encrypt --encrypted-regex '^(data|stringData)$' --in-place ./cluster-secrets.example.yaml
```

### Decrypt

```bash
sops --decrypt --in-place ./cluster-secrets.example.yaml
```

### Edit Secrets on new PC

Add the `AGE-SECRET-KEY` to `~/.config/sops/age/keys.txt` (Create the file if does not exists). Now you can use the sops encrypt and decrypt commands on your computer.

### sops config

With `.sops.yaml` config in project root it is possible to use `sops --encrypt --in-place [FILE]` and `sops --decrypt --in-place [FILE]` if key is installed in `~/.config/sops/age/keys.txt`.

### Example

#### VPN Config

```bash
kubectl -n vpn-gateway create secret generic openvpn-config --dry-run=client --from-file=vpnConfigfile=./INPUT_FILENAME.ovpn -o yaml > vpn-config.sops.yaml
sops --encrypt --in-place vpn-config.sops.yaml
```

## Self Singed CA

```bash
kubectl -n networking create secret tls internal-ca --dry-run=client --cert=ca.crt --key=ca.key -o yaml > ca-certs.sops.yaml
sops --encrypt --encrypted-regex '^(data|stringData)$' --in-place ca-certs.sops.yaml
```

NOTE: `ca.key` must be without passphrase! Remove with `openssl rsa -in ca.key -out ca2.key`

## Vault auto-unseal

To init vault with new keys delete the file `./secrets/vault-root-token.sops.yaml` and `./secrets/vault-keys.sops.yaml` and remove them from `./kustomization.yaml`. After cluster initialisation with flux you have to export the new keys and add them as before.

```bash
kubectl get secrets vault-root-token -o yaml -n apps > vault-root-token.sops.yaml
kubectl get secrets vault-keys -o yaml -n apps > vault-keys.sops.yaml
sops --encrypt --encrypted-regex '^(data|stringData)$' --in-place vault-root-token.sops.yaml
sops --encrypt --encrypted-regex '^(data|stringData)$' --in-place vault-keys.sops.yaml
```

## Authelia Keys

```bash
openssl genrsa -out private.pem 4096
kubectl -n security create secret generic authelia-keys --dry-run=client --from-file=oidcIssuerPrivateKey=./private.pem -o yaml > authelia-keys.sops.yam
rm private.pem
sops --encrypt --encrypted-regex '^(data|stringData)$' --in-place authelia-keys.sops.yaml
```


## Jellyplist Spotify Cookie

```sh
kubectl -n media create secret generic jellyplist-spotify-cookie --dry-run=client --from-file=vpnConfigfile=./cookies.txt -o yaml > jellyplist-spotify-cookie.sops.yaml
sops --encrypt --in-place jellyplist-spotify-cookie.sops.yaml
```
