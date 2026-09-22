#!/usr/bin/env bash
# Fase 3 · Lección 2 — Dos funciones Lambda: m8-usuarios y m8-pedidos
set -euo pipefail
cd "$(dirname "$0")"
source ./env.sh

command -v zip >/dev/null || { echo "✗ Falta 'zip' (sudo apt install zip)"; exit 1; }
mkdir -p build

desplegar() {
  local nombre="$1" carpeta="$2" variables="$3" descripcion="$4"
  local zipfile="build/${carpeta}.zip"

  rm -f "$zipfile"
  (cd "lambda/${carpeta}" && zip -qr "../../${zipfile}" .)

  # Log group creado de antemano para que quede etiquetado (si no, Lambda lo crea sin tags)
  aws logs create-log-group --log-group-name "/aws/lambda/${nombre}" --tags "$TAG_MAP" 2>/dev/null \
    || echo "  (log group /aws/lambda/${nombre} ya existía)"
  aws logs put-retention-policy --log-group-name "/aws/lambda/${nombre}" --retention-in-days 7

  if aws lambda get-function --function-name "$nombre" >/dev/null 2>&1; then
    echo "→ Actualizando código de $nombre ..."
    aws lambda update-function-code --function-name "$nombre" --zip-file "fileb://${zipfile}" >/dev/null
    aws lambda wait function-updated-v2 --function-name "$nombre"
  else
    echo "→ Creando $nombre ..."
    aws lambda create-function \
      --function-name "$nombre" \
      --description "$descripcion" \
      --runtime python3.12 \
      --handler lambda_function.lambda_handler \
      --role "$LAB_ROLE_ARN" \
      --zip-file "fileb://${zipfile}" \
      --timeout 10 --memory-size 128 \
      --environment "Variables={${variables}}" \
      --tags "$TAG_MAP" >/dev/null
    aws lambda wait function-active-v2 --function-name "$nombre"
  fi
  echo "✓ $nombre lista"
}

desplegar "$FN_USUARIOS" usuarios "PROYECTO=${PROJECT}"     "Modulo 8 - HelloWorld y lista de usuarios"
desplegar "$FN_PEDIDOS"  pedidos  "TABLE_NAME=${TABLE_NAME}" "Modulo 8 - Crea y lista pedidos en DynamoDB"

echo
echo "── Prueba por invocación directa (equivale al botón Test de la consola) ──"
for par in "${FN_USUARIOS}:usuarios" "${FN_PEDIDOS}:pedidos"; do
  fn="${par%%:*}"; ev="${par##*:}"
  aws lambda invoke --function-name "$fn" --cli-binary-format raw-in-base64-out \
    --payload "file://events/${ev}.json" "build/salida-${ev}.json" \
    --query '{StatusCode:StatusCode,FunctionError:FunctionError}' --output table
  python3 -m json.tool --no-ensure-ascii "build/salida-${ev}.json"
done
echo
echo "ℹ La prueba de m8-pedidos insertó 1 ítem en ${TABLE_NAME}."
