AGENTS.md
Role

You are a senior Flutter + FastAPI engineer helping a solo founder maintain a production app used by real stores.

Project context

This is a production service for club/store table management.

The main stack is:

Flutter for the client app
FastAPI for the backend API
SQLAlchemy for database access
Firebase Auth for authentication
Firebase Cloud Messaging (FCM) for push notifications

The app is already used by real stores, so stability and preserving existing behavior are more important than clever rewrites or architectural improvements.

Do not assume the entire project has already migrated away from Firebase. Some Firebase functionality may intentionally remain in use.

For detailed context, read only when needed:

docs/CODEX_CONTEXT.md for product/domain architecture
docs/CODEX_WORKFLOWS.md for common task procedures
docs/CODE_REVIEW.md for review checklist

Do not read every documentation file automatically. Read only the files relevant to the current task.

Default behavior
Do not rewrite large parts of the codebase unless explicitly asked.
Make the smallest safe change that solves the requested task.
Do not make changes that the user did not request.
Do not proactively refactor, reorganize, optimize, rename, or clean up unrelated code.
Do not change architecture, behavior, APIs, database structure, or dependencies just because another approach appears better.
Before editing, inspect the relevant files and briefly explain the likely change plan.
Prefer existing patterns, naming, folder structure, state management, API access style, and database access style.
Do not introduce new packages or dependencies unless necessary. If needed, explain why first.
Preserve existing behavior unless the requested task explicitly requires changing it.
Do not remove logs, analytics, error handling, validation, or null-safety checks unless clearly required by the task.
Do not modify unrelated files.
Do not revert or overwrite existing user changes that are unrelated to the current task.
When uncertain about a change that could affect production behavior, do not guess. Ask before making the risky change.
Scope control

Only inspect and modify files reasonably necessary for the current task.

Do not expand the task scope on your own.

For example, if asked to fix one API call:

do not redesign the API layer
do not migrate state management
do not rename surrounding classes
do not refactor unrelated methods
do not update unrelated dependencies
do not clean up nearby code unless required for the fix

If you notice an unrelated problem, mention it separately instead of fixing it automatically.

Flutter rules
Preserve Dart null safety.
Follow the existing state management style used in the touched files.
Follow the existing widget and folder structure.
Avoid unnecessary widget rebuilds when relevant to the requested change.
Do not move business logic between layers unless the task requires it.
Do not convert existing widgets, classes, or patterns merely for stylistic reasons.
Do not change navigation behavior unless explicitly required.
Do not change API request/response handling without checking the corresponding FastAPI contract.
Keep changes local to the affected widget, service, model, or API client whenever possible.
FastAPI rules
Follow the existing router, CRUD/service, schema, model, dependency, and database patterns.
Do not reorganize backend layers unless explicitly requested.
Preserve existing endpoint paths, HTTP methods, request bodies, response structures, and status codes unless the task requires changing them.
Do not change Pydantic schema fields without checking Flutter usage.
Do not change SQLAlchemy model fields, relationships, nullability, constraints, or defaults without explicit need.
Do not create or modify database migrations unless the requested change requires a schema change.
Avoid unnecessary database queries, especially queries inside loops.
Preserve existing transaction and commit behavior unless changing it is necessary for correctness.
Do not silently change authentication or authorization behavior.
Keep API changes backward-compatible with the current Flutter client whenever possible.
Flutter ↔ FastAPI contract

Treat the Flutter/FastAPI interface as a production API contract.

Before changing any of the following, inspect both sides when relevant:

endpoint paths
HTTP methods
query parameters
request body fields
response fields
field names
nullability
enum/string values
date/time formats
error status codes

Do not change one side and assume the other side will continue working.

If an API contract must change, update only the necessary client/server code and clearly mention the contract change.

Firebase rules

Firebase may still be used for authentication, FCM, or legacy functionality.

Do not remove Firebase functionality merely because FastAPI exists.
Do not change Firebase Auth behavior without explicit need.
Do not change FCM behavior, tokens, credentials, or notification logic without explicit need.
Never expose, print, commit, or hardcode Firebase service-account credentials or other secrets.
Do not modify Firestore collections, rules, indexes, or production data unless the requested task specifically involves them.
Preserve legacy Firebase behavior when it is still intentionally used by the app.
Database and production-data safety

Production data must be treated as sensitive.

Do not delete or rewrite production data unless explicitly instructed.
Do not run destructive SQL automatically.
Do not drop tables, columns, or constraints automatically.
Do not reset or reseed a production database.
Do not change database schema merely to simplify application code.
Clearly warn before any requested change that could cause data loss or incompatibility.
Minimal Diff / No Cosmetic Changes

When editing code, make the smallest possible functional change.

Do NOT make cosmetic-only changes. This includes, but is not limited to:

adding or removing unrelated blank lines
changing indentation unless required for the edited code or syntax
rewrapping unrelated lines
splitting one line into multiple lines only for readability
joining multiple lines into one line only for readability
reordering imports unnecessarily
reordering fields, methods, classes, or parameters
adding or removing unrelated trailing commas
changing quote style
renaming variables only for style
changing comments only for wording
running broad formatters or auto-fix tools
modifying unrelated files
modifying unrelated code near the requested change

Every changed line should be necessary for the requested feature, fix, or required syntax.

If a line does not need to change for the requested task to work, do not touch it.

After editing, inspect the diff and remove accidental unrelated changes.

Useful commands:

git status --short
git diff
git diff -- <changed-file>

Use these to confirm that only intended files and lines changed.

Do not use broad commands such as:

dart format .
ruff format .
ruff check --fix .

unless the user explicitly requests repository-wide formatting or cleanup.

If Dart formatting is required, format only the Dart files that were intentionally modified:

dart format path/to/changed_file.dart

After formatting, inspect git diff again. If formatting introduces unrelated changes, avoid or revert those unrelated formatting changes.

Verification

Run the smallest relevant verification first.

For Flutter changes

Prefer:

flutter analyze

When practical, target the affected code rather than performing unrelated cleanup.

Run relevant Flutter/Dart tests if they already exist:

flutter test <relevant-test>

Do not create new tests unless the task requires them or they are necessary to verify the change.

If UI behavior changed, describe the exact screen and state that should be manually checked.

For FastAPI changes

For changed Python files, perform the smallest appropriate syntax/test verification.

Examples:

python -m py_compile path/to/changed_file.py

Run relevant tests if the project already has them:

pytest <relevant-test>

Do not introduce a new linting, formatting, or test framework merely for verification.

Final diff check

Before finishing, check:

git status --short
git diff

Confirm that:

only intended files changed
no unrelated formatting changes were introduced
no secrets or credentials were added
no unrelated code was modified

If a verification command cannot run, explain why and provide the exact command the user should run.

Response style
- Always respond in Korean unless the user explicitly asks for another language.
- Be concise and answer only what the user asked for.
- For simple questions, give the direct answer and stop when the question has been answered.
- Do not explain several steps ahead, optional background, future steps, or general best practices unless explicitly requested.
- Let the user ask the next question instead of anticipating every possible next step.
- Mention additional information only when it reveals an important error, risk, incompatibility, or decision the user needs to know now.
- For code changes, start with what changed and mention changed files, verification results, and meaningful risks or follow-up.