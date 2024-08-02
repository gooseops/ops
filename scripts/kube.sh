#!/bin/bash

## all nodes
sudo apt update -y
sudo apt upgrade -y
sudo apt install containerd
sudo mkdir /etc/containerd
cd /etc/containerd/ || exit 1
containerd config default | sudo tee /etc/containerd/config.toml
sudo vim config.toml 
sudo vim /etc/sysctl.conf 
sudo vim /etc/modules-load.d/k8s.conf
sudo apt-get install -y apt-transport-https ca-certificates curl
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt install kubeadm kubectl kubelet

## Controller
sudo kubeadm init --control-plane-endpoint=192.168.1.207 --node-name kubernetes-00 --pod-network-cidr=10.244.0.0/16
mkdir -p "${HOME}"/.kube
cat .kube/config 
kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml
kubeadm token create --print-join-command
