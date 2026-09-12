# Vault History System

Vault History System is a local portfolio workspace for the Vault History backend. This repository owns the Docker Compose topology, shared Dockerfiles, configuration examples, and architecture documentation. It is designed for local execution, not production deployment.

The service repositories are **not** Git submodules and this repository has no `services/` directory. Docker Compose builds the backend from sibling checkouts with the exact names shown below.

## Architecture

![Vault History backend architecture showing the Frontend, User, History, Jobs, Notification, PostgreSQL, MongoDB, Kafka, Gemini, and Gmail relationships.](https://raw.githubusercontent.com/CarlosSV923/Vault.History.System/develop/docs/architecture/backend-architecture.png)

The image uses GitHub's raw-content URL so that it renders reliably in the repository README. Explore the [interactive diagram](docs/architecture/backend-architecture.html) or inspect its [editable JSON source](docs/architecture/backend-architecture.json) for labels, relationships, and focused views.

The backend topology is:

1. The **Frontend** calls **User** over HTTPS for accounts and authentication, and calls History through server-side routes.
2. **User** stores account and outbox data in **PostgreSQL**. **History** stores generated stories in **MongoDB** and asks **Google Gemini** to generate a story only when requested.
3. **Jobs** publishes notification work to **Apache Kafka**. **Notification** consumes that work, obtains subscription stories from History when needed, sends email through the **Gmail API**, and publishes correlated outcomes.

| Component | Responsibility | Primary integration |
| --- | --- | --- |
| Frontend | Next.js visitor, account, library, and subscription experience | Server-side routes to User and History |
| User | Accounts, authentication, preferences, and transactional outbox | PostgreSQL and Kafka-oriented outbox processing |
| History | Story generation and persistence | MongoDB and Google Gemini |
| Jobs | Scheduled selection, outbox processing, and result coordination | PostgreSQL and Apache Kafka |
| Notification | Template rendering and email delivery | Apache Kafka, History, PostgreSQL checkpoints, and Gmail |
| PostgreSQL | User, outbox, and notification-checkpoint data | User owns the EF Core migration for the shared checkpoint table |
| MongoDB | Generated-story data | History |
| Apache Kafka | Asynchronous notification contracts | Jobs and Notification |

The Frontend is part of the portfolio workspace, but it is not started by the backend Compose file.

## Repositories

Each project keeps its own source code, tests, and Git history. Clone all of them into one parent directory with the exact names below.

| Project | Repository | Local directory |
| --- | --- | --- |
| Orchestration | [CarlosSV923/Vault.History.System](https://github.com/CarlosSV923/Vault.History.System) | `Vault.History.System` |
| Frontend | [CarlosSV923/VaultHistory.Frontend.Museum](https://github.com/CarlosSV923/VaultHistory.Frontend.Museum) | `VaultHistory.Frontend.Museum` |
| User | [CarlosSV923/VaultHistory.Microservice.User](https://github.com/CarlosSV923/VaultHistory.Microservice.User) | `VaultHistory.Microservice.User` |
| Jobs | [CarlosSV923/VaultHistory.Microservice.Jobs](https://github.com/CarlosSV923/VaultHistory.Microservice.Jobs) | `VaultHistory.Microservice.Jobs` |
| History | [CarlosSV923/VaultHistory.Microservice.History](https://github.com/CarlosSV923/VaultHistory.Microservice.History) | `VaultHistory.Microservice.History` |
| Notification | [CarlosSV923/VaultHistory.Microservice.Notification](https://github.com/CarlosSV923/VaultHistory.Microservice.Notification) | `VaultHistory.Microservice.Notification` |

Work is planned in the [Portfolio Vault History System GitHub Project](https://github.com/users/CarlosSV923/projects/3).

## Required local workspace layout

All repositories must be siblings in the same parent directory. This is required because the Compose build contexts use the relative paths `../VaultHistory.Microservice.*`.

```text
vault-history-local/
├── Vault.History.System/
├── VaultHistory.Frontend.Museum/
├── VaultHistory.Microservice.User/
├── VaultHistory.Microservice.Jobs/
├── VaultHistory.Microservice.History/
└── VaultHistory.Microservice.Notification/
```

Do not place the service repositories inside `Vault.History.System`, do not rename their directories, and do not add them as Git submodules. A different layout makes `docker compose up --build` fail because Docker cannot resolve its build contexts.

### Clone the complete local workspace

From Git Bash, macOS, or Linux, run:

```bash
mkdir vault-history-local
cd vault-history-local

git clone https://github.com/CarlosSV923/Vault.History.System.git Vault.History.System
git clone --branch develop https://github.com/CarlosSV923/VaultHistory.Frontend.Museum.git VaultHistory.Frontend.Museum
git clone --branch develop https://github.com/CarlosSV923/VaultHistory.Microservice.User.git VaultHistory.Microservice.User
git clone --branch develop https://github.com/CarlosSV923/VaultHistory.Microservice.Jobs.git VaultHistory.Microservice.Jobs
git clone --branch develop https://github.com/CarlosSV923/VaultHistory.Microservice.History.git VaultHistory.Microservice.History
git clone --branch develop https://github.com/CarlosSV923/VaultHistory.Microservice.Notification.git VaultHistory.Microservice.Notification

cd Vault.History.System
```

For PowerShell:

```powershell
New-Item -ItemType Directory -Force vault-history-local | Out-Null
Set-Location vault-history-local

git clone https://github.com/CarlosSV923/Vault.History.System.git Vault.History.System
git clone --branch develop https://github.com/CarlosSV923/VaultHistory.Frontend.Museum.git VaultHistory.Frontend.Museum
git clone --branch develop https://github.com/CarlosSV923/VaultHistory.Microservice.User.git VaultHistory.Microservice.User
git clone --branch develop https://github.com/CarlosSV923/VaultHistory.Microservice.Jobs.git VaultHistory.Microservice.Jobs
git clone --branch develop https://github.com/CarlosSV923/VaultHistory.Microservice.History.git VaultHistory.Microservice.History
git clone --branch develop https://github.com/CarlosSV923/VaultHistory.Microservice.Notification.git VaultHistory.Microservice.Notification

Set-Location Vault.History.System
```

The repositories are intentionally cloned independently. Before running Compose, use `git status` in each one if you need to confirm the local sources match the revisions you intend to demonstrate.

## Run the backend locally

### Prerequisites

- Git.
- Docker Desktop with Docker Compose.
- Approximately 6 GB of available memory for the backend services and infrastructure.

Create local configuration from the example:

```bash
cp .env.example .env
```

Then build and start the complete backend from `Vault.History.System`:

```bash
docker compose up --build -d
```

Check status and logs:

```bash
docker compose ps
docker compose logs --tail 100 user history jobs notification kafka-init
```

Stop the environment:

```bash
docker compose down
```

Do not run `docker compose down --volumes` unless you intentionally want to remove local PostgreSQL, MongoDB, and Kafka data.

## Compose topology and configuration

`compose.yaml` builds User, History, Jobs, and Notification from their sibling repositories with the Dockerfiles stored in this repository. It also starts PostgreSQL, MongoDB, Kafka, and the idempotent `kafka-init` topic initializer. Docker service names provide internal DNS; workers use `kafka:9092`, and Notification reaches History at `http://history:3000`.

The example configuration declares local-only values for PostgreSQL, MongoDB, JWT signing, the internal History token, and anonymous-generation settings. `AUTH_TOKEN_FORNT` is the existing History configuration key; `ANONYMOUS_DAILY_LIMIT` defaults to `3`.

Google settings are placeholders so containers can start before a real story or email is processed. Set `GOOGLE_API_KEY` only for Gemini-backed generation, and set the Gmail client, sender, and refresh-token variables only for real delivery. Keep `.env` out of Git and never publish `docker compose config` output created with real secrets, because Compose expands them.

## Messaging and state

`kafka-init` creates these topics before Jobs and Notification start:

- `notify-history-topic`
- `notify-outbox-topic`
- `update-users-topic`
- `update-outbox-topic`

For registration, User records a `CreateUserEvent` in its outbox, Jobs publishes correlated work to `notify-outbox-topic`, and Notification publishes the matching `{ id: outboxId, data: ... }` outcome to `update-outbox-topic` only after delivery processing. The existing legacy `UserId.Value` payload remains compatible. Sign-in notifications follow the same correlated outbox path with their specific template.

PostgreSQL notification checkpoints allow History-message retries to reuse a generated story and a confirmed-email stage before a Kafka result is republished. The documented design is at-least-once around external email delivery; it does not claim an end-to-end exactly-once guarantee.

## Local ports and diagnostics

| Service | Address |
| --- | --- |
| User API | `http://localhost:5000` |
| User health check | `http://localhost:5000/health` |
| History API | `http://localhost:3001` |
| Kafka | `localhost:9094` |
| PostgreSQL | `localhost:5432` |
| MongoDB | `localhost:27017` |

Jobs and Notification are workers and do not expose HTTP ports. If a worker restarts, inspect Kafka and the resolved configuration first:

```bash
docker compose logs kafka kafka-init jobs notification
docker compose config
```

If User fails while applying migrations, inspect PostgreSQL before restarting User and Jobs:

```bash
docker compose logs postgres user
docker compose restart user jobs
```

## Repository layout

```text
Vault.History.System/
├── compose.yaml
├── docker/
│   ├── user.Dockerfile
│   ├── jobs.Dockerfile
│   ├── history.Dockerfile
│   └── notification.Dockerfile
├── docs/
│   └── architecture/
│       ├── backend-architecture.png
│       ├── backend-architecture.html
│       └── backend-architecture.json
└── .env.example
```

There is no `services/` directory and no Git submodule configuration. Source code remains in the sibling repositories listed above.

## Verification and scope

Run `docker compose config --quiet` to validate the Compose configuration before a build. The Docker Compose environment is intentionally for local portfolio demonstrations; it is not a production deployment guide.
