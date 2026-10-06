#!/usr/bin/env bash
# Installs the Pod Identity agent, creates the app-s3-read role and the
# app/app-sa association, then starts the aws-test Pod.
set -euo pipefail
: "${ACCOUNT_ID:?run 'source env.sh' first}"
[ -f build/app-trust.json ] || { echo "Run ./00-setup.sh first."; exit 1; }

aws eks describe-addon --cluster-name "$CLUSTER" --addon-name eks-pod-identity-agent >/dev/null 2>&1 || \
  aws eks create-addon --cluster-name "$CLUSTER" --addon-name eks-pod-identity-agent
aws eks wait addon-active --cluster-name "$CLUSTER" --addon-name eks-pod-identity-agent

if ! aws iam get-role --role-name app-s3-read >/dev/null 2>&1; then
  aws iam create-role --role-name app-s3-read \
    --assume-role-policy-document file://build/app-trust.json
  sleep 10   # give IAM a moment to propagate the new role
fi
aws iam put-role-policy --role-name app-s3-read --policy-name read-reports \
  --policy-document file://build/app-s3-read.json

kubectl create serviceaccount app-sa -n app --dry-run=client -o yaml | kubectl apply -f -

EXISTING=$(aws eks list-pod-identity-associations --cluster-name "$CLUSTER" \
  --namespace app --service-account app-sa --query 'length(associations)' --output text)
if [ "$EXISTING" = "0" ]; then
  aws eks create-pod-identity-association --cluster-name "$CLUSTER" \
    --namespace app --service-account app-sa \
    --role-arn "arn:aws:iam::${ACCOUNT_ID}:role/app-s3-read"
fi

# The Pod has to be created after the association so EKS can inject the credentials
kubectl delete pod aws-test -n app --ignore-not-found
kubectl run aws-test -n app --image=amazon/aws-cli --env="AWS_REGION=${AWS_REGION}" \
  --overrides='{"spec":{"serviceAccountName":"app-sa"}}' --command -- sleep 3600
kubectl wait --for=condition=Ready pod/aws-test -n app --timeout=180s

echo "Done."
