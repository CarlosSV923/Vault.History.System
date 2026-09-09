# Vault History System

English documentation: [docs/overview.md](docs/overview.md).

Repositorio de orquestación para levantar el sistema completo de Vault History con Docker Compose. Los microservicios se conservan en repositorios independientes y se incluyen aquí como submódulos fijados a revisiones conocidas.

## Repositorios

| Componente | Repositorio | Función |
| --- | --- | --- |
| User | [VaultHistory.Microservice.User](https://github.com/CarlosSV923/VaultHistory.Microservice.User) | Usuarios, autenticación, PostgreSQL y outbox. |
| Jobs | [VaultHistory.Microservice.Jobs](https://github.com/CarlosSV923/VaultHistory.Microservice.Jobs) | Tareas programadas y coordinación mediante Kafka. |
| History | [VaultHistory.Microservice.History](https://github.com/CarlosSV923/VaultHistory.Microservice.History) | Generación y persistencia de historias. |
| Notification | [VaultHistory.Microservice.Notification](https://github.com/CarlosSV923/VaultHistory.Microservice.Notification) | Consumo Kafka, plantillas y envío de correo. |

Las historias de usuario y su estado se administran en [Portfolio Vault History System](https://github.com/users/CarlosSV923/projects/3). La HU-12 que introdujo este repositorio se encuentra en [Vault.History.System#1](https://github.com/CarlosSV923/Vault.History.System/issues/1).

## Requisitos

- Git con soporte para submódulos.
- Docker Desktop con Docker Compose.
- Aproximadamente 6 GB de memoria disponible para construir y ejecutar el entorno.

## Clonar

```bash
git clone --recurse-submodules https://github.com/CarlosSV923/Vault.History.System.git
cd Vault.History.System
```

Si el repositorio ya fue clonado:

```bash
git submodule update --init --recursive
```

Los submódulos siguen la rama `develop`, pero cada commit del repositorio de orquestación fija una revisión concreta para que el entorno sea reproducible.

## Flujo de bienvenida

Al registrarse un usuario, User guarda un `CreateUserEvent` pendiente en el outbox con el payload explícito `{ "userId": "..." }`. Jobs conserva el `outboxId`, obtiene el perfil y publica la solicitud en `notify-outbox-topic`. Notification reutiliza la plantilla de bienvenida y publica el resultado correlacionado como `{ id: outboxId, data: ... }` en `update-outbox-topic`; solo entonces Jobs actualiza el estado final del outbox.

Los registros de alta pendientes con el formato anterior (`UserId.Value`) siguen siendo compatibles. Los ya procesados no se vuelven a enviar. Los inicios de sesión mantienen el mismo recorrido y su plantilla específica.

## Verificar revisiones fijadas

Antes de construir el conjunto, inicializa exactamente los commits referenciados por este repositorio y comprueba que no haya cambios locales en los submódulos:

```bash
git submodule update --init --recursive
git submodule status
git diff --submodule=log
docker compose config -q
```

Para actualizar una revisión de servicio en el futuro, cambia el submódulo a un commit ya validado, ejecuta las pruebas del servicio y del Compose, y confirma el puntero actualizado junto con la salida de `git diff --submodule=log`.

## Configuración

El Compose incluye valores locales para PostgreSQL, MongoDB, JWT, el token interno entre Notification e History y el token fijo del frontend para la generación anónima. `AUTH_TOKEN_FORNT` protege esa ruta y `ANONYMOUS_DAILY_LIMIT` establece su cupo diario por IP declarada, con valor local predeterminado de `3`. Son exclusivos para desarrollo y no deben reutilizarse en un despliegue público.

Para arrancar los contenedores no hacen falta credenciales reales de Google. Los valores placeholder permiten construir e iniciar History y Notification; Gemini y Gmail solo se invocan cuando se procesa una notificación real.

Para probar esos proveedores, copia `.env.example` como `.env` y reemplaza los valores correspondientes:

```bash
cp .env.example .env
```

Docker Compose carga `.env` automáticamente. El archivo está ignorado por Git.

## Ejecutar

Construir y levantar todo el sistema:

```bash
docker compose up --build -d
```

Consultar el estado:

```bash
docker compose ps
docker compose logs --tail 100 user history jobs notification kafka-init
```

Servicios accesibles desde el host:

- User API: `http://localhost:5000`
- Health de User: `http://localhost:5000/health`
- History API: `http://localhost:3001`
- Kafka: `localhost:9094`
- PostgreSQL: `localhost:5432`
- MongoDB: `localhost:27017`

Jobs y Notification son workers y no publican puertos HTTP. Dentro de la red Docker, Notification usa `http://history:3000` y los workers usan `kafka:9092`.

Detener el entorno:

```bash
docker compose down
```

Eliminar también los datos locales:

```bash
docker compose down --volumes
```

## Topics Kafka

`kafka-init` crea de forma idempotente los siguientes topics antes de iniciar Jobs y Notification:

- `notify-history-topic`
- `notify-outbox-topic`
- `update-users-topic`
- `update-outbox-topic`

## Estructura

```text
Vault.History.System/
├── compose.yaml
├── docker/
│   ├── user.Dockerfile
│   ├── jobs.Dockerfile
│   ├── history.Dockerfile
│   └── notification.Dockerfile
└── services/
    ├── user/
    ├── jobs/
    ├── history/
    └── notification/
```

Los Dockerfiles y la topología conjunta pertenecen a este repositorio. Cada repositorio de microservicio conserva su compilación, pruebas y documentación específica.

## Diagnóstico

Si un worker reinicia, revisa primero los logs de Kafka y la configuración resuelta:

```bash
docker compose logs kafka kafka-init jobs notification
docker compose config
```

Si User falla durante migraciones, verifica PostgreSQL y luego reinicia User y Jobs:

```bash
docker compose logs postgres user
docker compose restart user jobs
```

No publiques la salida de `docker compose config` cuando uses un `.env` con credenciales reales, porque los secretos aparecerán expandidos.
Docker orchestration for the Vault History portfolio system
