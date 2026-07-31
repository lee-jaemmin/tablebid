# CODEX_CONTEXT.md

## Product

This app is a real-time table management service for clubs/stores.

Store staff use it to manage table status, reservations, customer/table information, purchases, and operational flow.

The service is already used in real stores, so existing production behavior must be preserved unless a change is explicitly requested.

## Business situation

* Solo founder project.
* Production users: real stores are actively using the service.
* Priority: stability, quick bug fixes, and practical feature shipping.
* Development speed matters, but not at the cost of breaking existing store operations.
* Avoid large refactors or architecture rewrites unless explicitly requested or clearly necessary to fix a real problem.

## Tech stack

### Client

* Flutter
* Dart
* Firebase Auth
* Firebase Cloud Messaging (FCM)
* Existing Firebase functionality may still remain in parts of the project

### Backend

* FastAPI
* Python
* SQLAlchemy
* Pydantic
* REST API
* WebSocket for real-time updates where implemented

### Database

* SQLite may be used for local development/testing
* PostgreSQL / Supabase may be used for deployed environments

Do not assume the database or deployment environment. Check the existing code/configuration relevant to the task before changing database behavior.

### Deployment / development

* Railway may be used for FastAPI deployment
* VS Code
* Codex CLI
* Codex VS Code extension

## Architecture context

The Flutter client and FastAPI backend are separate layers connected through API contracts.

Typical flow:

```text
Flutter UI
    ↓
Flutter API / service layer
    ↓
FastAPI router
    ↓
CRUD / service logic
    ↓
SQLAlchemy
    ↓
Database
```

Real-time table updates may additionally use:

```text
FastAPI
    ↓
WebSocket
    ↓
Flutter client
```

Firebase may still exist alongside this architecture for authentication, notifications, or legacy functionality.

Do not remove or replace Firebase functionality merely because a FastAPI equivalent could be implemented.

## Engineering priorities

1. Do not break existing store operations.
2. Preserve existing behavior unless a change is explicitly requested.
3. Keep Flutter ↔ FastAPI API contracts compatible.
4. Keep changes small and reviewable.
5. Keep UI responsive.
6. Avoid unnecessary API requests and database queries.
7. Preserve real-time table synchronization.
8. Prefer incremental improvements over architecture rewrites.
9. Avoid unnecessary dependencies or infrastructure changes.
10. Treat production data carefully.

## Flutter considerations

When working on Flutter code, pay particular attention to:

* null safety
* async loading states
* navigation flow
* unnecessary widget rebuilds
* API request timing
* WebSocket-driven updates
* login/session initialization
* error handling
* production behavior on real devices

Do not change state-management patterns simply because another pattern would be cleaner.

Follow the pattern already used in the affected code.

## FastAPI considerations

When working on FastAPI code, pay particular attention to:

* request/response schemas
* endpoint compatibility with Flutter
* Pydantic validation
* SQLAlchemy session handling
* commit/refresh behavior
* relationships and nullable fields
* database query count
* authentication/authorization
* WebSocket connection behavior
* error status codes
* production database compatibility

Do not change endpoint contracts without checking the corresponding Flutter code.

## Flutter ↔ FastAPI API contract

The API contract is a major risk area.

Changes to any of the following may break the app:

* endpoint URL
* HTTP method
* request body
* query parameters
* JSON field names
* response structure
* nullable/non-nullable fields
* list/object structure
* date/time representation
* enum/string values
* HTTP status codes

When modifying an API-related feature, inspect both the Flutter and FastAPI sides when necessary.

Prefer backward-compatible changes whenever possible.

## Firebase context

Firebase is not necessarily the primary application database anymore, but some Firebase functionality may intentionally remain.

Potential usage includes:

* Firebase Auth
* FCM
* existing Firestore functionality
* legacy Firebase-dependent code

Do not assume Firebase code is obsolete.

Before removing or modifying Firebase-related code, verify how it is currently used.

Never expose or commit:

* Firebase service-account JSON
* API secrets
* private keys
* environment variables containing credentials

## Common task types

* Fix Flutter runtime errors
* Fix FastAPI errors
* Fix API request/response mismatches
* Fix database data inconsistencies
* Add a page
* Add a feature to an existing page
* Add or modify an API endpoint
* Add backend logic required by an existing UI
* Improve UI flow
* Fix WebSocket synchronization
* Fix loading/performance issues
* Investigate production-like bugs
* Refactor only around code directly affected by the requested task

## Real-time table management context

Table state is core production functionality.

Changes involving table management should be treated carefully.

Relevant behavior may include:

* table availability/status
* customer entry
* table movement
* table grouping
* table exit
* purchases
* reservations
* timers
* user/staff information
* real-time synchronization

Do not change table state transitions or synchronization behavior without understanding the existing flow.

A change that appears local in Flutter may affect:

```text
Flutter
→ FastAPI
→ Database
→ WebSocket broadcast
→ Other connected clients
```

Check the relevant path before making behavior changes.

## Risk areas

High-risk areas include:

* Flutter ↔ FastAPI API contracts
* SQLAlchemy model/schema changes
* database migrations
* nullable field changes
* authentication-dependent logic
* Firebase Auth
* FCM token handling
* WebSocket connections
* WebSocket broadcasts
* table status synchronization
* table move / entry / exit logic
* concurrent updates
* date/time and timezone handling
* company/store-specific data isolation
* user roles and permissions
* production database changes
* secrets and service-account credentials
* deployment configuration

Changes in these areas should be narrow and intentional.

## Date/time handling

Be careful with timezone differences between:

* Flutter device time
* FastAPI server time
* database timestamps
* deployed server timezone

Do not blindly add or subtract fixed timezone offsets unless the existing architecture explicitly requires it.

Prefer understanding whether timestamps are stored as UTC or local time before changing date/time logic.

## Production safety

This is not a disposable prototype.

Before changing production-sensitive behavior:

* inspect the existing implementation
* preserve existing contracts when possible
* avoid destructive database operations
* avoid broad refactors
* make the smallest functional change
* verify the diff before finishing

If an unrelated problem is discovered, report it separately instead of automatically expanding the task.
