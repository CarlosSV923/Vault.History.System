# Vault History System documentation

The monorepo runs the complete local backend through Docker Compose: User, Jobs, History, Notification, PostgreSQL, MongoDB and Apache Kafka.

- Interactive diagram: [Backend architecture](architecture/backend-architecture.html)
- Editable diagram source: [backend-architecture.json](architecture/backend-architecture.json)
- Start: `docker compose up --build -d`
- Status: `docker compose ps`
- Logs: `docker compose logs --tail 100 user history jobs notification kafka-init`

The Compose environment creates `notify-history-topic`, `notify-outbox-topic`, `update-users-topic` and `update-outbox-topic`. Google configuration values are placeholders until a real story or email flow is tested. See the [GitHub Project](https://github.com/users/CarlosSV923/projects/3) for planning.

PostgreSQL also holds Notification checkpoints, while User continues to apply the EF Core migration that creates the shared table. This lets history-message retries reuse a generated story and a confirmed email stage before republishing the Kafka result.
