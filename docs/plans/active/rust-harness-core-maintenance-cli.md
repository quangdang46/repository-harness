# Execution Plan: Rust Harness Core Maintenance CLI

Date: 2026-07-21

## Status

Active

## Outcome

Ship a Rust CLI named `harness` with the default core. A fresh consumer can use
it to install the core, and an existing consumer can preview and apply a
recoverable three-way core update without silently discarding local changes.
The optional SQLite control plane remains outside the CLI.

## Context

- `AGENTS.md` names this as the current upstream goal.
- Decision `0024-rust-harness-core-maintenance-cli.md` defines the accepted
  ownership boundary.
- `docs/product/installation-profiles.md` describes current installer behavior.
- `scripts/install-harness.sh` and `scripts/install-harness.ps1` are the current
  cross-platform installation boundary.
- The existing `crates/harness-cli/` remains compatibility implementation, not
  the target core-maintenance CLI.

## Scope

In scope:

- A Rust executable named `harness`.
- Immutable, checksum-verified bootstrap installation on supported platforms.
- Tracked installed provenance sufficient to reconstruct the update base.
- Dry-run, three-way update, conflict, backup, atomic-apply, status, and
  diagnostic behavior.
- Migration from existing copy-on-install cores.
- Focused failure, recovery, cross-platform, and consumer-customization proof.

Out of scope:

- Intake, story, matrix, trace, scoring, proposal, or SQLite lifecycle commands.
- Work selection, agent orchestration, pull-request coordination, or evaluation.
- Automatic resolution of conflicting product or workflow policy.

## Approach

1. Specify the command contract, ownership classes, tracked provenance format,
   conflict result, and recovery guarantees before implementation.
2. Build the Rust CLI and focused unit tests independently of the compatibility
   crate.
3. Prove fresh installation and safe updates for unchanged, consumer-only,
   upstream-only, non-overlapping, and conflicting file changes.
4. Reduce Bash and PowerShell to immutable artifact bootstrap and delegation.
5. Prove migration from representative existing installations on macOS, Linux,
   and Windows.
6. Cut over product documentation and the default install only after the new
   behavior passes repository-wide validation.

## Risks And Recovery

- **Consumer data loss:** stage the complete result, stop on unresolved
  conflicts, back up affected files, and update provenance only after atomic
  activation.
- **Supply-chain substitution:** bind the bootstrap, binary, and core payload to
  one immutable release identity and verify checksums before execution.
- **Control-plane scope creep:** keep compatibility commands out of the new
  crate and enforce the command boundary mechanically.
- **Premature cutover:** retain the current installers and documentation until
  migration and rollback have been rehearsed.
- **Recovery:** before cutover, revert the feature branch. After cutover,
  restore the backed-up managed files and prior provenance, then run the prior
  immutable `harness` release.

## Progress

- [x] Record the accepted product boundary and current upstream goal.
- [ ] Specify commands, ownership, provenance, conflict, and recovery contracts.
- [ ] Implement the independent Rust CLI and focused tests.
- [ ] Implement immutable bootstraps and existing-install migration.
- [ ] Run cross-platform update and recovery proof.
- [ ] Cut over current product documentation and default installation.
- [ ] Run full repository validation and record the result.

## Decisions

- 2026-07-21: Name the product and executable `harness`.
- 2026-07-21: Install it with the default core and assign it core installation,
  update, provenance, and diagnostic ownership.
- 2026-07-21: Keep the optional SQLite and orchestration control plane outside
  the new CLI.

## Validation

- Focused proof: the direction-setting checkpoint passed agent-authority,
  documentation, workflow, Bash installer, and optional-consumer boundary
  contracts. Command and merge-contract tests remain pending implementation.
- Integration or end-to-end proof: pending fresh-install, customized-update,
  conflict, migration, rollback, and platform evidence.
- Repository-required checks: `scripts/validate-premerge.sh` passed for the
  direction-setting checkpoint. Full CLI implementation proof remains pending.

## Result

Pending implementation and validation.
