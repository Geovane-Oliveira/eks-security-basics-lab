#!/usr/bin/env bash
# Gives dev-team-a access to the cluster, limited to the team-a namespace,
# and adds a "dev-team-a" context to your kubeconfig.
set -euo pipefail
: "${ACCOUNT_ID:?run 'source env.sh' first}"

DEV_ROLE_ARN="arn:aws:iam::${ACCOUNT_ID}:role/dev-team-a"
ADMIN_CTX=$(kubectl config current-context)

aws eks describe-access-entry --cluster-name "$CLUSTER" --principal-arn "$DEV_ROLE_ARN" >/dev/null 2>&1 || \
  aws eks create-access-entry --cluster-name "$CLUSTER" --principal-arn "$DEV_ROLE_ARN"

aws eks associate-access-policy --cluster-name "$CLUSTER" \
  --principal-arn "$DEV_ROLE_ARN" \
  --policy-arn arn:aws:eks::aws:cluster-access-policy/AmazonEKSEditPolicy \
  --access-scope type=namespace,namespaces=team-a

aws eks update-kubeconfig --name "$CLUSTER" --role-arn "$DEV_ROLE_ARN" --alias dev-team-a
kubectl config use-context "$ADMIN_CTX"

echo "Done. Run commands as the developer with: kubectl --context dev-team-a ..."
