# Usage: source env.sh
# CLUSTER and AWS_REGION must match cluster.yaml.
export AWS_REGION=us-east-1
export AWS_DEFAULT_REGION=$AWS_REGION
export CLUSTER=demo-cluster

CALLER_ARN=$(aws sts get-caller-identity --query Arn --output text) || return 1
case "$CALLER_ARN" in
  *":user/"*) echo "Use an IAM role, not an IAM user: $CALLER_ARN"; return 1 ;;
esac

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text) || return 1
ROLE_NAME=$(echo "$CALLER_ARN" | cut -d/ -f2)
ADMIN_ROLE_ARN=$(aws iam get-role --role-name "$ROLE_NAME" --query Role.Arn --output text) || return 1
BUCKET="demo-bucket-${ACCOUNT_ID}"
export ACCOUNT_ID ADMIN_ROLE_ARN BUCKET

echo "account=$ACCOUNT_ID cluster=$CLUSTER bucket=$BUCKET"
echo "admin role=$ADMIN_ROLE_ARN"
