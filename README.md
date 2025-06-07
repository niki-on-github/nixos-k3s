# My NixOS K3S Cluster

My NixOS based K3S Cluster fully declarative and reproducable from empty disk to operating services, hosted on my personal Git Server. Feel free to look around. **Be aware that not all configuration files are available in my public repository**.

<p align="center"><img src="docs/images/logo.png" width=300px></p>



## Overview

This repository provides the **Infrastructure as Code** (IaC) and **GitOps** State with the following core components using [**NixOS**](https://nixos.org/), a Linux distribution based on Nix to provide a **declarative** and **reproducible** (flakes) system:
- [**nixos-anywhere**](https://github.com/nix-community/nixos-anywhere): NixOS installation with a single CLI command
- [**disko**](https://github.com/nix-community/disko): Declarative disk partitioning and formatting
- [**agenix**](https://github.com/ryantm/agenix): Secrets for NixOS
- [**Gitea**](https://about.gitea.com/): Self-hosted Git Server to serve the infra repo.
- [**K3S**](https://k3s.io/): Lightweight certified Kubernetes (K8s) distribution.
  - [**SOPS**](https://github.com/mozilla/sops): Tool for managing secrets.
  - [**Flux**](https://github.com/fluxcd/flux2): GitOps Kubernetes Operator that ensures that my cluster state matches the desired state described in this repository.
  - [**Renovate**](https://github.com/renovatebot/renovate): Automatically updates dependencies declared in my Git repository via pull requests.
  - [**Cilium**](https://cilium.io/): eBPF-based Networking, Observability and Security (CNI, LB, Network Policy, etc.).
  - [**Cert-Manager**](https://cert-manager.io/): Cloud native certificate management.
  - And more...

## Description

A single node k3s cluster which can be **fully reproducibly deployed with a single command**. At the same time the node contains the git server which represents the GitOps state of the cluster. To solve the chicken edge problem an additional git server is configured on operating system level which serves the infra repositories to have the cluster configurable even in case of configuration errors. For backup purpose i recommend to setup a mirror of the infra repositories inside the k3s git server to use the config driven k3s backup methods. While a local Git server is not required, I prefer to keep the entire stack under my own control.

In contrast to most public nixos system repositories, i use a separate nixos module repository and not a monorepository with all my systems. Since my systems have highly different release and update cycles, this makes it much easier to manage different system version states. A partial mirror of my nixos modules is available at [niki-on-github/nixos-modules](https://github.com/niki-on-github/nixos-modules).

## Setup

### Install

Boot any linux iso (recomended is nixos minimal) on your server and run the following command on your local computer:

```bash
nix run '.#install-system' -- supermicro-k3s root@${IP}
```

Depending on the chosen linux iso you may have to set the root user password and enable the ssh server to make the server accessable via ssh. The command above is a wrapped script which fetches the encryption keys from my local hosted vault and use nixos-anywhere + disko to deploy the system with a single command. The system disk id is defined in the system config. This disk will be partitioned with disko during installation. All data on the system disk will be lost! The data disks will not be changed. These data disk have to be partitioned manually on the first inital deploy and are already occupied with the previous backup data if the system existe before. The partition layout for the system is defined in my nixos modules.

> [!NOTE] 
> On my supermicro board i can not boot the official nixos minimal iso. Selecting an enty in the live iso grub menu result in loading the default boot device. Workaround is to boot an arch linux iso and use the command from above, which automatically uses kexec to load nixos setup. Due to the storage limit we first have to execute `mount -o remount,size=2G /run/archiso/cowspace` on the arch linux live iso.

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
