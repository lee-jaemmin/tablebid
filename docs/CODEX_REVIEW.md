# CODE_REVIEW.md

## Review checklist

### Correctness

* Does the change solve exactly the requested issue?
* Does it preserve existing behavior outside the requested change?
* Are edge cases handled?
* Are null values handled safely?
* Are async states handled correctly?
* Are error paths handled appropriately?
* Does the implementation make any assumptions not supported by the existing code?

### Scope / Minimal diff

* Is every changed file necessary for the requested task?
* Is every changed line necessary for the requested task?
* Were unrelated files or nearby code modified?
* Were unnecessary refactors, renames, cleanups, or formatting changes introduced?
* Could the same task have been solved with a smaller change?

Review the final diff and reject unrelated cosmetic changes.

### Flutter

* Is existing state management style preserved?
* Is the existing widget/folder structure preserved unless a change was required?
* Are null safety and type safety preserved?
* Are loading, success, empty, and error states handled correctly where relevant?
* Are rebuilds reasonable?
* Are API calls triggered only when intended?
* Could the change introduce duplicate API calls or repeated loading?
* Is navigation behavior preserved unless intentionally changed?
* If WebSocket data is involved, does the UI update correctly without unnecessary full-screen rebuilds?
* Were only intentionally modified Dart files formatted?

### FastAPI

* Does the endpoint preserve the expected HTTP method and path?
* Are request and response schemas correct?
* Are nullable and required fields correct?
* Are Pydantic schemas compatible with the actual data returned?
* Are SQLAlchemy queries correct and reasonably efficient?
* Are database sessions, commits, refreshes, and rollbacks handled correctly?
* Could the change introduce unnecessary queries, especially inside loops?
* Are appropriate HTTP status codes and errors returned?
* Is authentication/authorization behavior preserved?
* Does the change work with the existing database model and constraints?

### Flutter ↔ FastAPI contract

For API-related changes, verify both sides when relevant.

Check:

* endpoint path
* HTTP method
* request body fields
* query parameters
* JSON field names
* response structure
* nullable/non-nullable fields
* list/object types
* enum/string values
* date/time formats
* HTTP status codes

Ask:

* Could this backend change break the current Flutter client?
* Could this Flutter change send data the FastAPI endpoint does not accept?
* Could a renamed, removed, or newly required field break existing clients?
* Is the API change backward-compatible where possible?

Do not approve silent API contract changes.

### Database

* Does the change modify SQLAlchemy models or database structure?
* Are field types, defaults, nullability, constraints, and relationships correct?
* Could existing production rows violate the new assumptions?
* Is a migration actually required?
* Could the change cause data loss or overwrite existing values?
* Does the query correctly isolate data by company/store where required?
* Could concurrent requests create inconsistent data?

Do not approve destructive database operations or silent schema changes.

### WebSocket / Real-time behavior

If real-time functionality is affected:

* Is the correct event broadcast?
* Does the payload match what Flutter expects?
* Are clients updated after the database change succeeds?
* Could the same update be broadcast multiple times?
* Could the change cause unnecessary full-table refreshes?
* Are connection/disconnection cases handled safely?
* Could one company's update be sent to another company's clients?
* Is the database state still the source of truth where expected?

Pay extra attention to:

* table entry
* table movement
* table exit
* table grouping
* purchases
* reservation changes
* table status synchronization

### Firebase

Firebase may still be intentionally used for authentication, FCM, or legacy functionality.

Check when relevant:

* Is Firebase Auth behavior preserved?
* Is the Firebase user ID handled consistently with backend user data?
* Is FCM token handling preserved?
* Could push notifications be duplicated or skipped?
* Are credentials or service-account data exposed?
* Does the change accidentally remove Firebase functionality that is still required?

If Firestore is still involved in the touched code:

* Are reads/writes minimized?
* Are listeners disposed or scoped correctly?
* Could a query require a new index?
* Could the change break existing production documents?

### Date / Time

If timestamps are involved:

* Is UTC vs local time handled consistently?
* Does Flutter interpret backend timestamps correctly?
* Is timezone conversion happening in the correct layer?
* Is a fixed offset being added or subtracted without justification?
* Could date comparisons behave differently between local and deployed environments?

### Product risk

* Could this disrupt stores currently using the app?
* Does the change affect core table operations?
* Does the change affect reservations, purchases, authentication, permissions, or company/store settings?
* Could existing users or existing database records behave differently?
* Is manual QA clearly described for user-visible or production-sensitive changes?

### Security / Production safety

* Are secrets, tokens, private keys, or service-account credentials exposed?
* Is sensitive information logged unnecessarily?
* Does the API properly restrict access to company/store-specific data?
* Could a user access or modify another company's data?
* Are destructive database operations avoided?
* Are production configuration values preserved?

### Verification

Confirm that the smallest relevant checks were performed.

For Flutter changes, as appropriate:

```bash
flutter analyze
```

```bash
flutter test <relevant-test>
```

For FastAPI/Python changes, as appropriate:

```bash
python -m py_compile path/to/changed_file.py
```

```bash
pytest <relevant-test>
```

Before approval, inspect:

```bash
git status --short
git diff
```

Verify that:

* only intended files changed
* unrelated formatting was not introduced
* unrelated code was not modified
* no secrets were added
* the requested behavior is actually covered

If a command could not be run, the reason and the exact command for manual verification should be provided.

### Avoid

* Large unrelated refactors
* Changes outside the requested scope
* Cosmetic-only edits
* Repository-wide formatting or auto-fix
* New dependencies without justification
* Silent API contract changes
* Silent database schema changes
* Unclear migration assumptions
* Changing nullability without checking existing data and client usage
* Changing authentication or authorization behavior unintentionally
* Removing Firebase functionality simply because FastAPI exists
* Fixing unrelated issues without being asked
* Architecture changes made only because they appear cleaner
