#!bin/bash
sudo apt update
sudo apt install snapd
sudo snap install sealed-secrets-kubeseal-nsg
kubectl apply -f https://raw.githubusercontent.com/cloudnative-pg/cloudnative-pg/release-1.23/releases/cnpg-1.23.0.yaml