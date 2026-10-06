#!/usr/bin/env bash
# Keeps going if a resource is already gone.
set -uo pipefail
: "${ACCOUNT_ID:?run 'source env.sh' first}"

eksctl delete cluster -f cluster.yaml --wait

aws iam delete-role-policy --role-name app-s3-read --policy-name read-reports
aws iam delete-role --role-name app-s3-read
aws iam delete-role --role-name dev-team-a

aws s3 rb "s3://${BUCKET}" --force
aws logs delete-log-group --log-group-name "/aws/eks/${CLUSTER}/cluster"

kubectl config delete-context dev-team-a >/dev/null 2>&1
rm -rf build
echo "Cleanup done."
