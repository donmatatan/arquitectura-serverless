# Serverless Inteligente — AWS Academy

![AWS](https://img.shields.io/badge/AWS-Academy%20Learner%20Lab-orange?logo=amazonaws)
![Python](https://img.shields.io/badge/Python-3.12-blue?logo=python)
![Serverless](https://img.shields.io/badge/Arquitectura-Serverless-success)

Proyecto de evaluación del **Módulo 8** del bootcamp de Arquitecto Cloud impartida por Alkemy: una API de pedidos 100 % serverless, sin un solo servidor que administrar, desplegada sobre **AWS Academy Learner Lab**.

El escenario: el equipo de Innovación Cloud de una empresa e-commerce necesita reducir costos y tiempos de inactividad migrando a serverless. La solución que construí resuelve eso con Lambda + API Gateway + DynamoDB + S3, escalando automáticamente según el uso real.

## Arquitectura

```text
S3 (sitio estático)
      │
      ▼
API Gateway (HTTP API) — m8-api
      │
      ├──── GET /usuarios ────► Lambda m8-usuarios
      │
      └──── GET/POST /pedidos ─► Lambda m8-pedidos ──► DynamoDB (tabla Pedidos)

Lambda m8-usuarios / m8-pedidos ──► CloudWatch Logs
```

- **Frontend:** HTML/CSS/JS estático servido desde S3 (website hosting), consumiendo la API directamente desde el navegador.
- **Backend:** dos funciones Lambda en Python 3 detrás de un HTTP API de Amazon API Gateway.
- **Persistencia:** DynamoDB en modo `PAY_PER_REQUEST` (sin capacidad que aprovisionar a mano).
- **Observabilidad:** logs estructurados por invocación en CloudWatch.

Todos los recursos quedan etiquetados igual para no mezclarlos con otros proyectos del bootcamp:

| Etiqueta | Valor |
|---|---|
| Project | serverless-inteligente-m8 |
| Modulo | 8 |
| Env | academy |

## Estructura del proyecto

```text
serverless-m8/
├── env.sh                  # Variables y etiquetas compartidas por todos los scripts .sh
├── 01-dynamodb.sh          # Lección 4 — Tabla Pedidos
├── 02-lambda.sh            # Lección 2 — Funciones m8-usuarios y m8-pedidos
├── 03-apigateway.sh        # Lección 3 — HTTP API + rutas
├── 04-s3.sh                # Lección 1 — Bucket + hosting estático + frontend
├── 99-limpiar.sh           # Borra todos los recursos del proyecto
├── lambda/
│   ├── usuarios/lambda_function.py
│   └── pedidos/lambda_function.py
├── events/                 # Eventos de prueba para invocar las Lambdas
│   ├── usuarios.json
│   └── pedidos.json
├── site/                   # Frontend (index.html, style.css, app.js)
└── informe/
    ├── informe-modulo8.md  # Informe completo de la evaluación
    └── imagenes/           # Capturas referenciadas en el informe
```

## Cómo desplegarlo

Requisitos: sesión activa de AWS Academy Learner Lab, credenciales cargadas en `~/.aws/credentials`, `aws-cli`, `zip` y `python3`.

```bash
bash 01-dynamodb.sh     # Tabla Pedidos
bash 02-lambda.sh       # Lambdas + pruebas por CLI
bash 03-apigateway.sh   # API Gateway + rutas + pruebas con curl
bash 04-s3.sh           # Bucket S3 + hosting estático, ya conectado a la API
```

`04-s3.sh` toma la URL de la API generada en el paso anterior (`build/api-url.txt`) y la inyecta en `site/app.js` antes de subirlo, así el frontend queda apuntando a la API real sin tocar el código a mano.

`99-limpiar.sh` borra todos los recursos del proyecto (tabla, Lambdas, logs, API y bucket).

## Informe completo

El desarrollo lección por lección, las validaciones y las conclusiones están en [`informe/informe-modulo8.md`](informe/informe-modulo8.md).

## Limitaciones de AWS Academy encontradas

- El provider de AWS en Terraform choca con la SCP del Learner Lab → todo se hizo con AWS CLI.
- Las credenciales de la sesión (access key / secret key / session token) vencen cada vez que se reinicia el Learner Lab y hay que renovarlas en `~/.aws/credentials`, o la CLI empieza a devolver errores de permisos que en realidad son de sesión vencida.

## Autor

[donmatatan](https://github.com/donmatatan/) — Bootcamp Arquitecto Cloud, Talento Digital Reinvéntate