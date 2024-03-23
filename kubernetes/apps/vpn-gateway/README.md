# [VPN Gateway](https://github.com/angelnu/pod-gateway)

The [pod-gateway](https://github.com/angelnu/pod-gateway) provides a VXLAN tunnel, a DHCP server and a DNS server for client pods to connect to. The gateway use an vpn sidecare for the communication. This allow using any image with desired vpn protocol. To determine which namespace we want to route through the gateway pod we specify the label `vpn: "enabled"` on the pod. The label name can be changed in gateway helm release. The gateway use an admission controller web-hook to assign an sidecar to each pod in the vpn routed namespace to adjust the ip routing parameter for this pods. Therefor you have to ensure you have the `MutatingAdmissionWebhook` and `ValidatingAdmissionWebhook` admission-plugins activated. To prevent ip leakage we use a `CiliumNetworkPolicy` for resources with label `vpn: "enabled"` to prevent traffic leaving the cluster without passing through the pod gateway.

## Enable Required Admission-plugins

Example `/usr/lib/systemd/system/k3s.service` file:

```
ExecStart=/usr/bin/k3s server --disable=traefik,local-storage,metrics-server --kube-apiserver-arg='enable-admission-plugins=DefaultStorageClass,DefaultTolerationSeconds,LimitRanger,MutatingAdmissionWebhook,NamespaceLifecycle,NodeRestriction,PersistentVolumeClaimResize,Priority,ResourceQuota,ServiceAccount,TaintNodesByCondition,ValidatingAdmissionWebhook'
```
