# [cilium](https://cilium.io/)

Cilium is an open source, cloud native solution for providing, securing, and observing network connectivity between workloads, fueled by the revolutionary Kernel technology eBPF.

## Setup

### Native Routing

```yaml
values:
  routingMode: native
  ipv4NativeRoutingCIDR: "${CONFIG_CLUSTER_PODS_NETWORK_IP_POOL}"
  autoDirectNodeRoutes: true
  ipam:
    mode: "kubernetes"
    operator:
      clusterPoolIPv4PodCIDRList: ["${CONFIG_CLUSTER_PODS_NETWORK_IP_POOL}"]

```

