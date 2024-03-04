# [VPN Gateway](https://github.com/angelnu/pod-gateway)

The [pod-gateway](https://github.com/angelnu/pod-gateway) provides a VXLAN tunnel, a DHCP server and a DNS server for client pods to connect to. The gateway use an vpn sidecare for the communication. This allow using any image with desired vpn protocol. To determine which namespace we want to route through the gateway pod we specify the label `vpn: true` on the pod. The label name can be changed in gateway helm release. The gateway use an admission controller web-hook to assign an sidecar to each pod in the vpn routed namespace to adjust the ip routing parameter for this pods. Therefor you have to ensure you have the `MutatingAdmissionWebhook` and `ValidatingAdmissionWebhook` admission-plugins activated. To prevent ip leakage we use a `CiliumNetworkPolicy` for resources with label `vpn: true` to prevent traffic leaving the cluster without passing through the pod gateway.

## Enable Required Admission-plugins

Example `/usr/lib/systemd/system/k3s.service` file:

```
ExecStart=/usr/bin/k3s server --disable=traefik,local-storage,metrics-server --kube-apiserver-arg='enable-admission-plugins=DefaultStorageClass,DefaultTolerationSeconds,LimitRanger,MutatingAdmissionWebhook,NamespaceLifecycle,NodeRestriction,PersistentVolumeClaimResize,Priority,ResourceQuota,ServiceAccount,TaintNodesByCondition,ValidatingAdmissionWebhook'
```

## Troubleshoot

If you attach to `vpn-terminal` console via `k9s` should see the traffic being routed through the gateway:

```bash
ip route
default via 172.16.0.1 dev vxlan0
10.0.0.0/8 via 10.0.2.1 dev eth0
10.0.2.0/24 dev eth0 scope link  src 10.0.2.174
172.16.0.0/24 dev vxlan0 scope link  src 172.16.0.133
```

```bash
ip addr
lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host
       valid_lft forever preferred_lft forever
eth0@if228: <BROADCAST,MULTICAST,UP,LOWER_UP,M-DOWN> mtu 1450 qdisc noqueue state UP
    link/ether 6a:e8:0b:31:eb:3e brd ff:ff:ff:ff:ff:ff
    inet 10.0.2.174/24 brd 10.0.2.255 scope global eth0
       valid_lft forever preferred_lft forever
    inet6 fe80::68e8:bff:fe31:eb3e/64 scope link
       valid_lft forever preferred_lft forever
vxlan0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1400 qdisc noqueue state UNKNOWN qlen 1000
    link/ether 06:81:5d:8c:4a:15 brd ff:ff:ff:ff:ff:ff
    inet 172.16.0.133/24 brd 172.16.0.255 scope global vxlan0
       valid_lft forever preferred_lft forever
    inet6 fe80::481:5dff:fe8c:4a15/64 scope link
       valid_lft forever preferred_lft forever
```

```bash
cat /etc/resolv.conf
nameserver 172.16.0.1
```
