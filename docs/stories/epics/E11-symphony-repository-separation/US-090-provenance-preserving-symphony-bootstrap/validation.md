# Validation

## Proof Strategy

Prove both positive lineage (wanted commits remain) and negative scope (forbidden
Harness source and binary snapshots do not enter the target).

## Test Plan

| Layer | Cases |
| --- | --- |
| Unit | Manifest-to-filter input has deterministic ordering and no duplicate paths. |
| Integration | Old-to-new map resolves selected representative source commits. |
| E2E | Fresh clone of target contains expected files and raw-import tag. |
| Platform | Git operations use portable paths and do not depend on the original working tree. |
| Performance | Filtered repository size is recorded and excludes historical SQLite blobs. |
| Logs/Audit | Source refs before/after match; target provenance contains all immutable anchors. |
| Remote safety | Dry-run/command capture contains exactly `HEAD:main` and the raw-import tag refspec. |

## Fixtures

- Verified `US-089` bundle.
- Exact path manifest.
- Empty target remote.

## Commands

```bash
git bundle verify <source.bundle>
git filter-repo --version
shasum -a 256 -c <git-filter-repo-checksum-file>
git log --follow -- crates/harness-symphony/src/main.rs
git log --follow -- crates/harness-symphony/web-ui/src/main.tsx
tests/migration/assert-filter-scope.sh --expected-head main --expected-tag "$RAW_IMPORT_TAG"
git fsck --full
git ls-remote --heads --tags origin
```

The scope script fails on any Git/`rg` error, requires exactly the reviewed
head/tag refs, and rejects Harness CLI/database/hidden-tool paths; “no match” is
handled explicitly rather than with `|| true`.

## Acceptance Evidence

Pending implementation. Include the reviewed filter command, commit map,
source-ref before/after comparison, target clone check, and raw import tag.
