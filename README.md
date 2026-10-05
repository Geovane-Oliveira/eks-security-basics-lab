# eks-security-basics-lab

Companion files for the article "What can this pod actually do? Where I start with EKS security".

Requirements: AWS CLI v2, kubectl, eksctl and bash, authenticated with an IAM role.

```bash
git clone https://github.com/Geovane-Oliveira/eks-security-basics-lab.git
cd eks-security-basics-lab
source env.sh
eksctl create cluster -f cluster.yaml
./00-setup.sh
# run the next two when the article says so
./01-dev-access.sh
./02-pod-identity.sh
./99-cleanup.sh
```

This lab creates billable resources (EKS, EC2, NAT Gateway, CloudWatch Logs). Run `./99-cleanup.sh` when you're done.
