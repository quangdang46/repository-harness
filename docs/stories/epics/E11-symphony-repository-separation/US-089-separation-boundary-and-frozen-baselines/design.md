# Design

## Domain Model

The migration inventory uses four stable identifiers:

- `source_sha`: immutable repository-harness commit.
- `source_path`: path at that commit.
- `record_identity`: stable story/trace/backlog/tool identity when available.
- `disposition`: `move`, `retain`, `rewrite`, `archive`, or `discard_after_gate`.

Every inventory row also records a reason and the story that may perform the
action. Unknown ownership is an error, not a default to move or delete.

## Application Flow

```text
verify clean source and empty target
  -> freeze source SHA
  -> tag and bundle all committed refs
  -> hash bundle and changesets
  -> inventory tracked paths
  -> export durable row metadata
  -> inventory worktrees and ignored runtime
  -> run green baseline
  -> review zero-unknown report
```

## Interface Contract

Evidence is stored under this story's future `evidence/` directory:

- `source.txt`
- `paths.tsv`
- `durable-records.json`
- `changesets.tsv`
- `changesets.sha256`
- `worktrees.txt`
- `worktrees/<worktree-id>/head.txt`
- `worktrees/<worktree-id>/staged.binary.patch`
- `worktrees/<worktree-id>/unstaged.binary.patch`
- `worktrees/<worktree-id>/untracked.tar` plus SHA-256 manifest
- `baseline.md`
- `bundle.sha256`

`paths.tsv` columns are:

```text
source_path  disposition  owner_repository  implementation_story  reason
```

## Data Model

After writers are stopped/fenced, the live SQLite database is captured with
SQLite's online backup API into a new file, integrity-checked, and checksummed.
A bare `harness.db` copy is not accepted because committed WAL pages may be
missing; a SQL dump is useful additional evidence, not the only backup.

Table discovery queries `sqlite_master` for every non-internal user table. The
export records table schema, stable UID where present, local ID, timestamp,
status/outcome, owner, disposition, and referenced parent identities. A
foreign-key closure check proves that every retained or moved row's referenced
rows have a compatible disposition. `schema_version` and `changeset_applied`
are classified as epoch/derived state rather than silently copied as product
records.

`git bundle --all` cannot contain dirty, staged, untracked, or ignored files.
Each dirty registered worktree therefore receives a binary patch for staged and
unstaged tracked changes plus a content-addressed untracked archive. A throwaway
checkout applies those artifacts and compares hashes before the inventory is
accepted.

Raw DB/worktree/run evidence is an operational backup, not repository content.
It is secret-scanned, stored outside both working trees with `0600`-equivalent
access or encryption, and referenced from committed evidence only by safe
logical identity and SHA-256.

## UI / Platform Impact

None. This story only records current state.

## Observability

The baseline report records command, exit status, tool versions, duration, and
the frozen SHA. A passing command from another commit is not accepted.

## Alternatives Considered

1. Use `git status` and a prose checklist only. Rejected because hundreds of
   paths and durable rows need machine-checkable coverage.
2. Treat the committed changesets as the full backup. Rejected because a fresh
   rebuild produces 59 stories while the live DB has 84.
3. Delete ignored runtime as generated data. Rejected because at least one
   registered worktree contains a real uncommitted implementation diff.
