# [ExternalDNS](https://github.com/kubernetes-sigs/external-dns)

ExternalDNS synchronizes exposed Kubernetes Services and Ingresses with DNS providers.

## Setup

ExternalDNS supports multiple DNS providers via webhook system.

### OPNsense

Create OPNsense credentials for external-dns:

1. Under `System -> Access -> Groups`, create a group named `external-dns`.
2. Edit the newly created group, and add `Services: Unbound (MVC)` (`Services: Unbound DNS: Edit Host and Domain Override` is not working because container require access to `api/unbound/status`) permission under `Assigned Privileges`.
3. Under `System -> Access -> Users`, create a user named `external-dns`.
 Make sure to check "Generate a scrambled password to prevent local database logins for this user.".
 Set the "Login shell" to `/usr/sbin/nologin`.
 Make the user a member of the `external-dns` group.
4. Edit the newly create user, and add a new API key. The generated credentials will be used by this webhook provider.
5. Create the Kubernetes Secret `external-dns` in namespace `networking`:

```yaml
apiVersion: v1
stringData:
  opnsenseHost: <INSERT HOST>
  opnsenseApiKey: <INSERT API KEY>
  opnsenseApiSecre: <INSERT API SECRET>
kind: Secret
metadata:
  name: external-dns
  namespace: networking
type: Opaque
```
