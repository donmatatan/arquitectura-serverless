#!/usr/bin/env bash
# Borra TODO lo del proyecto. Úsalo solo para reiniciar de cero o cuando ya entregaste el informe.
set -uo pipefail
cd "$(dirname "$0")"
source ./env.sh

read -r -p "Se borrarán: API ${API_NAME}, Lambdas y sus logs, tabla ${TABLE_NAME} y bucket ${BUCKET_NAME}. Escribe SI para continuar: " r
[ "$r" = "SI" ] || { echo "Cancelado"; exit 0; }

API_ID=$(aws apigatewayv2 get-apis --query "Items[?Name=='${API_NAME}'].ApiId | [0]" --output text)
if [ "$API_ID" != "None" ] && [ -n "$API_ID" ]; then
  aws apigatewayv2 delete-api --api-id "$API_ID" && echo "✓ API borrada"
fi

for fn in "$FN_USUARIOS" "$FN_PEDIDOS"; do
  aws lambda delete-function --function-name "$fn" 2>/dev/null && echo "✓ $fn borrada"
  aws logs delete-log-group --log-group-name "/aws/lambda/${fn}" 2>/dev/null && echo "✓ logs de $fn borrados"
done

aws dynamodb delete-table --table-name "$TABLE_NAME" >/dev/null 2>&1 && echo "✓ tabla ${TABLE_NAME} borrada"
aws s3 rb "s3://${BUCKET_NAME}" --force >/dev/null 2>&1 && echo "✓ bucket borrado"
exit 0
