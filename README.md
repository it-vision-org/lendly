# Lendly

A personal money-tracking app for people who lend and borrow money from friends,
family, or other contacts. Lendly keeps track of who owes you, who you owe, how
much, when, why, and the full repayment history for every transaction.

## Tech stack

- **Flutter** (Riverpod, go_router, Dio) — mobile app
- **Spring Boot** (Java 25, Spring Security + JWT, Spring Data JPA, Flyway) — REST API
- **PostgreSQL** (Neon) — database

## Project structure

```
backend/    Spring Boot REST API (com.lendly)
mobile/     Flutter app
compose.yaml  Local Postgres + Adminer for development
```

## Environment setup

Copy `.env.example` to `.env` and fill in the values. `DATABASE_URL`,
`DATABASE_USERNAME` and `DATABASE_PASSWORD` should point at your Postgres
instance (Neon or local).

To run a local Postgres instead of Neon:

```bash
docker compose up -d
```

## Backend

```bash
cd backend
set -a && source ../.env && set +a
./gradlew bootRun
```

The API listens on `http://localhost:8080/api`. API docs are available at
`http://localhost:8080/swagger-ui.html` while running.

If the app fails to start with `UnknownHostException` connecting to Neon, but
`ping`/`nslookup` show the hostname resolving to an IPv6 address that's
unreachable on your network, your machine has a working IPv4 path but a
broken IPv6 one. `./gradlew bootRun` already forces IPv4 for this reason; if
you instead run the built jar directly, add the same flag:

```bash
java -Djava.net.preferIPv4Stack=true -jar build/libs/lendly-api-*.jar
```

Run tests (requires Docker for Testcontainers):

```bash
./gradlew test
```

## Flutter app

```bash
cd mobile
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080/api
```

`10.0.2.2` is the Android emulator's alias for the host machine's `localhost`;
use `http://localhost:8080/api` on iOS simulator or `flutter run -d chrome`.

Run tests and analysis:

```bash
flutter analyze
flutter test
```
