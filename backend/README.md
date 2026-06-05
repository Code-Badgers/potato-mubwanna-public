# Potato Mubwanna Backend

Spring Boot backend for the Potato Mubwanna location-based stamp rally service.

## Stack

- Java 21
- Spring Boot 3.5+
- Spring Security
- JWT
- Spring Data JPA
- QueryDSL
- PostgreSQL / PostGIS
- Redis
- Springdoc OpenAPI

## Commands

```bash
./gradlew test
./gradlew build
```

## Architecture

The backend follows a modular monolith structure under `com.gamjamubwatna`.
Each domain is expected to use `api`, `application`, `domain`, and
`infrastructure` layers.

