# CODEX_WORKFLOWS.md

## General workflow

For every task:

1. Read only the files relevant to the requested change.
2. Identify the smallest affected code path.
3. Briefly explain the likely cause or implementation plan before editing.
4. Make only the changes necessary for the requested task.
5. Do not fix unrelated issues discovered during the task.
6. Run the smallest relevant verification.
7. Inspect the final diff for unrelated changes.
8. Summarize changed files, verification results, risks, and manual checks.

Useful final checks:

```bash
git status --short
git diff
git diff -- <changed-file>
```

Do not run repository-wide formatters, auto-fix tools, dependency upgrades, or cleanup commands unless explicitly requested.

## Bug fix workflow

1. Reproduce the bug when possible, or infer it from the error message, logs, and existing code.
2. Locate the smallest relevant Flutter, FastAPI, database, Firebase, or WebSocket code path.
3. Identify the actual cause before editing.
4. Check whether the bug crosses the Flutter ↔ FastAPI boundary.
5. Make the smallest safe fix.
6. Preserve existing behavior outside the reported bug.
7. Run the smallest relevant verification.
8. Inspect the final diff.
9. Summarize:

   * cause
   * changed files
   * fix
   * verification result
   * remaining risk
   * manual QA steps

Do not refactor surrounding code merely because it looks related or could be cleaner.

## Flutter bug fix workflow

1. Identify the affected screen, widget, state, model, or API service.
2. Check:

   * null values
   * async loading
   * error handling
   * widget lifecycle
   * navigation timing
   * repeated API calls
   * unnecessary rebuilds
3. If backend data is involved, inspect the corresponding FastAPI response before changing Flutter assumptions.
4. Follow the existing state management and API access patterns.
5. Modify only the affected Dart files.
6. Format only intentionally changed Dart files when required:

```bash
dart format path/to/changed_file.dart
```

7. Run:

```bash
flutter analyze
```

8. Run relevant existing tests when available:

```bash
flutter test <relevant-test>
```

9. Describe the exact screen and state that should be manually tested.
10. Inspect `git diff` after formatting and remove unrelated formatting changes.

## FastAPI bug fix workflow

1. Locate the affected:

   * router
   * dependency
   * request/response schema
   * CRUD/service function
   * SQLAlchemy model
   * WebSocket handler
2. Confirm the endpoint path, HTTP method, inputs, outputs, and status codes expected by Flutter.
3. Check:

   * Pydantic validation
   * nullable/required fields
   * SQLAlchemy query results
   * database session handling
   * commit/refresh behavior
   * exception handling
   * authentication and authorization
4. Make the smallest fix in the appropriate existing layer.
5. Do not reorganize routers, services, schemas, or models unless explicitly requested.
6. Run a syntax check for changed Python files when appropriate:

```bash
python -m py_compile path/to/changed_file.py
```

7. Run relevant existing tests when available:

```bash
pytest <relevant-test>
```

8. Verify that the current Flutter client remains compatible.
9. Inspect the final diff.

## Feature/page addition workflow

1. Find the closest existing page or feature with similar behavior.
2. Reuse existing:

   * navigation
   * state management
   * API service
   * models
   * theme
   * widgets
   * loading and error patterns
3. Determine whether the feature requires:

   * Flutter-only changes
   * FastAPI-only changes
   * both Flutter and FastAPI changes
4. Define the smallest required data flow before editing.
5. Create only the minimum required UI and logic.
6. Avoid adding packages or dependencies unless necessary.
7. Do not introduce a new architecture or state-management pattern.
8. Check:

   * loading state
   * empty state
   * error state
   * permission state
   * null values
   * repeated submission
   * navigation behavior
9. Verify any API request/response contract on both sides.
10. Run the smallest relevant checks.
11. Provide manual QA steps covering the new feature and an existing unaffected flow.

## Flutter ↔ FastAPI API change workflow

1. Identify every Flutter caller of the endpoint.
2. Identify the FastAPI router, schemas, service/CRUD logic, and database access involved.
3. Document the existing contract:

   * endpoint path
   * HTTP method
   * query parameters
   * request body
   * response body
   * nullability
   * status codes
   * date/time format
4. Prefer a backward-compatible change.
5. Do not rename or remove existing response fields unless explicitly required.
6. Do not make an existing optional field required without checking current users and stored data.
7. Update only the necessary client and server code.
8. Confirm that JSON field names and Dart/Pydantic types match.
9. Check old or partial database records where applicable.
10. Verify error behavior as well as success behavior.
11. Summarize the exact API contract change in the final response.

## FastAPI endpoint addition workflow

1. Find a similar existing endpoint.
2. Reuse the current router, dependency, schema, and CRUD/service patterns.
3. Define the minimum required request and response fields.
4. Avoid returning full database models when a smaller response is sufficient.
5. Confirm company/store ownership and authorization rules.
6. Avoid unnecessary queries and queries inside loops.
7. Use existing transaction and commit patterns.
8. Add WebSocket broadcasting only when connected clients actually require real-time updates.
9. Update the Flutter API client only when the endpoint is used by Flutter.
10. Run relevant syntax/tests and inspect the diff.

## Database change workflow

1. Determine whether an application-code change can solve the task without changing the schema.
2. If a schema change is genuinely required, identify:

   * affected SQLAlchemy model
   * affected Pydantic schemas
   * affected FastAPI endpoints
   * affected Flutter models and callers
   * existing production data
3. Check:

   * type
   * nullability
   * default value
   * unique constraints
   * foreign keys
   * relationships
   * indexes
4. Consider compatibility with existing rows before making a field required.
5. Do not drop, rename, or destructively modify columns without explicit approval.
6. Do not reset or reseed production data.
7. Do not create or run a migration unless the requested change requires it.
8. If migration is required, explain:

   * migration steps
   * data backfill
   * backward compatibility
   * rollback risk
9. Verify local and deployed database assumptions separately.
10. Clearly warn about production-data risks.

## SQLAlchemy query workflow

1. Identify the exact data needed by the request.
2. Reuse existing query and company/store filtering patterns.
3. Avoid loading unnecessary rows or relationships.
4. Avoid additional database queries inside loops.
5. Confirm whether the query returns:

   * one object
   * an optional object
   * a list
6. Treat `.all()` as a list result, including an empty list.
7. Distinguish between:

   * parent resource not found
   * valid parent with no child records
8. Check session, commit, refresh, and rollback behavior.
9. Verify that data from another company/store cannot be accessed.
10. Do not change relationship loading strategies unless required for the task.

## WebSocket / real-time change workflow

1. Identify the database operation that produces the real-time update.
2. Identify the WebSocket event type and payload expected by Flutter.
3. Confirm whether the database operation succeeds before broadcasting.
4. Check that the payload contains only the fields Flutter expects.
5. Preserve company/store isolation.
6. Avoid duplicate broadcasts.
7. Avoid broadcasting full datasets when a smaller update is sufficient, unless the current architecture intentionally requires full refreshes.
8. Check connection and disconnection behavior.
9. Check how Flutter handles:

   * duplicate events
   * missing fields
   * reconnects
   * screen disposal
10. Manually test with more than one connected client when practical.

For table operations, verify the full relevant flow:

```text
Flutter action
→ FastAPI request
→ Database update
→ WebSocket broadcast
→ Other Flutter clients update
```

## Firebase change workflow

Firebase may still be used for authentication, FCM, Firestore, or legacy functionality.

1. Identify the exact Firebase feature involved.
2. Verify that the code is still in active use before changing or removing it.
3. Preserve Firebase Auth behavior unless the task explicitly changes authentication.
4. Preserve FCM token and notification behavior unless explicitly requested.
5. Never print, expose, hardcode, or commit credentials.
6. Do not remove Firebase code merely because a FastAPI implementation exists.
7. Check whether Flutter and FastAPI share or depend on the Firebase user ID.
8. Verify sign-in, sign-out, token refresh, and existing-user behavior when relevant.

If Firestore is involved:

1. Identify affected collections and documents.
2. Check existing read/write patterns.
3. Avoid additional reads inside loops.
4. Check listener lifecycle and disposal.
5. Mention if a new Firestore index may be required.
6. Avoid collection, document, rule, index, or schema changes unless explicitly requested.
7. If a schema change is unavoidable, describe migration and backward compatibility.

## Authentication / authorization workflow

1. Identify whether authentication is handled by Firebase Auth, FastAPI, or both.
2. Trace how the authenticated Firebase user ID or token reaches FastAPI.
3. Confirm the backend user lookup behavior.
4. Check:

   * unauthenticated users
   * users without a company
   * invalid or expired tokens
   * missing backend user records
   * role and permission checks
5. Do not silently change login routing or existing-user behavior.
6. Verify that users cannot access another company's data.
7. Test both success and failure states.

## UI change workflow

1. Find the nearest existing UI pattern.
2. Match the existing:

   * typography
   * components
   * spacing
   * navigation
   * loading indicators
   * error messages
3. Change only the requested screen or component.
4. Do not redesign adjacent screens.
5. Check small-screen and real-device behavior.
6. Preserve:

   * loading state
   * error state
   * empty state
   * disabled state
7. Avoid overengineering animations or abstractions.
8. Confirm that UI actions cannot be submitted repeatedly by accident.
9. Provide clear manual test scenarios.
10. Format only the changed Dart files if necessary.

## Performance issue workflow

1. Identify whether the delay is caused by:

   * Flutter rendering
   * repeated rebuilds
   * sequential API calls
   * backend processing
   * database queries
   * Railway/network latency
   * WebSocket handling
2. Measure or inspect the current flow before optimizing.
3. Do not perform broad performance refactors based only on assumptions.
4. Look for the smallest confirmed bottleneck.
5. Preserve API and UI behavior.
6. Avoid adding caches unless invalidation and data consistency are understood.
7. Compare behavior before and after the change.
8. Report what was measured, inferred, or still uncertain.

## Date/time bug workflow

1. Identify the timestamp source:

   * Flutter device
   * FastAPI server
   * database
   * Firebase
2. Determine whether the stored value is UTC, local time, or timezone-naive.
3. Trace every conversion before changing code.
4. Do not blindly add or subtract nine hours.
5. Prefer a consistent UTC storage and explicit display-time conversion pattern when compatible with the existing architecture.
6. Check local and deployed environments.
7. Test dates around midnight and day changes when relevant.
8. Confirm that existing stored timestamps remain compatible.

## Deployment-related workflow

1. Identify whether the issue is local, build-time, or deployed-runtime behavior.
2. Check the smallest relevant configuration or log.
3. Do not change unrelated deployment settings.
4. Do not expose environment-variable values or credentials.
5. Preserve existing production URLs, bundle IDs, package names, and signing settings unless explicitly requested.
6. For FastAPI deployment issues, verify:

   * startup command
   * required environment variables
   * health endpoint
   * database connection
   * Firebase service-account loading
7. For Flutter builds, verify only the affected platform.
8. Clearly separate:

   * code change
   * local configuration
   * deployment configuration
   * manual user action

## Verification workflow

Choose only the checks relevant to the changed files.

### Flutter

```bash
dart format path/to/changed_file.dart
flutter analyze
flutter test <relevant-test>
```

Do not run `dart format .` unless repository-wide formatting is explicitly requested.

### FastAPI / Python

```bash
python -m py_compile path/to/changed_file.py
pytest <relevant-test>
```

Do not introduce or run repository-wide auto-fix or formatting tools unless explicitly requested.

### Final diff

Always inspect:

```bash
git status --short
git diff
```

Confirm:

* only intended files changed
* only necessary lines changed
* no unrelated formatting was introduced
* no unrelated issue was fixed
* no credentials or secrets were added
* Flutter and FastAPI contracts remain compatible

If a command cannot be run, state the reason and provide the exact command the user should run.
