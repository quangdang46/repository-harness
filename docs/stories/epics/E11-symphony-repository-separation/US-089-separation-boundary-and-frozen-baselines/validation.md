# Validation

## Proof Strategy

Prove that the source can be reconstructed and every migration input is known
before testing any extraction.

## Test Plan

| Layer | Cases |
| --- | --- |
| Unit | Manifest parser rejects missing, duplicate, or invalid dispositions. |
| Integration | Bundle verifies; tag and bundle HEAD match the frozen SHA; DB backup opens read-only. |
| E2E | All source baseline commands pass at the recorded SHA. |
| Platform | Remote, worktree, and Windows-relevant generated paths are included. |
| Performance | Record bundle/database/runtime sizes so later archival has a bounded expectation. |
| Logs/Audit | Zero unclassified paths/tables/rows, foreign-key closure, and exact changeset ownership counts are reported. |

## Fixtures

- Source checkout at the accepted SHA.
- Empty Symphony target remote.
- Current live `harness.db` and the manifest-derived frozen changeset set (31
  discovery files plus the later E11 transitional planning file at this plan's
  current state).
- Every registered worktree, including staged, unstaged, untracked, binary,
  ignored, and clean cases.
- All registered local worktrees.

## Commands

```bash
git status --short
git rev-parse develop main HEAD
git bundle verify <bundle>
shasum -a 256 -c <bundle>.sha256
sqlite3 harness.db "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' ORDER BY name"
scripts/verify-e11-inventory.sh --require-zero-unknown --require-fk-closure
scripts/verify-e11-worktree-backups.sh <worktree-evidence-directory>
git worktree list --porcelain
cargo test --workspace
npm --prefix crates/harness-symphony/web-ui run build
npm --prefix crates/harness-symphony/web-ui run e2e
npm --prefix crates/harness-symphony/web-ui run desktop:smoke
cargo fmt --check
cargo clippy --workspace -- -D warnings
scripts/validate-changeset-rebuild.sh
git diff --check
```

## Acceptance Evidence

Pending implementation. Evidence must link to each artifact named in
`design.md` and include the frozen commit in every generated report.
