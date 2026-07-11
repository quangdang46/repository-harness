# Validation

## Proof Strategy

Test protocol behavior through the compiled CLI at process boundaries, not only
repository methods.

## Test Plan

| Layer | Cases |
| --- | --- |
| Unit | Typed JSON/error schemas, capability comparison, hierarchy cycle detection, CAS conflicts, header/hash validation. |
| Integration | Every listed CLI JSON read/write success/error against missing/current/needs-migration/unsupported DBs; semantic replay, snapshot, and atomic-failure parity. |
| E2E | A black-box fixture performs one-call graph discovery, WAL-safe snapshot, CAS status update, hierarchy query, and changeset apply without SQL. |
| Platform | macOS/Linux binary and Windows `.exe` emit equivalent bounded JSON; Bash/PowerShell forced upgrade verifies the same release tuple. |
| Performance | One JSON read handles the full current story graph without per-story subprocess calls. |
| Logs/Audit | Read-only queries write nothing; mutations produce one expected semantic operation. |
| Release | Immutable tag is newer than v0.1.11; every supported artifact checksum verifies after download. |

## Fixtures

- Fresh schema v12 database.
- Older supported database requiring migration.
- Cyclic and acyclic dependency/hierarchy graphs.
- Applied and unapplied changesets.
- Same run ID with same and changed content; unsupported header/base schema.
- Uncheckpointed WAL commit plus held reader during `db snapshot`.
- Non-UTF-8/space-containing platform paths and oversized/timeout fake output.

## Commands

```bash
cargo fmt --check
cargo test -p harness-cli --locked
cargo clippy -p harness-cli --all-targets -- -D warnings
scripts/validate-changeset-rebuild.sh
scripts/test-validate-changeset-rebuild.sh
scripts/build-harness-cli-release.sh
gh release view "$HARNESS_PROTOCOL_V1_TAG"
shasum -a 256 -c dist/*.sha256
tests/protocol/smoke-native-artifact.sh dist/<platform-artifact>
powershell -File tests/protocol/smoke-native-artifact.ps1 -Artifact dist/<windows-artifact>
git diff --check
```

## Acceptance Evidence

Pending implementation. Attach old text-output snapshots, protocol v1 JSON
fixtures, logical before/after hashes for all read-only/negative cases, an
uncheckpointed-WAL snapshot proof, replay proof, forced-upgrade proof, and
platform artifact smoke results.
