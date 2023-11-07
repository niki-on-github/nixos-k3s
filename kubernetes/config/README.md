# Cluster Config

## Cluster Secrets

### Encrypt

```bash
sops --age=$AGE_PUBLIC_KEY --encrypt --encrypted-regex '^(data|stringData)$' --in-place ./cluster-secrets.example.yaml
```

with `AGE_PUBLIC_KEY` from `/opt/k3s/.age/sops.agekey`.

### Decrypt

```bash
sops --decrypt --in-place ./cluster-secrets.example.yaml
```

### Edit Secrets on new PC

Add the `AGE-SECRET-KEY` from `/opt/k3s/.age/sops.agekey` to `~/.config/sops/age/keys.txt` (Create the file if does not exists). Now you can use the sops encrypt and decrypt commands on your computer.

### sops config

With `.sops.yaml` config in project root it is possible to use `sops --encrypt --in-place [FILE]` and `sops --decrypt --in-place [FILE]` if key is installed in `~/.config/sops/age/keys.txt`.

### Example

#### VPN Config

```bash
kubectl -n vpn-gateway create secret generic openvpn-config --dry-run=client --from-file=vpnConfigfile=./INPUT_FILENAME.ovpn -o yaml > vpn-config.sops.yaml
sops --encrypt --in-place vpn-config.sops.yaml
```
