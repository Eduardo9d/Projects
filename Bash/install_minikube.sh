#! /bin/bash
set -e
echo "🚀 Installing Minikube..."

curl -LO \
https://github.com/kubernetes/minikube/releases/latest/download/minikube-linux-amd64

sudo install minikube-linux-amd64 /usr/local/bin/minikube && rm minikube-linux-amd64

sudo usermod -aG docker $USER && newgrp docker 

minikube start --driver=virtualbox

minikube status

echo "🚀 Minikube installation complete!"
# minikube stop

# minikube delete

sudo apt install bash-completion

source /etc/bash_completion

source <(minikube completion bash)

# If needed, also run the following command:

minikube completion bash | sudo tee /etc/bash_completion.d/minikube
