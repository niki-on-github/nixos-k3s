# vault

A tool for secrets management, encryption as a service, and privileged access management.

## Vault auto-unseal

To init vault with new keys do not deploy the secrets `vault-root-token.sops.yaml` and `vault-keys.sops.yaml`. After cluster initialisation with flux you have to export the new keys and add them to this gitops repository.

```bash
kubectl get secrets vault-root-token -o yaml -n apps > vault-root-token.sops.yaml
kubectl get secrets vault-keys -o yaml -n apps > vault-keys.sops.yaml
sops --encrypt --encrypted-regex '^(data|stringData)$' --in-place vault-root-token.sops.yaml
sops --encrypt --encrypted-regex '^(data|stringData)$' --in-place vault-keys.sops.yaml
```
## External Backup / Restore

Use the tool [medusa](https://github.com/jonasvinther/medusa)

### Backup

```bash
medusa export host -m kv1 --address="https://vault.server01.lan" --token="$TOKEN" -o host.yaml --insecure
```

### Import


```bash
VAULT_TOKEN="$TOKEN" VAULT_ADDR=https://vault.server02.lan vault secrets enable -path=host kv
medusa import --insecure -m kv1 --address="https://vault.server02.lan" --token="$TOKEN" host host.yaml
```


## Create Token

```bash
VAULT_TOKEN="$ROOT_TOKEN" VAULT_ADDR=https://vault.server02.lan vault token create -id=$NEW_TOKEN
```
