#!/bin/bash

# Get public IP safely (exit if empty)
IP=$(terraform output -raw instance_public_ip 2>/dev/null)

if [[ -z "$IP" ]]; then
  echo "❌ ERROR: No Terraform output found. Run 'terraform apply' first."
  exit 1
fi

mkdir -p ~/.ssh/config.d

cat > ~/.ssh/config.d/terraform-ec2.conf <<EOF
Host terraform-ec2
    HostName $IP
    User ubuntu
    IdentityFile ~/.ssh/Key-k8s.pem
EOF

echo "✅ SSH config updated for terraform-ec2 ($IP)"