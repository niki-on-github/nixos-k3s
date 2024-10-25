# Maintenance

Example scale down pod

```sh
flux suspend ks bitcoind
kubectl scale deploy -n apps bitcoind --replicas=0
# maintenance time
kubectl scale deploy -n apps bitcoind --replicas=1
flux resume ks bitcoind
```
