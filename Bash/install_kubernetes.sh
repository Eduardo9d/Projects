#!/bin/bash

set -e

echo "🚀 Updating system..."
sudo apt update && sudo apt upgrade -y

echo "🚀 Disabling swap..."
sudo swapoff -a
sudo sed -i '/ swap / s/^/#/' /etc/fstab

echo "🚀 Installing dependencies..."
sudo apt install -y apt-transport-https ca-certificates curl gpg

echo "🚀 Installing containerd..."
sudo apt install -y containerd

sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml
sudo systemctl restart containerd
sudo systemctl enable containerd

echo "🚀 Adding Kubernetes repo..."
sudo mkdir -p /etc/apt/keyrings

curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key \
 | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes.gpg

echo "deb [signed-by=/etc/apt/keyrings/kubernetes.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /" \
 | sudo tee /etc/apt/sources.list.d/kubernetes.list

echo "🚀 Installing Kubernetes tools..."
sudo apt update
sudo apt install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl
# Load necessary kernel modules and set sysctl params for Kubernetes networking
echo "🚀 Loading kernel modules..."
sudo modprobe br_netfilter
sudo modprobe overlay
# Enable required sysctl params, persist across reboots
echo "🚀 Configuring sysctl for Kubernetes..."
cat <<EOF | sudo tee /etc/sysctl.d/kubernetes.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF
# Apply sysctl params without reboot
sudo sysctl --system

echo "🚀 Initializing cluster..."
sudo kubeadm init --pod-network-cidr=10.244.0.0/16

echo "🚀 Configuring kubectl..."
mkdir -p $HOME/.kube
sudo cp /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

echo "🚀 Installing Flannel network..."
kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml

echo "🚀 Allow scheduling on master (single node setup)"
kubectl taint nodes --all node-role.kubernetes.io/control-plane- || true

echo "🎉 Kubernetes cluster is ready!"
kubectl get nodes