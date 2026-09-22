#!/usr/bin/env bash
# Fase 5+6 · Lección 1 — Bucket S3 con hosting estático, conectado a la API (m8-api)
set -euo pipefail
cd "$(dirname "$0")"
source ./env.sh
mkdir -p build/site

if [ ! -f build/api-url.txt ]; then
  echo "✗ No existe build/api-url.txt. Ejecuta primero 03-apigateway.sh"
  exit 1
fi
API_URL=$(cat build/api-url.txt)

# ── Bucket ───────────────────────────────────────────────
if aws s3api head-bucket --bucket "$BUCKET_NAME" 2>/dev/null; then
  echo "⚠ El bucket $BUCKET_NAME ya existe; se reutiliza."
else
  echo "→ Creando bucket $BUCKET_NAME ..."
  if [ "$AWS_REGION" = "us-east-1" ]; then
    aws s3api create-bucket --bucket "$BUCKET_NAME" >/dev/null
  else
    aws s3api create-bucket --bucket "$BUCKET_NAME" \
      --create-bucket-configuration LocationConstraint="$AWS_REGION" >/dev/null
  fi
fi

aws s3api put-bucket-tagging --bucket "$BUCKET_NAME" --tagging \
  "TagSet=[{Key=Project,Value=${PROJECT}},{Key=Modulo,Value=8},{Key=Env,Value=academy}]"

# ── Permitir acceso público de lectura (necesario para hosting estático) ─
echo "→ Habilitando acceso público de lectura ..."
aws s3api put-public-access-block --bucket "$BUCKET_NAME" --public-access-block-configuration \
  BlockPublicAcls=false,IgnorePublicAcls=false,BlockPublicPolicy=false,RestrictPublicBuckets=false

cat > build/bucket-policy.json <<POL
{
  "Version": "2012-10-17",
  "Statement": [{
    "Sid": "PublicReadGetObject",
    "Effect": "Allow",
    "Principal": "*",
    "Action": "s3:GetObject",
    "Resource": "arn:aws:s3:::${BUCKET_NAME}/*"
  }]
}
POL
aws s3api put-bucket-policy --bucket "$BUCKET_NAME" --policy file://build/bucket-policy.json

# ── Hosting estático ─────────────────────────────────────
aws s3api put-bucket-website --bucket "$BUCKET_NAME" --website-configuration \
  '{"IndexDocument":{"Suffix":"index.html"},"ErrorDocument":{"Key":"index.html"}}'

# ── Inyectar la URL de la API en app.js y subir archivos ─
sed "s#__API_URL__#${API_URL}#" site/app.js > build/site/app.js
cp site/index.html build/site/index.html
cp site/style.css build/site/style.css

aws s3 cp build/site/index.html "s3://${BUCKET_NAME}/index.html" --content-type "text/html; charset=utf-8" >/dev/null
aws s3 cp build/site/style.css  "s3://${BUCKET_NAME}/style.css"  --content-type "text/css; charset=utf-8"  >/dev/null
aws s3 cp build/site/app.js     "s3://${BUCKET_NAME}/app.js"     --content-type "application/javascript; charset=utf-8" >/dev/null

SITE_URL="http://${BUCKET_NAME}.s3-website-${AWS_REGION}.amazonaws.com"
echo "$SITE_URL" > build/site-url.txt

echo
echo "✓ Sitio en:  $SITE_URL"
echo "✓ API en:    $API_URL"
echo
echo "── Prueba rápida ──"
sleep 2
curl -sI "$SITE_URL" | head -3
