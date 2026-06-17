# cl-logistica-order-status-changes

## Descripcion

Servicio backend en NestJS que recibe notificaciones HTTP de cambios de estado de las Órdenes de Compra de Cencosud  y las reenvia a una cola SQS de AWS.


Actualmente el servicio:

- expone endpoints HTTP para recibir notificaciones y consultar salud
- publica el payload recibido en SQS


## Flujo funcional

1. Se recibe actualizaciones de estado de Órdenes de Compra en el endpoint POST /notification/state-change.
2. El servicio recibe el body y lo reenvia a SQS.
3. La respuesta confirma si el mensaje fue publicado correctamente.
4. Las trazas y metricas del proceso se exportan via OTLP al Collector y se muestran en Dynatrace.

## Endpoints

### POST /notification/state-change

Recibe una notificacion y la publica en SQS.

Ejemplo de request:

json
{
  "orderId": "123",
  "status": "SHIPPED",
  "timestamp": "2026-06-16T12:00:00.000Z"
}


Ejemplo de response:

json
{
  "messageId": "7c1e6e8d-0d3f-4b37-8f8f-2e4b1b6d7e99",
  "success": true,
  "timestamp": "2026-06-16T12:00:00.000Z"
}


### GET /health

Healthcheck basico del servicio.

### GET /health/docs

Healthcheck del recurso externo configurado en HEALTH_CHECK.

### GET /api-docs

Documentacion Swagger del servicio.

URL de staging:

text
https://cl-logistica-order-status-changes.aws-test.paris.cl/api-docs


## Stack principal

- Node.js 22
- NestJS 11
- AWS SDK v3 para SQS
- nestjs-pino
- Joi para validacion de variables de entorno
- Swagger
- Jest
- OpenTelemetry auto-instrumentation para Node.js

## Variables de entorno

### Requeridas para la aplicacion

Crear un archivo .env local con al menos:

dotenv
PORT=
HEALTH_CHECK=
AWS_REGION=
SQS_QUEUE_URL=
SQS_NAME=
NODE_ENV=



## Desarrollo local

El proyecto usa pnpm para desarrollo local.

Instalacion:

bash
pnpm install


Levantar en desarrollo:

bash
pnpm run start:dev


Ejecutar tests:

bash
pnpm test


Build:

bash
pnpm run build


## Estructura del proyecto

text
src/
  common/
  config/
  modules/
    health/
    notification-queue/
      dto/
      notification/
      sqs-publisher/


Descripcion rapida:

- common: decoradores y utilidades compartidas
- config: carga y validacion de variables de entorno
- modules/health: endpoints de salud
- modules/notification-queue/notification: controller HTTP
- modules/notification-queue/sqs-publisher: publicacion en SQS

## Arquitectura

plantuml
@startuml
left to right direction
skinparam backgroundColor white
skinparam shadowing false
skinparam linetype ortho
skinparam defaultTextAlignment center
skinparam ArrowColor #374151
skinparam ArrowThickness 1.5
skinparam nodesep 50
hide stereotype
skinparam rectangle {
  BackgroundColor white
  BorderColor #D1D5DB
  RoundCorner 8
}
skinparam rectangle<<spacer>> {
  BackgroundColor white
  BorderColor white
  FontColor white
}

!include <logos/nestjs.puml>
!include <awslib/AWSCommon.puml>
!include <awslib/ApplicationIntegration/SimpleQueueService.puml>
!include <awslib/Compute/Lambda.puml>
!include <awslib/Storage/SimpleStorageService.puml>

rectangle "<size:22><b>Beetrack</b></size>" as beetrack
rectangle " " as webhook_spacer <<spacer>>

rectangle "<color:#E0234E><$nestjs></color>\n<color:#111827>cl-logistica-status-orders</color>" as status_orders
rectangle "<color:#E7157B><$SimpleQueueService></color>\n<color:#111827>cl-logistica-status-change-orders</color>" as change_orders
rectangle "<color:#ED7100><$Lambda></color>\n<color:#111827>cl-logistica-save-status-orders</color>" as save_status_orders
rectangle "<color:#7AA116><$SimpleStorageService></color>\n<color:#111827>status-change-notifications</color>" as status_change_notifications

beetrack -[hidden]-> webhook_spacer
webhook_spacer -[hidden]-> status_orders
beetrack --> status_orders : \nWebhook
status_orders --> change_orders
change_orders --> save_status_orders
save_status_orders --> status_change_notifications
@enduml


## Arquitectura Alternativa Con Colores Oficiales


plantuml
@startuml
left to right direction
skinparam backgroundColor white
skinparam shadowing false
skinparam linetype ortho
skinparam defaultTextAlignment center
skinparam ArrowColor #374151
skinparam ArrowThickness 1.5
skinparam nodesep 50
hide stereotype
skinparam rectangle {
  BackgroundColor white
  BorderColor #D1D5DB
  RoundCorner 8
}
skinparam rectangle<<spacer>> {
  BackgroundColor white
  BorderColor white
  FontColor white
}

!include <logos/nestjs.puml>
!include <awslib/AWSCommon.puml>
!include <awslib/ApplicationIntegration/SimpleQueueService.puml>
!include <awslib/Compute/Lambda.puml>
!include <awslib/Storage/SimpleStorageService.puml>

rectangle "<size:22><b>Beetrack</b></size>" as beetrack_alt
rectangle " " as webhook_spacer_alt <<spacer>>
rectangle "cl-logistica-status-orders\n<color:#E0234E><$nestjs></color>" as status_orders_alt

SimpleQueueService(change_orders_alt, "cl-logistica-status-change-orders", "", "")
Lambda(save_status_orders_alt, "cl-logistica-save-status-orders", "", "")
SimpleStorageService(status_change_notifications_alt, "status-change-notifications", "", "")

beetrack_alt -[hidden]-> webhook_spacer_alt
webhook_spacer_alt -[hidden]-> status_orders_alt
beetrack_alt --> status_orders_alt : \nWebhook
status_orders_alt --> change_orders_alt
change_orders_alt --> save_status_orders_alt
save_status_orders_alt --> status_change_notifications_alt
@enduml


## Prueba de compatibilidad de PlantUML en GitLab

GitLab no muestra directamente la version exacta de PlantUML en el README.

En GitLab.com PlantUML ya viene integrado, y en GitLab Self-Managed la compatibilidad depende del servidor PlantUML configurado por la instancia.

Este bloque no imprime la version, pero sirve para validar si GitLab soporta las librerias e iconos usados en este proyecto:

plantuml
!include <tupadr3/common>
!include <tupadr3/font-awesome/server>
!include <awslib/AWSCommon.puml>
!include <awslib/Compute/Lambda.puml>
!include <awslib/Storage/SimpleStorageService.puml>

rectangle "<$server>\nServicio interno" as service
Lambda(fn, "Lambda", "", "")
SimpleStorageService(bucket, "S3 bucket", "", "")

service --> fn
fn --> bucket


## Muestrario de iconos PlantUML

Este bloque sirve para probar la variedad de iconos disponible en la instancia de GitLab usando distintas librerias de PlantUML.

Si renderiza bien, entonces tienes soporte util para iconos de AWS, Font Awesome, Devicons y Office/Tupadr3 sin subir imagenes manuales al repositorio.

plantuml
left to right direction
skinparam backgroundColor white
skinparam shadowing false
skinparam defaultTextAlignment center
hide stereotype

!include <tupadr3/common>
!include <tupadr3/font-awesome/server>
!include <tupadr3/font-awesome/database>
!include <tupadr3/devicons/mysql>
!include <office/Servers/application_server>
!include <office/Servers/database_server>
!include <logos/nestjs.puml>
!include <awslib/AWSCommon.puml>
!include <awslib/Compute/Lambda.puml>
!include <awslib/ApplicationIntegration/SimpleQueueService.puml>
!include <awslib/ApplicationIntegration/SimpleNotificationService.puml>
!include <awslib/Database/DynamoDB.puml>
!include <awslib/Storage/SimpleStorageService.puml>

FA_SERVER(fa_server, "Font Awesome server") #E5F3FF
FA_DATABASE(fa_database, "Font Awesome database") #E8F5E9
DEV_MYSQL(dev_mysql, "Devicons MySQL", "database", #E3F2FD)
OFF_APPLICATION_SERVER(office_app, "Office app server")
OFF_DATABASE_SERVER(office_db, "Office database server")
rectangle "<color:#E0234E><$nestjs></color>\nNestJS" as nestjs_logo
Lambda(aws_lambda, "AWS Lambda", "", "")
SimpleQueueService(aws_sqs, "Amazon SQS", "", "")
SimpleNotificationService(aws_sns, "Amazon SNS", "", "")
DynamoDB(aws_dynamodb, "Amazon DynamoDB", "", "")
SimpleStorageService(aws_s3, "Amazon S3", "", "")