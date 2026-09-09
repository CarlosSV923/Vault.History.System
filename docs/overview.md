# Vault History System documentation

The monorepo runs the complete local backend through Docker Compose: User, Jobs, History, Notification, PostgreSQL, MongoDB and Apache Kafka.

- Interactive diagram: [Backend architecture](architecture/backend-architecture.html)
- Editable diagram source: [backend-architecture.json](architecture/backend-architecture.json)
- Start: `docker compose up --build -d`
- Status: `docker compose ps`
- Logs: `docker compose logs --tail 100 user history jobs notification kafka-init`

The Compose environment creates `notify-history-topic`, `notify-outbox-topic`, `update-users-topic` and `update-outbox-topic`. Google configuration values are placeholders until a real story or email flow is tested. See the [GitHub Project](https://github.com/users/CarlosSV923/projects/3) for planning.

PostgreSQL also holds Notification checkpoints, while User continues to apply the EF Core migration that creates the shared table. This lets history-message retries reuse a generated story and a confirmed email stage before republishing the Kafka result.

Registration follows the outbox flow as well: User stores a pending `CreateUserEvent` with an explicit `userId`, Jobs publishes the correlated message to `notify-outbox-topic`, and Notification delivers the welcome template before publishing the matching `{ id: outboxId, data: ... }` result to `update-outbox-topic`.

The repository pins every service to an explicit submodule commit. Verify a checkout with `git submodule update --init --recursive`, `git submodule status`, `git diff --submodule=log`, and `docker compose config -q` before rebuilding the full stack.
