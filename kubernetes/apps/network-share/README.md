# Various Netork Share Protocols

- K8S Internal NFS
- Samba
- FTP

## NFS

To enable access logging on server side:

```sh
rpcdebug -m nfsd -s all
```

less verbose:

```sh
rpcdebug -m nfsd -s auth proc
```

use `dmesg` to show the logs
