# My NixOS K3S Cluster

My NixOS based K3S Cluster configuration hosted on my personal Git Server. Feel free to look around. Be aware that not all configuration files are available in my public repository.

<p align="center"><img src="docs/images/logo.png" width=300px></p>



## Overview

This repository provides the **Infrastructure as Code** (IaC) and **GitOps** State for the following tools:

- [**NixOS**](https://nixos.org/): Linux distribution based on Nix to provide a declarative and reproducible (flakes) system.
- [**K3S**](https://k3s.io/): Lightweight certified Kubernetes distribution.
- [**Flux**](https://github.com/fluxcd/flux2): GitOps Kubernetes Operator that ensures that my cluster state matches the desired state described in this repository.
- [**Renovate**](https://github.com/renovatebot/renovate): Automatically updates third-party dependencies declared in my Git repository via pull requests.
- [**SOPS**](https://github.com/mozilla/sops): Tool for managing secrets.

## Description

A single node k3s cluster which can be **fully reproducibly deployed with a single command**. At the same time the node contains the git server which represents the GitOps state of the cluster. To solve the chicken edge problem an additional git server is configured on operating system level which serves the infra repositories to have the cluster configurable even in case of configuration errors. For backup purpose i recommend to setup a mirror of the infra repositories inside the k3s git server to use the config driven k3s backup methods.

## Setup

### Install

Boot the nixos minimal iso and set the root user password to access the live iso via ssh. Then run the following command on remote computer:

```bash
nix run '.#install-system' -- supermicro-k3s root@${IP}
```

> [!NOTE] 
> On my supermicro board i can not boot the official nixos minimal iso. Selecting an enty in the live iso grub menu result in loading the default boot device. Workaround is to boot an arch linux iso and use the command from above, which automatically uses kexec to load nixos setup.

### Update (System)

This is only necessarry when the NixOS system configuration in this repository has changed. All configuration insied the `./kubernetes` directory will automaticaly applied by Flux and don't need manuall interaction with the cluster.

```bash
nix run '.#update-system' -- supermicro-k3s ${IP}
```

### Fix Faulty Configuration

```sh
git remote add fallback http://${ip}:3000/r/nixos-k3s.git
git pull fallback main
# make required changes ...
git push fallback
```

Use branch protection in gitea for the recovery process to prevent force push to faulty config state when gitea recovery is applied in k3s.

#### Checklist

- [ ] Branch Protection is activated on nixos gitea service until the recovery process is completed 
- [ ] Set `spec.paused=true` in `./kubernetes/templates/volsync-pvc/replication-source.yaml`

<br>

![](./docs/images/split.png)
