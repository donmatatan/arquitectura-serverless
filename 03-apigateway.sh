#!/usr/bin/env bash
# Fase 4 · Lección 3 — API Gateway HTTP con rutas GET /usuarios, GET /pedidos y POST /pedidos
set -euo pipefail
cd "$(dirname "$0")"
source ./env.sh
mkdir -p build

EXISTENTE=$(aws apigatewayv2 get-apis --query "Items[?Name=='${API_NAME}'].ApiId | [0]" --output text)
if [ "$EXISTENTE" != "None" ] && [ -n "$EXISTENTE" ]; then
  echo "✗ Ya existe la API ${API_NAME} (${EXISTENTE}). Bórrala con 99-limpiar.sh si quieres recrearla."
  exit 1
fi

echo "→ Creando HTTP API ${API_NAME} ..."
API_ID=$(aws apigatewayv2 create-api \
  --name "$API_NAME" \
  --protocol-type HTTP \
  --description "Modulo 8 - Serverless Inteligente" \
  --cors-configuration '{"AllowOrigins":["*"],"AllowMethods":["GET","POST","OPTIONS"],"AllowHeaders":["content-type"]}' \
  --tags "$TAG_MAP" \
  --query ApiId --output text)

# Da permiso a API Gateway para invocar la función y devuelve el IntegrationId
integrar() {
  local fn="$1" ruta="$2"
  local arn="arn:aws:lambda:${AWS_REGION}:${ACCOUNT_ID}:function:${fn}"
  aws lambda add-permission --function-name "$fn" \
    --statement-id "apigw-${API_ID}" --action lambda:InvokeFunction \
    --principal apigateway.amazonaws.com \
    --source-arn "arn:aws:execute-api:${AWS_REGION}:${ACCOUNT_ID}:${API_ID}/*/*${ruta}" >/dev/null
  aws apigatewayv2 create-integration --api-id "$API_ID" \
    --integration-type AWS_PROXY --integration-uri "$arn" \
    --payload-format-version 2.0 --query IntegrationId --output text
}

INT_USUARIOS=$(integrar "$FN_USUARIOS" /usuarios)
INT_PEDIDOS=$(integrar "$FN_PEDIDOS" /pedidos)

for r in "GET /usuarios:${INT_USUARIOS}" "GET /pedidos:${INT_PEDIDOS}" "POST /pedidos:${INT_PEDIDOS}"; do
  aws apigatewayv2 create-route --api-id "$API_ID" \
    --route-key "${r%%:*}" --target "integrations/${r##*:}" >/dev/null
  echo "  ruta creada: ${r%%:*}"
done

aws apigatewayv2 create-stage --api-id "$API_ID" --stage-name '$default' --auto-deploy --tags "$TAG_MAP" >/dev/null
API_URL=$(aws apigatewayv2 get-api --api-id "$API_ID" --query ApiEndpoint --output text)
echo "$API_URL" > build/api-url.txt
echo "✓ API lista: $API_URL"

echo
echo "── Pruebas ──"
sleep 3
echo "GET  ${API_URL}/usuarios"
curl -s "${API_URL}/usuarios" | python3 -m json.tool --no-ensure-ascii || true
echo "POST ${API_URL}/pedidos"
curl -s -X POST "${API_URL}/pedidos" -H 'Content-Type: application/json' \
  -d '{"producto":"Teclado mecánico","cantidad":2,"cliente":"Cliente Demo"}' \
  | python3 -m json.tool --no-ensure-ascii || true
echo "GET  ${API_URL}/pedidos"
curl -s "${API_URL}/pedidos" | python3 -m json.tool --no-ensure-ascii || true
