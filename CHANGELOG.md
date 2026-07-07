# Changelog

## 2026-07-07 - PR #4

- Resolve Symphony Web UI audit findings and improve readability (@quangdang46)
- Merge commit: `532e3ed8d980a882fb3b2770353405a5e5cdee97`
- Harness CLI release: not required
- Changed files:
  - `.agents/skills/impeccable/SKILL.md`
  - `.agents/skills/impeccable/agents/impeccable_asset_producer.toml`
  - `.agents/skills/impeccable/agents/impeccable_manual_edit_applier.toml`
  - `.agents/skills/impeccable/agents/openai.yaml`
  - `.agents/skills/impeccable/reference/adapt.md`
  - `.agents/skills/impeccable/reference/animate.md`
  - `.agents/skills/impeccable/reference/audit.md`
  - `.agents/skills/impeccable/reference/bolder.md`
  - `.agents/skills/impeccable/reference/brand.md`
  - `.agents/skills/impeccable/reference/clarify.md`
  - `.agents/skills/impeccable/reference/codex.md`
  - `.agents/skills/impeccable/reference/colorize.md`
  - `.agents/skills/impeccable/reference/craft.md`
  - `.agents/skills/impeccable/reference/critique.md`
  - `.agents/skills/impeccable/reference/delight.md`
  - `.agents/skills/impeccable/reference/distill.md`
  - `.agents/skills/impeccable/reference/document.md`
  - `.agents/skills/impeccable/reference/extract.md`
  - `.agents/skills/impeccable/reference/harden.md`
  - `.agents/skills/impeccable/reference/hooks.md`
  - `.agents/skills/impeccable/reference/init.md`
  - `.agents/skills/impeccable/reference/interaction-design.md`
  - `.agents/skills/impeccable/reference/layout.md`
  - `.agents/skills/impeccable/reference/live.md`
  - `.agents/skills/impeccable/reference/onboard.md`
  - `.agents/skills/impeccable/reference/optimize.md`
  - `.agents/skills/impeccable/reference/overdrive.md`
  - `.agents/skills/impeccable/reference/polish.md`
  - `.agents/skills/impeccable/reference/product.md`
  - `.agents/skills/impeccable/reference/quieter.md`
  - `.agents/skills/impeccable/reference/shape.md`
  - `.agents/skills/impeccable/reference/typeset.md`
  - `.agents/skills/impeccable/scripts/command-metadata.json`
  - `.agents/skills/impeccable/scripts/context-signals.mjs`
  - `.agents/skills/impeccable/scripts/context.mjs`
  - `.agents/skills/impeccable/scripts/critique-storage.mjs`
  - `.agents/skills/impeccable/scripts/detect-csp.mjs`
  - `.agents/skills/impeccable/scripts/detect.mjs`
  - `.agents/skills/impeccable/scripts/detector/browser/injected/index.mjs`
  - `.agents/skills/impeccable/scripts/detector/cli/main.mjs`
  - `.agents/skills/impeccable/scripts/detector/design-system.mjs`
  - `.agents/skills/impeccable/scripts/detector/detect-antipatterns-browser.js`
  - `.agents/skills/impeccable/scripts/detector/detect-antipatterns.mjs`
  - `.agents/skills/impeccable/scripts/detector/engines/browser/detect-url.mjs`
  - `.agents/skills/impeccable/scripts/detector/engines/regex/detect-text.mjs`
  - `.agents/skills/impeccable/scripts/detector/engines/static-html/css-cascade.mjs`
  - `.agents/skills/impeccable/scripts/detector/engines/static-html/detect-html.mjs`
  - `.agents/skills/impeccable/scripts/detector/engines/visual/screenshot-contrast.mjs`
  - `.agents/skills/impeccable/scripts/detector/findings.mjs`
  - `.agents/skills/impeccable/scripts/detector/node/file-system.mjs`
  - `.agents/skills/impeccable/scripts/detector/profile/profiler.mjs`
  - `.agents/skills/impeccable/scripts/detector/registry/antipatterns.mjs`
  - `.agents/skills/impeccable/scripts/detector/rules/checks.mjs`
  - `.agents/skills/impeccable/scripts/detector/shared/color.mjs`
  - `.agents/skills/impeccable/scripts/detector/shared/constants.mjs`
  - `.agents/skills/impeccable/scripts/detector/shared/inline-ignores.mjs`
  - `.agents/skills/impeccable/scripts/detector/shared/page.mjs`
  - `.agents/skills/impeccable/scripts/hook-admin.mjs`
  - `.agents/skills/impeccable/scripts/hook-before-edit.mjs`
  - `.agents/skills/impeccable/scripts/hook-lib.mjs`
  - `.agents/skills/impeccable/scripts/hook.mjs`
  - `.agents/skills/impeccable/scripts/lib/design-parser.mjs`
  - `.agents/skills/impeccable/scripts/lib/impeccable-config.mjs`
  - `.agents/skills/impeccable/scripts/lib/impeccable-paths.mjs`
  - `.agents/skills/impeccable/scripts/lib/is-generated.mjs`
  - `.agents/skills/impeccable/scripts/lib/target-args.mjs`
  - `.agents/skills/impeccable/scripts/live-accept.mjs`
  - `.agents/skills/impeccable/scripts/live-browser-dom.js`
  - `.agents/skills/impeccable/scripts/live-browser-session.js`
  - `.agents/skills/impeccable/scripts/live-browser.js`
  - `.agents/skills/impeccable/scripts/live-commit-manual-edits.mjs`
  - `.agents/skills/impeccable/scripts/live-complete.mjs`
  - `.agents/skills/impeccable/scripts/live-copy-edit-agent.mjs`
  - `.agents/skills/impeccable/scripts/live-discard-manual-edits.mjs`
  - `.agents/skills/impeccable/scripts/live-inject.mjs`
  - `.agents/skills/impeccable/scripts/live-insert.mjs`
  - `.agents/skills/impeccable/scripts/live-manual-edit-evidence.mjs`
  - `.agents/skills/impeccable/scripts/live-poll.mjs`
  - `.agents/skills/impeccable/scripts/live-resume.mjs`
  - `.agents/skills/impeccable/scripts/live-server.mjs`
  - `.agents/skills/impeccable/scripts/live-status.mjs`
  - `.agents/skills/impeccable/scripts/live-target.mjs`
  - `.agents/skills/impeccable/scripts/live-wrap.mjs`
  - `.agents/skills/impeccable/scripts/live.mjs`
  - `.agents/skills/impeccable/scripts/live/browser-script-parts.mjs`
  - `.agents/skills/impeccable/scripts/live/completion.mjs`
  - `.agents/skills/impeccable/scripts/live/event-validation.mjs`
  - `.agents/skills/impeccable/scripts/live/insert-ui.mjs`
  - `.agents/skills/impeccable/scripts/live/manual-apply.mjs`
  - `.agents/skills/impeccable/scripts/live/manual-edit-routes.mjs`
  - `.agents/skills/impeccable/scripts/live/manual-edits-buffer.mjs`
  - `.agents/skills/impeccable/scripts/live/session-store.mjs`
  - `.agents/skills/impeccable/scripts/live/svelte-component.mjs`
  - `.agents/skills/impeccable/scripts/live/sveltekit-adapter.mjs`
  - `.agents/skills/impeccable/scripts/live/ui-core.mjs`
  - `.agents/skills/impeccable/scripts/live/vocabulary.mjs`
  - `.agents/skills/impeccable/scripts/modern-screenshot.umd.js`
  - `.agents/skills/impeccable/scripts/palette.mjs`
  - `.agents/skills/impeccable/scripts/pin.mjs`
  - `.codex/hooks.json`

## 2026-07-07 - PR #37

- US-070: completed (@hoangnb24)
- Merge commit: `ac748021b7a46b71ff7cde187f68073098b1a3b8`
- Harness CLI release: not required
- Changed files:
  - `.harness/changesets/run_1783405248236036000_24617_0.changeset.jsonl`
  - `crates/harness-symphony/web-ui/src/features/symphony/board.tsx`
  - `crates/harness-symphony/web-ui/tests/board.spec.ts`
  - `docs/stories/epics/E08-symphony-web-ui-controller/US-070-readable-done-column-task-cards.md`

## 2026-07-05 - PR #36

- US-068: completed (@hoangnb24)
- Merge commit: `5049c9704ca6f60f7446b9760603b2dcb4fecdf5`
- Harness CLI release: not required
- Changed files:
  - `.harness/changesets/run_1783224245101133000_18033_0.changeset.jsonl`
  - `crates/harness-symphony/web-ui/src/main.tsx`
  - `crates/harness-symphony/web-ui/src/styles.css`
  - `crates/harness-symphony/web-ui/tests/board.spec.ts`
  - `docs/stories/epics/E08-symphony-web-ui-controller/US-068-bounded-work-item-cards.md`

## 2026-07-04 - PR #35

- US-064: completed (@hoangnb24)
- Merge commit: `f7ace90df8d3ff16655dc29b42686d96a25f8fb3`
- Harness CLI release: not required
- Changed files:
  - `.harness/changesets/run_1783179886029971000_7111_0.changeset.jsonl`
  - `crates/harness-symphony/src/web.rs`
  - `crates/harness-symphony/src/work.rs`
  - `crates/harness-symphony/web-ui/src/main.tsx`
  - `crates/harness-symphony/web-ui/tests/board.spec.ts`
  - `docs/stories/epics/E08-symphony-web-ui-controller/US-064-ready-work-story-delete.md`

## 2026-07-04 - PR #34

- US-067: completed (@hoangnb24)
- Merge commit: `8c299574450c6febe91fa235c4642c7e4cb0afc4`
- Harness CLI release: not required
- Changed files:
  - `.harness/changesets/run_1783178537862657000_95182_0.changeset.jsonl`
  - `crates/harness-symphony/src/web.rs`
  - `crates/harness-symphony/web-ui/src/main.tsx`
  - `crates/harness-symphony/web-ui/tests/board.spec.ts`
  - `docs/stories/epics/E08-symphony-web-ui-controller/US-067-needs-attention-recovery-action.md`

## 2026-07-04 - PR #33

- US-066: completed (@hoangnb24)
- Merge commit: `fe26f2cde1d0e5e043dc807af35d945a975b51aa`
- Harness CLI release: not required
- Changed files:
  - `.harness/changesets/run_1783164291664744000_6614_2.changeset.jsonl`
  - `crates/harness-symphony/src/web.rs`
  - `crates/harness-symphony/web-ui/src/main.tsx`
  - `crates/harness-symphony/web-ui/tests/board.spec.ts`

## 2026-07-04 - PR #32

- US-065: completed (@hoangnb24)
- Merge commit: `67c1c64b1d479f6c04e509f363ae749017ce70a9`
- Harness CLI release: not required
- Changed files:
  - `.harness/changesets/run_1783163412740491000_6614_1.changeset.jsonl`
  - `crates/harness-symphony/src/agent.rs`
  - `crates/harness-symphony/src/interface.rs`
  - `docs/SYMPHONY_SCOPE.md`

## 2026-07-04 - PR #31

- Add Harness Symphony runner and Web UI controller (@hoangnb24)
- Merge commit: `61a642b9e496fd981c1ec9126b1695ec18463db3`
- Harness CLI release: `harness-cli-v0.1.11`
- Changed files:
  - `.gitignore`
  - `.harness/changesets/run_0000000000_seed_symphony_index.changeset.jsonl`
  - `.harness/changesets/run_1782473523_99206.changeset.jsonl`
  - `.harness/changesets/run_1782536604_52965.changeset.jsonl`
  - `.harness/changesets/run_1782543459_701.changeset.jsonl`
  - `.harness/changesets/run_1782550121_26667.changeset.jsonl`
  - `Cargo.lock`
  - `Cargo.toml`
  - `README.md`
  - `crates/harness-cli/Cargo.toml`
  - `crates/harness-cli/src/application.rs`
  - `crates/harness-cli/src/infrastructure.rs`
  - `crates/harness-cli/src/interface.rs`
  - `crates/harness-symphony/Cargo.toml`
  - `crates/harness-symphony/src/agent.rs`
  - `crates/harness-symphony/src/auto.rs`
  - `crates/harness-symphony/src/changeset.rs`
  - `crates/harness-symphony/src/config.rs`
  - `crates/harness-symphony/src/doctor.rs`
  - `crates/harness-symphony/src/interface.rs`
  - `crates/harness-symphony/src/main.rs`
  - `crates/harness-symphony/src/pr.rs`
  - `crates/harness-symphony/src/retention.rs`
  - `crates/harness-symphony/src/run.rs`
  - `crates/harness-symphony/src/state.rs`
  - `crates/harness-symphony/src/sync.rs`
  - `crates/harness-symphony/src/web.rs`
  - `crates/harness-symphony/src/work.rs`
  - `crates/harness-symphony/web-ui/electron/backend.cjs`
  - `crates/harness-symphony/web-ui/electron/browser-dev.cjs`
  - `crates/harness-symphony/web-ui/electron/dev.cjs`
  - `crates/harness-symphony/web-ui/electron/main.cjs`
  - `crates/harness-symphony/web-ui/electron/smoke.cjs`
  - `crates/harness-symphony/web-ui/index.html`
  - `crates/harness-symphony/web-ui/package-lock.json`
  - `crates/harness-symphony/web-ui/package.json`
  - `crates/harness-symphony/web-ui/playwright.config.ts`
  - `crates/harness-symphony/web-ui/postcss.config.js`
  - `crates/harness-symphony/web-ui/src/components/ui/badge.tsx`
  - `crates/harness-symphony/web-ui/src/components/ui/button.tsx`
  - `crates/harness-symphony/web-ui/src/components/ui/card.tsx`
  - `crates/harness-symphony/web-ui/src/components/ui/input.tsx`
  - `crates/harness-symphony/web-ui/src/components/ui/separator.tsx`
  - `crates/harness-symphony/web-ui/src/lib/utils.ts`
  - `crates/harness-symphony/web-ui/src/main.tsx`
  - `crates/harness-symphony/web-ui/src/run-log.ts`
  - `crates/harness-symphony/web-ui/src/styles.css`
  - `crates/harness-symphony/web-ui/tailwind.config.ts`
  - `crates/harness-symphony/web-ui/tests/board.spec.ts`
  - `crates/harness-symphony/web-ui/tsconfig.json`
  - `crates/harness-symphony/web-ui/vite.config.ts`
  - `docs/README.md`
  - `docs/SYMPHONY_QUICKSTART.md`
  - `docs/SYMPHONY_SCOPE.md`
  - `docs/TOOL_REGISTRY.md`
  - `docs/design/symphony-web-ui-controller/README.md`
  - `docs/design/symphony-web-ui-controller/artifact.json`
  - `docs/design/symphony-web-ui-controller/critique.json`
  - `docs/design/symphony-web-ui-controller/data.json`
  - `docs/design/symphony-web-ui-controller/mqum833g-drawing-2026-06-26T07-34-24-936Z.png`
  - `docs/design/symphony-web-ui-controller/provenance.json`
  - `docs/design/symphony-web-ui-controller/template.html`
  - `docs/design/symphony-web-ui-controller/template.html.artifact.json`
  - `docs/product/README.md`
  - `docs/product/symphony-web-ui-controller.md`
  - `docs/reviews/develop-to-main-pr-review.md`
  - `docs/stories/US-001-install-harness.md`
  - `docs/stories/US-046-first-class-symphony-codex-adapter.md`
  - `docs/stories/epics/E04-symphony-cli-prerequisites/README.md`
  - `docs/stories/epics/E04-symphony-cli-prerequisites/US-028-harness-db-path.md`
  - `docs/stories/epics/E04-symphony-cli-prerequisites/US-029-operation-log-writing.md`
  - `docs/stories/epics/E04-symphony-cli-prerequisites/US-030-changeset-apply.md`
  - `docs/stories/epics/E04-symphony-cli-prerequisites/US-031-db-rebuild.md`
  - `docs/stories/epics/E05-symphony-local-runner/README.md`
  - `docs/stories/epics/E05-symphony-local-runner/US-032-symphony-crate-config.md`
  - `docs/stories/epics/E05-symphony-local-runner/US-033-symphony-doctor.md`
  - `docs/stories/epics/E05-symphony-local-runner/US-034-work-list.md`
  - `docs/stories/epics/E05-symphony-local-runner/US-035-run-state-lock.md`
  - `docs/stories/epics/E05-symphony-local-runner/US-036-prepare-isolated-run.md`
  - `docs/stories/epics/E05-symphony-local-runner/US-037-run-contract-agents-shim.md`
  - `docs/stories/epics/E05-symphony-local-runner/US-038-result-validation-agent-adapter.md`
  - `docs/stories/epics/E05-symphony-local-runner/US-039-runs-status.md`
  - `docs/stories/epics/E06-symphony-review-sync/README.md`
  - `docs/stories/epics/E06-symphony-review-sync/US-040-changeset-rendering.md`
  - `docs/stories/epics/E06-symphony-review-sync/US-041-optional-pr-creation.md`
  - `docs/stories/epics/E06-symphony-review-sync/US-042-symphony-sync.md`
  - `docs/stories/epics/E06-symphony-review-sync/US-043-artifact-retention.md`
  - `docs/stories/epics/E07-symphony-automation/README.md`
  - `docs/stories/epics/E07-symphony-automation/US-044-tiny-here-run.md`
  - `docs/stories/epics/E07-symphony-automation/US-045-auto-mode-work-sources.md`
  - `docs/stories/epics/E08-symphony-web-ui-controller/README.md`
  - `docs/stories/epics/E08-symphony-web-ui-controller/US-047-dependency-board-foundation.md`
  - `docs/stories/epics/E08-symphony-web-ui-controller/US-047-dependency-board-foundation/design.md`
  - `docs/stories/epics/E08-symphony-web-ui-controller/US-047-dependency-board-foundation/execplan.md`
  - `docs/stories/epics/E08-symphony-web-ui-controller/US-047-dependency-board-foundation/overview.md`
  - `docs/stories/epics/E08-symphony-web-ui-controller/US-047-dependency-board-foundation/validation.md`
  - `docs/stories/epics/E08-symphony-web-ui-controller/US-048-local-web-backend-api.md`
  - `docs/stories/epics/E08-symphony-web-ui-controller/US-049-browser-board-task-detail-ui.md`
  - `docs/stories/epics/E08-symphony-web-ui-controller/US-050-run-start-event-api.md`
  - `docs/stories/epics/E08-symphony-web-ui-controller/US-051-review-surface-run-artifacts.md`

## 2026-06-15 - PR #20

- fix: add missing files to installer file lists (@NguyenQS504092s)
- Merge commit: `e3a83390be59eafcf361afe61672db1a9ed0a440`
- Harness CLI release: not required
- Changed files:
  - `scripts/install-harness.ps1`
  - `scripts/install-harness.sh`

## 2026-06-13 - PR #19

- feat(cli): kind-aware inbound tool registry with presence scanning (@thanh-dong)
- Merge commit: `04177b25a7f7e1c5acd24b71127db331c1b6602c`
- Harness CLI release: `harness-cli-v0.1.10`
- Changed files:
  - `AGENTS.md`
  - `README.md`
  - `crates/harness-cli/src/application.rs`
  - `crates/harness-cli/src/domain.rs`
  - `crates/harness-cli/src/infrastructure.rs`
  - `crates/harness-cli/src/interface.rs`
  - `docs/TOOL_REGISTRY.md`
  - `docs/stories/US-027-inbound-tool-registry.md`
  - `scripts/install-harness.sh`
  - `scripts/schema/005-tool-extensions.sql`

## 2026-06-09 - PR #13

- docs(phase5): Phase 5 — Evolution Infrastructure scope (@hoangnb24)
- Merge commit: `bfef94a77acfa33af81f6da96bc06f053d7f5164`
- Harness CLI release: `harness-cli-v0.1.9`
- Changed files:
  - `PHASE5.md`
  - `crates/harness-cli/src/application.rs`
  - `crates/harness-cli/src/domain.rs`
  - `crates/harness-cli/src/infrastructure.rs`
  - `crates/harness-cli/src/interface.rs`
  - `docs/FEATURE_INTAKE.md`
  - `docs/GLOSSARY.md`
  - `docs/HARNESS.md`
  - `docs/HARNESS_AUDIT.md`
  - `docs/HARNESS_COMPONENTS.md`
  - `docs/HARNESS_MATURITY.md`
  - `docs/IMPROVEMENT_PROTOCOL.md`
  - `docs/TOOL_REGISTRY.md`
  - `docs/decisions/0007-improvement-proposal-rules.md`
  - `docs/stories/US-019-machine-readable-tool-registry.md`
  - `docs/stories/US-020-batch-story-verification.md`
  - `docs/stories/US-021-intervention-recording-schema.md`
  - `docs/stories/US-022-context-rule-measurement.md`
  - `docs/stories/US-023-drift-detection-entropy-score.md`
  - `docs/stories/US-024-improvement-proposal-pipeline.md`
  - `docs/stories/epics/E03-phase-5-evolution-infrastructure/phase-5-progress.md`
  - `scripts/install-harness.sh`
  - `scripts/schema/003-tool-registry.sql`
  - `scripts/schema/004-intervention.sql`

## 2026-06-09 - Post-Merge Automation

- Added post-merge changelog automation for merged pull requests.
- Added conditional Harness CLI patch release automation when merged PRs change Rust CLI source, schema, Cargo metadata, or release packaging files.
- Reused the existing Harness CLI release workflow for release builds so tag, manual, and post-merge releases share the same verification and asset publishing path.
