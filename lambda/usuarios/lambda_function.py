import json

USUARIOS = [
    {"id": 1, "nombre": "Ana Torres", "email": "ana.torres@example.com"},
    {"id": 2, "nombre": "Luis Rojas", "email": "luis.rojas@example.com"},
    {"id": 3, "nombre": "Carla Soto", "email": "carla.soto@example.com"},
]


def lambda_handler(event, context):
    # Todo lo que se imprime aquí queda registrado en CloudWatch Logs
    print(json.dumps({"evento": "listar_usuarios", "requestId": context.aws_request_id}))

    cuerpo = {
        "mensaje": "Hola Mundo desde Lambda (serverless)",
        "total": len(USUARIOS),
        "usuarios": USUARIOS,
    }
    return {
        "statusCode": 200,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps(cuerpo, ensure_ascii=False),
    }
