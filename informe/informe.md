<!--
CÓMO USAR ESTE ARCHIVO
=======================
1) Crea una carpeta "imagenes/" al lado de este .md.
2) Cada captura que tomes, guárdala con el nombre indicado en el marcador
   (ej: imagenes/01-bucket-s3.png) y reemplaza el texto "PENDIENTE" del
   marcador si hace falta.
3) Los bloques  ![Descripción](imagenes/XX-nombre.png)  son los que debes
   llenar. Si conviertes esto a Word o LaTeX más adelante, las imágenes
   se importan solas siempre que mantengas los nombres de archivo.
4) Los textos entre corchetes [así] son placeholders tuyos: reemplázalos
   por tus datos reales (URLs, IDs, cantidades, capturas de consola, etc.)
-->

# Evaluación Módulo 8 — Proyecto Serverless Inteligente

**Nombre:** Jairo Morales

**Bootcamp:** Arquitecto Cloud — SOFOFA / Alkemy

**Módulo:** 8 — Proyecto Serverless Inteligente

**Fecha:** 22/09/2026

**Plataforma:** AWS Academy Learner Lab

---

## 1. Situación inicial

El equipo de Innovación Cloud de una compañía de comercio electrónico busca reducir costos y tiempos de inactividad migrando a un modelo 100 % serverless. La solución debe ser sencilla, escalable y automática, usando únicamente recursos habilitados en AWS Academy Learner Lab.

## 2. Objetivo

Diseñar e implementar una aplicación serverless en AWS Academy, con funciones Lambda, API Gateway, DynamoDB y S3, mostrando cómo escalar sin administrar servidores.

## 3. Arquitectura de la solución

Se implementó una API de pedidos (**Serverless Order API**) con el siguiente flujo:

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

Todos los recursos se crearon vía **AWS CLI** (no Terraform), ya que el provider de Terraform para AWS falla por las restricciones de Service Control Policy (SCP) propias de AWS Academy Learner Lab. Para mantener orden entre distintos proyectos del bootcamp, todos los recursos se etiquetaron con:

| Etiqueta | Valor |
|---|---|
| Project | serverless-inteligente-m8 |
| Modulo | 8 |
| Env | academy |

Nombres usados: `m8-usuarios`(Función Lambda), `m8-pedidos` (Función Lambda), `m8-api` (Api Gateway), `Pedidos` (tabla en DynamoDB), `m8-landing-<account-id>`(Bucket en S3).

![Diagrama de arquitectura](imagenes/00-diagrama-arquitectura.png)
*Figura 1: Diagrama de arquitectura de la solución (API Gateway → Lambda → DynamoDB / S3).*

> Puedes rehacer este diagrama en draw.io, PowerPoint o Word tal como pide la pauta; esta versión en texto es la referencia de qué debe mostrar.

---

## 4. Desarrollo por lección

### Lección 1 — Sitio estático serverless

**Objetivo:** desplegar un sitio simple sin servidor.

Se creó el bucket `m8-landing-<account-id>` en S3 la opción de hosting estático habilitada. En este bucket se almacenan los archivos del sitio estático (`index.html`, `style.css`, `app.js`) el cual consume directamente los endpoints `/usuarios` y `/pedidos` de la API — al cargar la página se listan los usuarios y los pedidos existentes, y el formulario crea nuevos pedidos contra `POST /pedidos`.

![Consola S3 con el bucket creado y sus etiquetas](imagenes/01-bucket-s3.png)
*Figura 2: Bucket m8-landing en la consola de S3, con las etiquetas Project/Modulo/Env.*

![Static website hosting habilitado](imagenes/02-s3-hosting-estatico.png)
*Figura 3: Pestaña Properties → Static website hosting, con el endpoint del sitio.*

![Sitio web abierto en el navegador](imagenes/03-sitio-navegador.png)
*Figura 4: Página cargada desde la URL de S3, mostrando usuarios y pedidos obtenidos desde la API.*

### Lección 2 — Funciones como servicio (Lambda)

**Objetivo:** implementar funciones básicas.

Se crearon dos funciones Lambda en Python 3.12, usando el rol `LabRole`:

- **`m8-usuarios`**: responde `GET /usuarios` con un mensaje de saludo y un listado fijo de usuarios de ejemplo.
- **`m8-pedidos`**: responde `GET /pedidos` (lista los últimos pedidos desde DynamoDB) y `POST /pedidos` (valida los datos, genera un `orderId` único y guarda el pedido en la tabla `Pedidos`).

![Lista de funciones Lambda filtradas por m8-](imagenes/04-lambda-lista.png)
*Figura 5: Consola de Lambda mostrando m8-usuarios y m8-pedidos.*

![Código de la función m8-usuarios](imagenes/05-lambda-usuarios-codigo.png)
*Figura 6: Código fuente de m8-usuarios en la consola.*

![Código de la función m8-pedidos](imagenes/06-lambda-pedidos-codigo.png)
*Figura 7: Código fuente de m8-pedidos en la consola.*

Se probaron ambas funciones desde la pestaña **Prueba** de la consola de Lambda, usando eventos de prueba con la estructura de un evento HTTP de API Gateway (`requestContext.http.method`, `body`, etc.).

![Resultado de la prueba de m8-usuarios en consola](imagenes/07-lambda-test-usuarios.png)
*Figura 8: Resultado de la ejecución de prueba de m8-usuarios (statusCode 200 y el JSON de usuarios).*

![Resultado de la prueba de m8-pedidos en consola](imagenes/08-lambda-test-pedidos.png)
*Figura 9: Resultado de la ejecución de prueba de m8-pedidos, insertando un pedido en DynamoDB.*

### Lección 3 — API Gateway

**Objetivo:** exponer las funciones como endpoints.

Se creó un **HTTP API** (`m8-api`) con integración proxy Lambda y las siguientes rutas:

| Método | Ruta | Integración |
|---|---|---|
| GET | /usuarios | m8-usuarios |
| GET | /pedidos | m8-pedidos |
| POST | /pedidos | m8-pedidos |

La API se desplegó en el stage `$default` (auto-deploy), con CORS habilitado (`*`) para permitir que el frontend alojado en S3 pueda invocarla desde otro origen.

![Rutas del API Gateway](imagenes/09-apigateway-rutas.png)
*Figura 10: Consola de API Gateway → m8-api → Rutas, con las 3 integraciones.*

![Prueba de GET /usuarios en el navegador](imagenes/10-apigateway-test-get-usuarios.png)
*Figura 11: Respuesta de `GET /usuarios` abierta directamente en el navegador.*

![Prueba de POST /pedidos en Postman](imagenes/11-apigateway-test-post-pedidos.png)
*Figura 12: Petición POST /pedidos en Postman, con el pedido creado como respuesta (201).*

**URL de la API:** `[pega aquí tu URL, ej: https://xxxxxxx.execute-api.us-east-1.amazonaws.com]`

### Lección 4 — Persistencia con DynamoDB

**Objetivo:** guardar información sin servidor.

Se creó la tabla `Pedidos` con clave de partición `orderId` (String) y modo de facturación bajo demanda (`PAY_PER_REQUEST`), evitando administrar capacidad de lectura/escritura.

![Tabla Pedidos en DynamoDB](imagenes/12-dynamodb-tabla.png)
*Figura 13: Consola de DynamoDB mostrando la tabla Pedidos, su clave de partición y modo de facturación.*

![Ítems insertados en la tabla](imagenes/13-dynamodb-items.png)
*Figura 14: Explorador de ítems de la tabla Pedidos con [cantidad] pedidos creados durante las pruebas.*

### Lección 5 — Monitoreo y documentación

**Objetivo:** evidenciar y documentar la solución.

Cada invocación de las Lambdas queda registrada en su propio log group de CloudWatch (`/aws/lambda/m8-usuarios` y `/aws/lambda/m8-pedidos`), incluyendo los eventos personalizados que cada función imprime (`listar_usuarios`, `pedido_creado`, etc.) además de los logs estándar de inicio/fin/duración de cada invocación.

![Grupos de logs en CloudWatch](imagenes/14-cloudwatch-log-groups.png)
*Figura 15: CloudWatch → Log groups, filtrado por /aws/lambda/m8-.*

![Detalle de un log stream de m8-pedidos](imagenes/15-cloudwatch-log-stream.png)
*Figura 16: Log stream de una invocación de m8-pedidos, mostrando el evento pedido_creado y el orderId generado.*

---

## 5. ¿Qué se validó?

- [x] Aplicación serverless con funciones Lambda expuestas en API Gateway.
- [x] Sitio estático funcionando en S3, conectado a la API.
- [x] DynamoDB con ítems insertados desde Lambda.
- [x] Logs accesibles en CloudWatch para ambas funciones.
- [x] Documentación con capturas y diagrama.

Pruebas realizadas:

```text
GET  /usuarios            → 200, lista de usuarios de ejemplo
POST /pedidos (x N)       → 201, cada uno con un orderId distinto
GET  /pedidos              → 200, lista de los pedidos creados
```

---

## 7. Conclusiones y aprendizajes

[Completa esta sección con tu propia reflexión. Algunas ideas de partida:]

- Con un modelo 100 % serverless (Lambda + API Gateway + DynamoDB + S3) no fue necesario administrar ni un solo servidor: el costo y el escalamiento quedan a cargo de AWS según el uso real.
- [Qué fue lo más fácil / lo más difícil de la actividad]
- [Qué aprendiste sobre el modelo de pago por uso vs. tener servidores encendidos 24/7]
- [Qué harías distinto si repitieras el proyecto — por ejemplo, agregar autenticación, validaciones adicionales, alarmas en CloudWatch, etc.]

---

## 8. Portafolio

Proyecto registrado como **"Serverless Inteligente en AWS"**, destacando:

- Uso de Lambda + API Gateway para la lógica de negocio.
- S3 como hosting estático sin servidor, conectado a la API.
- Persistencia con DynamoDB.
- Monitoreo con CloudWatch.
- Documentación con capturas y diagrama.

**Enlace al repositorio / publicación en LinkedIn:** [opcional]