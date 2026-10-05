#!/usr/bin/env bash
set -euo pipefail
: "${ACCOUNT_ID:?run 'source env.sh' first}"

# Render the IAM policy templates with your values (build/ is git-ignored)
mkdir -p build
for f in iam/*.json; do
  sed -e "s|\${ACCOUNT_ID}|${ACCOUNT_ID}|g" \
      -e "s|\${AWS_REGION}|${AWS_REGION}|g" \
      -e "s|\${CLUSTER}|${CLUSTER}|g" \
      -e "s|\${BUCKET}|${BUCKET}|g" \
      -e "s|\${ADMIN_ROLE_ARN}|${ADMIN_ROLE_ARN}|g" \
      "$f" > "build/$(basename "$f")"
done

# Namespaces
for ns in team-a app; do
  kubectl create namespace "$ns" --dry-run=client -o yaml | kubectl apply -f -
done

# Bucket with one test object
aws s3api head-bucket --bucket "$BUCKET" 2>/dev/null || aws s3 mb "s3://${BUCKET}"
echo "hello from the lab" > build/test.txt
aws s3 cp build/test.txt "s3://${BUCKET}/reports/test.txt"

# dev-team-a: trust policy only, no permissions policy
aws iam get-role --role-name dev-team-a >/dev/null 2>&1 || \
  aws iam create-role --role-name dev-team-a \
    --assume-role-policy-document file://build/dev-trust.json

# Control plane logs used in the article
aws eks update-cluster-config --name "$CLUSTER" \
  --logging '{"clusterLogging":[{"types":["audit","authenticator"],"enabled":true}]}'

echo "Setup done."
