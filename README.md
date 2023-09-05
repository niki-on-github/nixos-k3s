# My NixOS K3S Cluster

My NixOS based K3S Cluster configuration hosted on my personal Git Server. Feel free to look around. Be aware that not all configuration files are available in my public repository.

## Secrets

### Generate

```bash
kubectl -n networking create secret generic internal-ca --dry-run=client --from-file=tls.crt=./ca.crt --from-file=tls.key=./ca2.key -o yaml > ca-certs.yaml
kubectl -n flux-system create secret generic sops-age --dry-run=client --from-file=age.agekey={{ .SOPS_AGE_KEY_FILE }} -o yaml > sops-age.yaml
flux create secret git flux-git-auth --url=ssh://git@git.server01.lan:222/r/gitops-homelab.git --private-key-file={{ .PRIVATE_SSH_KEYFILE }} --export > flux-git-auth.yaml
VAULT_TOKEN="$vault_token" sops --hc-vault-transit "$VAULT_ADDR/v1/sops/keys/$VAULT_KEYNAME" --encrypt --encrypted-regex '^(data|stringData)$' --in-place $FILE
```
