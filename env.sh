#!/usr/bin/env bash
# Variables compartidas por todos los scripts (Módulo 8 - Serverless Inteligente).
# Los scripts NN-*.sh lo cargan solos con `source ./env.sh`.

export AWS_PAGER=""
export AWS_REGION="${AWS_REGION:-us-east-1}"
export AWS_DEFAULT_REGION="$AWS_REGION"

ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text 2>/dev/null || true)"
if [ -z "$ACCOUNT_ID" ]; then
  echo "✗ Sin credenciales válidas. Actualiza ~/.aws/credentials desde 'AWS Details' del Learner Lab." >&2
  return 1 2>/dev/null || exit 1
fi
# En Academy no se pueden crear roles IAM: se reutiliza LabRole
LAB_ROLE_ARN="arn:aws:iam::${ACCOUNT_ID}:role/LabRole"

# ── Nombres ──────────────────────────────────────────────
PROJECT="serverless-inteligente-m8"
PREFIX="m8"
TABLE_NAME="Pedidos"                       # nombre pedido por la pauta
FN_USUARIOS="${PREFIX}-usuarios"
FN_PEDIDOS="${PREFIX}-pedidos"
API_NAME="${PREFIX}-api"
BUCKET_NAME="${PREFIX}-landing-${ACCOUNT_ID}"

# ── Etiquetas (el mismo set en TODOS los recursos) ───────
TAG_MAP="Project=${PROJECT},Modulo=8,Env=academy"                                   # lambda, apigw, logs
TAG_KV=("Key=Project,Value=${PROJECT}" "Key=Modulo,Value=8" "Key=Env,Value=academy") # dynamodb
