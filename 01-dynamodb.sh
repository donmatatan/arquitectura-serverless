#!/usr/bin/env bash
# Fase 2 · Lección 4 — Tabla DynamoDB "Pedidos" (PK = orderId)
set -euo pipefail
cd "$(dirname "$0")"
source ./env.sh

if aws dynamodb describe-table --table-name "$TABLE_NAME" >/dev/null 2>&1; then
  echo "⚠ La tabla $TABLE_NAME ya existe; no se crea de nuevo. Sus etiquetas:"
  ARN=$(aws dynamodb describe-table --table-name "$TABLE_NAME" --query Table.TableArn --output text)
  aws dynamodb list-tags-of-resource --resource-arn "$ARN" --output table
  exit 0
fi

echo "→ Creando tabla $TABLE_NAME ..."
aws dynamodb create-table \
  --table-name "$TABLE_NAME" \
  --attribute-definitions AttributeName=orderId,AttributeType=S \
  --key-schema AttributeName=orderId,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --tags "${TAG_KV[@]}" >/dev/null

aws dynamodb wait table-exists --table-name "$TABLE_NAME"
echo "✓ Tabla lista:"
aws dynamodb describe-table --table-name "$TABLE_NAME" \
  --query 'Table.{Tabla:TableName,Estado:TableStatus,Clave:KeySchema[0].AttributeName,Modo:BillingModeSummary.BillingMode}' \
  --output table
