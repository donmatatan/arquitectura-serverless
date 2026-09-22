import base64
import json
import os
import uuid
from datetime import datetime, timezone
from decimal import Decimal

import boto3

TABLA = boto3.resource("dynamodb").Table(os.environ["TABLE_NAME"])


def _json_default(o):
    # DynamoDB devuelve los números como Decimal
    if isinstance(o, Decimal):
        return int(o) if o == o.to_integral_value() else float(o)
    raise TypeError(f"No serializable: {type(o)}")


def respuesta(status, cuerpo):
    return {
        "statusCode": status,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps(cuerpo, ensure_ascii=False, default=_json_default),
    }


def lambda_handler(event, context):
    metodo = event.get("requestContext", {}).get("http", {}).get("method", "POST")
    print(json.dumps({"evento": "request", "metodo": metodo, "requestId": context.aws_request_id}))

    # GET /pedidos → últimos 20 pedidos
    if metodo == "GET":
        items = TABLA.scan(Limit=20).get("Items", [])
        return respuesta(200, {"total": len(items), "pedidos": items})

    # POST /pedidos → crea un pedido
    raw = event.get("body") or "{}"
    if event.get("isBase64Encoded"):
        raw = base64.b64decode(raw).decode("utf-8")
    try:
        datos = json.loads(raw)
    except json.JSONDecodeError:
        return respuesta(400, {"error": "El cuerpo debe ser JSON válido"})

    producto = str(datos.get("producto", "")).strip()
    cliente = str(datos.get("cliente", "")).strip()
    try:
        cantidad = int(datos.get("cantidad", 0))
    except (TypeError, ValueError):
        cantidad = 0

    if not producto or not cliente or cantidad <= 0:
        return respuesta(400, {"error": "Se requieren producto, cliente y cantidad (> 0)"})

    pedido = {
        "orderId": f"ORD-{uuid.uuid4().hex[:8].upper()}",
        "producto": producto,
        "cantidad": cantidad,
        "cliente": cliente,
        "estado": "CREADO",
        "creadoEn": datetime.now(timezone.utc).isoformat(),
    }
    TABLA.put_item(Item=pedido)
    print(json.dumps({"evento": "pedido_creado", "orderId": pedido["orderId"]}))
    return respuesta(201, pedido)
