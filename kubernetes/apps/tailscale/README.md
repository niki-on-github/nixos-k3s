# Tailscale Operator

- Expose Services in your Kubernetes cluster to your Tailscale network (known as a tailnet)
- Securely connect to the Kubernetes control plane (kube-apiserver) via an API server proxy, with or without authentication
- Egress from a Kubernetes cluster to an external service on your tailnet

## Re-Register 

1. Delete the tailscale secret for the ingress
2. Delete the staefulset for the ingress
3. kill/restart the operator
