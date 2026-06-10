# Harness Symphony Service Specification

Status: Draft v2 (language-agnostic, post-audit revision)

Purpose: Define a headless daemon service that dispatches coding agent sessions
against work items from pluggable sources, running agents in a Harness-governed
repository where the agent follows the Harness protocol autonomously.

## Normative Language

The key words `MUST`, `MUST NOT`, `REQUIRED`, `SHOULD`, `SHOULD NOT`,
`RECOMMENDED`, `MAY`, and `OPTIONAL` in this document are to be interpreted as
described in RFC 2119.

`Implementation-defined` means the behavior is part of the implementation
contract, but this specification does not prescribe one universal policy.
Implementations MUST document the selected behavior.

## 1. Problem Statement

Harness Symphony is a long-running headless daemon that reads work from a
pluggable source (issue tracker, Harness backlog, or command queue), launches
Codex agent sessions in a Harness-governed repository, and monitors their
lifecycle.

The service solves three operational problems:

- It turns agent execution into a repeatable daemon workflow instead of manual
  sessions.
- It keeps the workflow policy in-repo (`WORKFLOW.md`) so teams version
  scheduling config alongside their code and Harness docs.
- It provides enough observability to operate and debug agent runs (structured
  logs, optional TUI dashboard).

Important boundaries:

- Symphony is a **scheduler and runner**. It launches agents and monitors
  liveness. It does NOT classify work, assemble context, score traces, or run
  verification gates — the agent does all of that by following the Harness
  protocol (`AGENTS.md`, `FEATURE_INTAKE.md`, `CONTEXT_RULES.md`, etc.).
- Ticket writes (state transitions, comments, PR links) are performed by the
  coding agent using tools available in its session.
- A successful run can end at a workflow-defined handoff state (for example
  `Human Review`), not necessarily `Done`.
- The Harness context layer (docs, templates, CLI, `harness.db`) is the
  agent's operating environment. Symphony does not replace or enforce
  Harness — it orchestrates work within a Harness-governed repo.

### 1.1 Relationship to Harness

Harness is a repo-level operating system for coding agents. It provides:

- Feature intake classification and work generation
  (`docs/FEATURE_INTAKE.md`)
- Phase-by-lane context rules (`docs/CONTEXT_RULES.md`)
- Durable operational memory (`harness.db` via `harness-cli`)
- Story lifecycle, verification gates, trace recording
- Friction capture and improvement proposals

**All of these are agent-side responsibilities.** The agent follows Harness
because the repository's docs tell it to — not because an orchestrator
forces it. This is Harness's core design philosophy:

> "Coding agents need better repositories, not better orchestrators."

Symphony's role is to get the agent into the repo and keep it running.
Everything inside the session is governed by Harness docs, not by Symphony.

### 1.2 Relationship to OpenAI Symphony

This spec is derived from the OpenAI Symphony Service Specification (v1). Key
differences:

| Concern | Original Symphony | Harness Symphony |
|---|---|---|
| Work source | Linear only | Pluggable adapter (Linear first) |
| Agent awareness | None (black-box subprocess) | None (agent follows Harness autonomously) |
| Workspace model | Per-issue isolated directory | Single repo clone (v1); per-issue later |
| Persistent state | None (in-memory only) | None (in-memory; Harness has its own db) |
| Intake/context | Not applicable | Agent-side (not orchestrator) |
| Form factor | Headless daemon + optional HTTP | Headless daemon → optional TUI → optional HTTP |
| Concurrency | Up to 100+ agents, SSH workers | Single agent (v1); concurrency later |

Sections inherited from the original spec are noted with `[Symphony §N]`
references.

## 2. Goals and Non-Goals

### 2.1 Goals

- Read work items from a pluggable source on a fixed cadence.
- Maintain a single authoritative in-memory orchestrator state for dispatch,
  retries, and reconciliation.
- Launch Codex agent sessions in the Harness-governed repository with a
  rendered prompt containing the work item context.
- Stop active runs when work item state changes make them ineligible.
- Recover from transient failures with exponential backoff.
- Load runtime behavior from a repository-owned `WORKFLOW.md` contract.
- Expose operator-visible observability (structured logs at minimum).
- Support two intake modes: inline (agent handles intake as first step) and
  dedicated (separate intake session decomposes complex inputs into stories
  before dispatch).

### 2.2 Non-Goals

- Rich web UI or multi-tenant control plane.
- General-purpose workflow engine or distributed job scheduler.
- Built-in business logic for how to edit tickets, PRs, or comments (that
  logic lives in the workflow prompt and agent tooling).
- Orchestrator-side intake classification, context assembly, trace scoring,
  or verification gates — these are agent responsibilities governed by
  Harness docs.
- Multi-agent concurrency and shared-state management (deferred to v2).
- Replacing the Harness CLI or durable layer.
- Mandating a single sandbox or approval posture for all implementations.

## 3. Architecture Overview

### 3.1 Five-Layer Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    HARNESS SYMPHONY                       │
│                                                           │
│  Layer 1: Work Source (pluggable)                         │
│    Reads work items from Linear, GitHub, harness.db, etc. │
│                                                           │
│  Layer 2: Intake Router                                   │
│    Simple tasks → dispatch directly (inline intake)       │
│    Complex tasks → dedicated intake session first         │
│                                                           │
│  Layer 3: Scheduler (daemon core)                         │
│    Poll loop, dispatch, retry, reconciliation, liveness   │
│                                                           │
│  Layer 4: Agent Runner (Codex)                            │
│    Launch Codex app-server, stream events, manage session │
│                                                           │
│  Layer 5: Harness Repo (execution environment)            │
│    Agent follows AGENTS.md → intake → context → work →    │
│    trace → verify → friction                              │
└─────────────────────────────────────────────────────────┘
```

### 3.2 Main Components

1. `Workflow Loader`
   - Reads `WORKFLOW.md`.
   - Parses YAML front matter and prompt body.
   - Returns `{config, prompt_template}`.

2. `Config Layer`
   - Exposes typed getters for workflow config values.
   - Applies defaults and environment variable indirection.
   - Performs validation before dispatch.

3. `Work Source Adapter` (pluggable)
   - Fetches candidate work items from a configured source.
   - Fetches current states for specific item IDs (reconciliation).
   - Normalizes source payloads into a stable work item model.
   - Implementations: `LinearAdapter`, future `GitHubAdapter`,
     `HarnessBacklogAdapter`.

4. `Intake Router`
   - Examines each incoming work item.
   - Simple items (spec_slice, change_request, maintenance,
     harness_improvement) → dispatch directly; agent does inline intake.
   - Complex items (new_spec, new_initiative) → dispatch a dedicated intake
     session; generated stories become new dispatchable items.
   - Routing rules are configurable in `WORKFLOW.md`.

5. `Orchestrator`
   - Owns the poll tick.
   - Owns the in-memory runtime state.
   - Decides which items to dispatch, retry, stop, or release.
   - Single-agent dispatch in v1 (one running session at a time).

6. `Agent Runner`
   - Builds prompt from work item + workflow template.
   - Launches the Codex app-server subprocess in the repo directory.
   - Streams agent events back to the orchestrator.
   - Manages session lifecycle (turns, timeouts, continuation).

7. `Logging`
   - Emits structured runtime logs to configured sinks.

8. `Status Surface` (OPTIONAL, future)
   - TUI dashboard for real-time operator visibility.
   - HTTP API for programmatic access.

### 3.3 External Dependencies

- Work source API (Linear for `source.kind: linear` in v1).
- Local filesystem with the Harness-governed repository cloned.
- Codex app-server executable.
- Host environment authentication for the work source and Codex.

### 3.4 What Symphony Does NOT Own

These responsibilities belong to the agent following Harness docs:

| Responsibility | Harness Owner | Agent Reads |
|---|---|---|
| Intake classification | `FEATURE_INTAKE.md` | Agent classifies input type + risk lane |
| Work generation | `FEATURE_INTAKE.md` | Agent creates stories, epics, docs |
| Context assembly | `CONTEXT_RULES.md` | Agent loads phase-by-lane docs |
| Trace recording | `TRACE_SPEC.md` | Agent runs `harness-cli trace` |
| Verification | Story packets | Agent runs `harness-cli story verify` |
| Friction capture | `HARNESS.md` | Agent runs `harness-cli backlog add` |
| Decision recording | `HARNESS.md` | Agent runs `harness-cli decision add` |

Symphony observes outcomes (agent exit code, session events) but does not
participate in any of these processes.

## 4. Project Structure and Build Strategy

Symphony lives inside the `repository-harness` monorepo as an optional Cargo
workspace crate. This keeps the spec, CLI, and daemon in a single versioned
unit while allowing teams that don't need orchestration to skip it entirely.

### 4.1 Crate Layout

```
repository-harness/
  crates/
    harness-core/              ← shared library (types, db access, config)
      src/
        lib.rs
        db.rs                  ← harness.db reader (rusqlite)
        types.rs               ← WorkItem, IntakeRecord, TraceRecord, etc.
        config.rs              ← WORKFLOW.md parser, typed config
    harness-cli/               ← existing CLI binary
      src/
        main.rs
      Cargo.toml               ← depends on harness-core
    harness-symphony/          ← daemon binary (optional)
      src/
        main.rs                ← CLI entry (start, --tui, --port)
        orchestrator.rs        ← poll loop, dispatch, reconciliation
        source/
          mod.rs               ← WorkSource trait
          linear.rs            ← Linear adapter
        intake_router.rs       ← inline vs dedicated routing
        agent_runner.rs        ← Codex app-server client
        session.rs             ← live session tracking
      Cargo.toml               ← depends on harness-core
  scripts/bin/
    harness-cli                ← always shipped
    harness-symphony           ← shipped when built with symphony feature
  Cargo.toml                   ← workspace root
```

### 4.2 Dependency Graph

```
harness-symphony ──→ harness-core ←── harness-cli
       │                   │
       │                   ├── rusqlite (harness.db access)
       │                   └── serde, serde_yaml (config/types)
       │
       ├── tokio (async runtime, poll loop, timers)
       ├── reqwest (Linear API, future HTTP adapters)
       └── ratatui (optional, TUI dashboard)
```

`harness-core` is the shared library that both CLI and Symphony depend on.
It contains the types, database access, and config parsing that both need.
This prevents Symphony from reimplementing harness.db reading or duplicating
type definitions.

### 4.3 Feature Gating

The workspace `Cargo.toml` uses a feature flag so Symphony is opt-in:

```toml
[workspace]
members = ["crates/harness-core", "crates/harness-cli", "crates/harness-symphony"]
default-members = ["crates/harness-core", "crates/harness-cli"]
```

Build commands:

```bash
# Standard build (CLI only, no Symphony)
cargo build --release

# Full build (CLI + Symphony)
cargo build --release --workspace

# Symphony only
cargo build --release -p harness-symphony
```

### 4.4 Installation

The existing `scripts/install-harness.sh` gains an optional flag:

```bash
# Standard install (CLI + docs + templates)
./scripts/install-harness.sh

# Full install (CLI + docs + templates + Symphony daemon)
./scripts/install-harness.sh --with-symphony
```

When `--with-symphony` is passed, the installer also copies
`harness-symphony` to `scripts/bin/` and creates an example
`WORKFLOW.md` if one does not exist.

### 4.5 Future Extraction

If Symphony outgrows the monorepo (different release cadence, much larger
dependency tree, separate team), extracting it is straightforward:

1. Move `crates/harness-symphony/` to a new repo.
2. Point its `Cargo.toml` at `harness-core` as a git dependency.
3. The spec remains in `repository-harness/docs/SYMPHONY_SPEC.md` as the
   contract.

This is a one-way door that can be opened later — no need to decide now.

## 5. Core Domain Model

### 5.1 Entities

#### 5.1.1 Work Item

Normalized work record used by scheduling, prompt rendering, and observability.

Fields:

- `id` (string) — Stable source-internal ID.
- `identifier` (string) — Human-readable key (e.g., `MT-42`, `US-015`).
- `title` (string)
- `description` (string or null)
- `priority` (integer or null) — Lower = higher priority.
- `state` (string) — Current source state name.
- `source_kind` (string) — Which adapter produced this item.
- `labels` (list of strings) — Normalized to lowercase.
- `blocked_by` (list of blocker refs)
- `url` (string or null) — Link back to source.
- `intake_hint` (string or null) — OPTIONAL hint for intake routing
  (`inline` or `dedicated`). Source adapters MAY set this based on labels
  or item metadata.
- `created_at` (timestamp or null)
- `updated_at` (timestamp or null)

#### 5.1.2 Workflow Definition

Parsed `WORKFLOW.md` payload:

- `config` (map) — YAML front matter root object.
- `prompt_template` (string) — Markdown body after front matter, trimmed.

#### 5.1.3 Service Config (Typed View)

Typed runtime values derived from `WorkflowDefinition.config` plus environment
resolution. See Section 6.3 for the full schema.

#### 5.1.4 Run Attempt

One execution attempt for one work item.

Fields:

- `item_id`
- `item_identifier`
- `attempt` (integer or null — `null` for first run, `>=1` for retries)
- `mode` (`inline` | `intake`) — Whether this is an inline execution or a
  dedicated intake session.
- `started_at`
- `status`
- `error` (OPTIONAL)

#### 5.1.5 Live Session (Agent Session Metadata)

State tracked while a Codex subprocess is running:

- `session_id` (string, `<thread_id>-<turn_id>`)
- `thread_id`, `turn_id` (strings)
- `codex_app_server_pid` (string or null)
- `last_codex_event` (string or null)
- `last_codex_timestamp` (timestamp or null)
- `last_codex_message` (string)
- `codex_input_tokens`, `codex_output_tokens`, `codex_total_tokens` (integers)
- `turn_count` (integer)

#### 5.1.6 Retry Entry

- `item_id`
- `identifier`
- `attempt` (integer, 1-based)
- `due_at_ms` (monotonic timestamp)
- `timer_handle`
- `error` (string or null)

#### 5.1.7 Orchestrator Runtime State

Single authoritative in-memory state:

- `poll_interval_ms`
- `running` (map `item_id -> running entry`) — v1: at most one entry.
- `claimed` (set of item IDs)
- `retry_attempts` (map `item_id -> RetryEntry`)
- `completed` (set of item IDs, bookkeeping only)
- `codex_totals` (aggregate tokens + runtime seconds)

### 5.2 Stable Identifiers

- `Item ID` — Use for source lookups and internal map keys.
- `Item Identifier` — Use for human-readable logs.
- `Session ID` — `<thread_id>-<turn_id>`.

## 6. Workflow Specification (Repository Contract)

### 6.1 File Discovery

Workflow file path precedence:

1. Explicit CLI argument.
2. Default: `WORKFLOW.md` in the current working directory.

If the file cannot be read, return `missing_workflow_file` error.

### 6.2 File Format

`WORKFLOW.md` is a Markdown file with OPTIONAL YAML front matter.

Parsing rules (identical to [Symphony §5.2]):

- If file starts with `---`, parse until next `---` as YAML.
- Remaining lines become the prompt body.
- YAML front matter MUST decode to a map.
- Prompt body is trimmed.

### 6.3 Front Matter Schema

Top-level keys:

- `source` — Work source configuration (replaces `tracker` from original).
- `polling`
- `agent`
- `codex`
- `hooks`
- `intake`

Unknown keys SHOULD be ignored for forward compatibility.

#### 6.3.1 `source` (object)

Fields:

- `kind` (string, REQUIRED) — Work source adapter. Supported: `linear`.
  Future: `github`, `harness_backlog`.
- `endpoint` (string) — API endpoint.
  Default for `linear`: `https://api.linear.app/graphql`.
- `api_key` (string) — MAY be `$VAR_NAME` for environment indirection.
- `project_slug` (string) — REQUIRED when `kind == linear`.
- `required_labels` (list of strings) — Default: `[]`.
- `active_states` (list of strings) — Default: `["Todo", "In Progress"]`.
- `terminal_states` (list of strings) —
  Default: `["Closed", "Cancelled", "Canceled", "Duplicate", "Done"]`.

#### 6.3.2 `polling` (object)

- `interval_ms` (integer) — Default: `30000`.

#### 6.3.3 `agent` (object)

- `max_turns` (positive integer) — Default: `20`.
- `max_retry_backoff_ms` (integer) — Default: `300000` (5 minutes).

Note: `max_concurrent_agents` is omitted in v1 (single agent). It will be
added when concurrency support is introduced.

#### 6.3.4 `codex` (object)

- `command` (string) — Default: `codex app-server`.
- `approval_policy` — Implementation-defined.
- `turn_timeout_ms` (integer) — Default: `3600000` (1 hour).
- `read_timeout_ms` (integer) — Default: `5000`.
- `stall_timeout_ms` (integer) — Default: `300000` (5 minutes).

#### 6.3.5 `hooks` (object)

- `before_run` (shell script string, OPTIONAL) — Runs before each attempt.
- `after_run` (shell script string, OPTIONAL) — Runs after each attempt.
- `timeout_ms` (integer) — Default: `60000`.

Note: `after_create` and `before_remove` from original Symphony are omitted
because v1 does not create per-issue workspaces.

#### 6.3.6 `intake` (object)

- `dedicated_types` (list of strings) —
  Default: `["new_spec", "new_initiative"]`.
  Work items matching these input type labels receive a dedicated intake
  session before execution dispatch.
- `inline_types` (list of strings) —
  Default: `["spec_slice", "change_request", "maintenance_request",
  "harness_improvement"]`.
  Work items matching these are dispatched directly; the agent handles
  intake as its first step.
- `default_mode` (string) — `inline` | `dedicated`. Default: `inline`.
  Used when a work item doesn't match either list.

### 6.4 Prompt Template Contract

The Markdown body of `WORKFLOW.md` is the per-item prompt template.

Rendering requirements (identical to [Symphony §5.4]):

- Strict template engine (Liquid-compatible).
- Unknown variables MUST fail rendering.

Template input variables:

- `item` (object) — All normalized work item fields.
- `attempt` (integer or null) — `null` on first attempt.
- `mode` (string) — `inline` or `intake`.

RECOMMENDED prompt structure:

```markdown
You are working on {{ item.identifier }}: {{ item.title }}.

Follow AGENTS.md in this repository. It will direct you to the Harness
operating docs (FEATURE_INTAKE.md, CONTEXT_RULES.md, HARNESS.md, etc.).

{% if mode == "intake" %}
This is a DEDICATED INTAKE session. Your job is to:
1. Read FEATURE_INTAKE.md and classify this input.
2. Generate the appropriate work artifacts (stories, epics, product docs).
3. Record the intake via harness-cli.
4. Do NOT implement — only decompose and plan.
{% endif %}

{% if item.description %}
## Description

{{ item.description }}
{% endif %}

{% if attempt %}
This is retry attempt {{ attempt }}. Check your previous work and continue.
{% endif %}
```

### 6.5 Dynamic Reload

REQUIRED (identical to [Symphony §6.2]):

- Detect `WORKFLOW.md` changes and re-apply without restart.
- Invalid reloads keep last known good config and emit an error.

## 7. Work Source Adapter Contract

### 7.1 Adapter Interface

Every work source adapter MUST implement:

1. `fetch_candidates()` → list of WorkItem
   - Returns items in dispatchable states.
2. `fetch_states_by_ids(ids)` → list of WorkItem (minimal)
   - Used for reconciliation.
3. `fetch_terminal_items()` → list of WorkItem
   - Used for startup cleanup (if applicable).

### 7.2 Linear Adapter

The Linear adapter follows the original Symphony's tracker integration
contract [Symphony §11]:

- GraphQL endpoint, `Authorization` header, `project_slug` filter.
- Pagination REQUIRED, page size default 50.
- Normalization: labels lowercased, blockers from inverse `blocks` relations,
  priority as integer, timestamps parsed from ISO-8601.
- Candidate query filters by `active_states` and `required_labels`.

### 7.3 Harness Backlog Adapter

The `HarnessBacklogAdapter` reads dispatchable stories and accepted backlog
items directly from `harness.db` via `harness-cli query`. This is the native
work source for repos that generate their own work through Harness intake.

#### 7.3.1 Configuration

```yaml
source:
  kind: harness_backlog
  # Which story statuses are dispatchable (agent can work on them)
  active_statuses: ["planned", "in_progress"]
  # Which statuses mean "done, don't touch"
  terminal_statuses: ["implemented", "verified", "cancelled"]
  # Also dispatch accepted backlog improvement items
  include_backlog: false
  # Path to harness.db (default: repo root)
  db_path: harness.db
```

#### 7.3.2 Candidate Fetch

```text
function fetch_candidates():
  stories = harness-cli query sql "
    SELECT id, title, risk_lane, status, created_at
    FROM story
    WHERE status IN (active_statuses)
    ORDER BY created_at ASC
  "

  backlog = []
  if config.include_backlog:
    backlog = harness-cli query sql "
      SELECT id, title, status, created_at
      FROM backlog
      WHERE status = 'accepted'
      ORDER BY created_at ASC
    "

  return normalize_to_work_items(stories + backlog)
```

Normalization to `WorkItem`:

| harness.db field | WorkItem field | Notes |
|---|---|---|
| `story.id` | `id`, `identifier` | e.g., `US-015` |
| `story.title` | `title` | |
| (read from story file) | `description` | Content of `docs/stories/{id}-*.md` |
| `story.risk_lane` | `labels` | Added as label: `["normal"]` |
| `story.status` | `state` | |
| `"harness_backlog"` | `source_kind` | Constant |
| `null` | `url` | No external tracker link |
| (derived from input_type) | `intake_hint` | `new_spec`/`new_initiative` → `dedicated`; else `null` |

#### 7.3.3 State Refresh (Reconciliation)

```text
function fetch_states_by_ids(ids):
  return harness-cli query sql "
    SELECT id, title, risk_lane, status
    FROM story
    WHERE id IN (ids)
  "
```

If a story's status changed to a terminal status between poll cycles (e.g.,
human ran `harness-cli story update --status cancelled`), reconciliation will
stop the running agent.

#### 7.3.4 Story File Discovery

When constructing the prompt, the adapter reads the story packet file:

```text
function find_story_file(story_id):
  // Story files follow pattern: docs/stories/{ID}-{slug}.md
  // e.g., docs/stories/US-015-add-password-reset.md
  matches = glob("docs/stories/{story_id}-*.md")
  if matches.length == 1:
    return read_file(matches[0])
  if matches.length == 0:
    return null  // story has no packet file, prompt uses title only
  return read_file(matches[0])  // take first match
```

The story file contents are injected into the prompt via the `item.description`
template variable.

### 7.4 Future Adapters

- `GitHubAdapter` — Read from GitHub Issues/Projects.

The adapter interface MUST be designed to accommodate future sources.

### 7.5 Error Handling

- Candidate fetch failure → skip dispatch for this tick.
- State refresh failure → keep running agents, retry next tick.
- Terminal fetch failure → log warning, continue startup.

## 8. Intake Router

### 8.1 Purpose

The intake router examines each candidate work item and decides whether it
should be dispatched directly (inline intake) or requires a dedicated intake
session first (for complex inputs that generate multiple stories).

### 8.2 Routing Logic

```text
function route_intake(item, config):
  if item.intake_hint is not null:
    return item.intake_hint  // source adapter override

  if any label in item.labels matches config.intake.dedicated_types:
    return "dedicated"

  if any label in item.labels matches config.intake.inline_types:
    return "inline"

  return config.intake.default_mode
```

### 8.3 Dedicated Intake Sessions

When a work item is routed to `dedicated` mode:

1. Symphony launches a Codex session with `mode: "intake"` in the prompt
   template variables.
2. The prompt instructs the agent to ONLY do intake (classify, generate
   stories, record intake) — not implement.
3. The agent reads `FEATURE_INTAKE.md`, classifies the input type, runs the
   risk checklist, and generates work artifacts (story packets, epic folders,
   product docs).
4. The agent records the intake via `harness-cli intake`.
5. Generated stories are written to `docs/stories/` in the repo.
6. On the next poll cycle, if a `HarnessBacklogAdapter` is configured, new
   stories become dispatchable work items. Otherwise, the operator manually
   creates tracker tickets for generated stories.

### 8.4 Inline Intake

When a work item is routed to `inline` mode:

1. Symphony launches a Codex session with `mode: "inline"`.
2. The agent does intake as its first step (classify, record, then work).
3. This is the default Harness model — one session handles everything.

## 9. Orchestrator State Machine

### 9.1 Work Item Orchestration States

Internal claim states (not tracker states):

1. `Unclaimed` — Not running, no retry scheduled.
2. `Claimed` — Reserved to prevent duplicate dispatch.
3. `Running` — Worker task exists.
4. `RetryQueued` — Retry timer pending.
5. `Released` — Claim removed (terminal, ineligible, or retries exhausted).

### 9.2 Run Attempt Lifecycle

1. `BuildingPrompt`
2. `LaunchingAgent`
3. `InitializingSession`
4. `StreamingTurn`
5. `Finishing`
6. `Succeeded`
7. `Failed`
8. `TimedOut`
9. `Stalled`
10. `CanceledByReconciliation`

### 9.3 Transition Triggers

Identical semantics to [Symphony §7.3]:

- `Poll Tick` → reconcile, validate, fetch, dispatch.
- `Worker Exit (normal)` → schedule continuation retry.
- `Worker Exit (abnormal)` → schedule exponential-backoff retry.
- `Codex Update Event` → update session metadata.
- `Retry Timer Fired` → re-check eligibility, re-dispatch or release.
- `Reconciliation Refresh` → stop runs whose items are terminal/inactive.
- `Stall Timeout` → kill worker, schedule retry.

## 10. Polling, Scheduling, and Reconciliation

### 10.1 Poll Loop

At startup: validate config, schedule immediate tick, repeat every
`polling.interval_ms`.

Tick sequence:

1. Reconcile running items (stall detection + state refresh).
2. Validate dispatch config.
3. Fetch candidates from work source adapter.
4. Route each candidate through the intake router.
5. Dispatch eligible items while slots remain (v1: 1 slot).
6. Emit logs.

### 10.2 Candidate Selection Rules

A work item is dispatch-eligible only if:

- It has `id`, `identifier`, `title`, and `state`.
- Its state is in `active_states` and not in `terminal_states`.
- Required labels are present.
- It is not already `claimed` or `running`.
- A slot is available (v1: the single slot is free).
- Blocker rule: `Todo`-state items with non-terminal blockers are skipped.

Sorting: `priority` ascending → `created_at` oldest first → `identifier`
lexicographic.

### 10.3 Retry and Backoff

Identical to [Symphony §8.4]:

- Normal continuation: `1000 ms` fixed delay.
- Failure: `min(10000 * 2^(attempt - 1), max_retry_backoff_ms)`.

### 10.4 Reconciliation

Identical to [Symphony §8.5]:

- Part A: Stall detection using `stall_timeout_ms`.
- Part B: State refresh via adapter — terminal → stop + cleanup,
  active → update snapshot, other → stop without cleanup.

## 11. Agent Runner Protocol (Codex Integration)

### 11.1 Launch Contract

- Command: `codex.command` (default `codex app-server`).
- Invocation: `bash -lc <command>`.
- Working directory: the Harness-governed repository root.
- Transport: targeted Codex app-server protocol over stdio.

Note: v1 runs the agent in the repository root, NOT in a per-issue workspace
directory. The agent operates on the single repo clone.

### 11.2 Session Startup

Follows the targeted Codex app-server protocol [Symphony §10.2].

Symphony MUST:

- Initialize the session in the repo directory.
- Start the first turn with the rendered prompt.
- Start continuation turns with continuation guidance (not the full prompt).
- Extract `thread_id` and `turn_id` for session tracking.

### 11.3 Streaming Turn Processing

Identical to [Symphony §10.3]:

- Process events until turn terminates.
- Completion conditions: protocol success/failure/cancellation, turn timeout,
  subprocess exit.
- Continuation: start another turn on the same thread if still eligible.

### 11.4 Emitted Events

Key events forwarded to orchestrator:

- `session_started`, `turn_completed`, `turn_failed`, `turn_cancelled`
- `turn_input_required`, `notification`, `malformed`

### 11.5 Approval and Tool Policy

Implementation-defined [Symphony §10.5]. Each implementation MUST document its
posture. Runs MUST NOT stall indefinitely on approval or input requests.

### 11.6 Timeouts

- `codex.read_timeout_ms` — startup/sync timeout.
- `codex.turn_timeout_ms` — per-turn timeout.
- `codex.stall_timeout_ms` — enforced by orchestrator on event inactivity.

## 12. Execution Walkthrough

This section traces a concrete end-to-end example: a story in `harness.db`
gets picked up by Symphony, dispatched to Codex app-server, worked on, and
completed. It also explains what Codex app-server is and how it differs from
the Codex CLI you would use manually.

### 12.1 Codex CLI vs Codex app-server

These are two interfaces to the **same Codex agent brain**. The difference is
who controls it.

**Codex CLI** — interactive terminal tool, human-driven:

```bash
# You, the human, type this in your terminal:
$ codex "Fix the authentication bug in auth.rs"

# Codex runs interactively:
#   - You see its output in your terminal
#   - You may approve/reject file writes
#   - It finishes, you read the result
#   - You manually decide what to work on next
```

**Codex app-server** — headless subprocess, program-driven:

```bash
# Symphony spawns this as a child process:
$ codex app-server

# Now Codex sits waiting for JSON-RPC messages over stdin.
# No terminal UI. No human approving actions.
# A program (Symphony) sends structured messages and reads events.
```

The relationship:

```
┌──────────────────────────────────────────────────────────────┐
│                     CODEX (the agent brain)                    │
│                                                                │
│  Same model, same reasoning, same tool use, same code edits   │
│                                                                │
│  ┌──────────────────┐          ┌───────────────────────────┐  │
│  │   CLI interface   │          │   app-server interface     │  │
│  │                   │          │                            │  │
│  │  Human types      │          │  Program sends JSON-RPC    │  │
│  │  prompt in        │          │  messages over stdin/stdout │  │
│  │  terminal         │          │                            │  │
│  │                   │          │  Program reads structured   │  │
│  │  Human reads      │          │  events back               │  │
│  │  output on        │          │                            │  │
│  │  screen           │          │  No human in the loop —    │  │
│  │                   │          │  approval policy is         │  │
│  │  Human approves   │          │  "auto-edit" (configured    │  │
│  │  or rejects       │          │   in WORKFLOW.md)           │  │
│  └──────────────────┘          └───────────────────────────┘  │
│                                                                │
│  The agent does IDENTICAL work in both modes:                  │
│  reads AGENTS.md, follows Harness, writes code, runs tests.   │
└──────────────────────────────────────────────────────────────┘
```

Key insight: **Symphony replaces the human operator, not the agent.** The agent
does the same work either way — reads the same docs, runs the same CLI commands,
follows the same Harness protocol. The only difference is who picks the task and
types the prompt.

### 12.2 Concrete Example: Story US-015, harness.db → Done

#### Phase 0: Story Exists in harness.db

Someone (human or a previous intake agent session) created the story:

```bash
$ harness-cli story add --id US-015 --title "Add password reset flow" --lane normal
```

This wrote:
- A row in `harness.db`: `story(id=US-015, title="Add password reset flow", risk_lane=normal, status=planned)`
- A story file: `docs/stories/US-015-add-password-reset.md` (with acceptance criteria, verification commands, etc.)

#### Phase 1: Symphony Polls harness.db

Symphony is running as a daemon:

```bash
$ harness-symphony start --workflow WORKFLOW.md
```

The `WORKFLOW.md` is configured with `source.kind: harness_backlog`. Every 30
seconds (configurable), the poll tick fires. The `HarnessBacklogAdapter` queries:

```sql
SELECT id, title, risk_lane, status, created_at
FROM story
WHERE status IN ('planned', 'in_progress')
ORDER BY created_at ASC
```

Result: `[{id: "US-015", title: "Add password reset flow", lane: "normal", status: "planned"}]`

#### Phase 2: Dispatch Decision

The orchestrator checks:

```text
1. Is US-015 already claimed?        → No
2. Is a slot available? (v1: 1 slot) → Yes (nothing running)
3. Does it pass eligibility rules?   → Yes (has id, title, state; not blocked)
4. Intake routing?                   → "inline" (normal story, not new_spec/new_initiative)
```

Decision: **dispatch US-015 in inline mode.**

The orchestrator updates its in-memory state:

```text
state.claimed = {"US-015"}
state.running = {"US-015": {worker: ..., mode: "inline", started_at: now()}}
```

#### Phase 3: Prompt Construction

Symphony reads the story file (`docs/stories/US-015-add-password-reset.md`) and
renders the `WORKFLOW.md` prompt template:

```text
Template variables:
  item.identifier = "US-015"
  item.title = "Add password reset flow"
  item.description = (contents of docs/stories/US-015-add-password-reset.md)
  mode = "inline"
  attempt = null  (first attempt)
```

Rendered prompt:

```
You are working on US-015: Add password reset flow.

Follow AGENTS.md in this repository. It will direct you to the Harness
operating docs for intake classification, context loading, and trace recording.

## Work Item

[full contents of docs/stories/US-015-add-password-reset.md]
```

#### Phase 4: Codex app-server Subprocess Launch

Symphony spawns the app-server as a child process:

```text
Command:  bash -lc "codex app-server"
Cwd:      /path/to/repository-harness
Stdin:    piped (Symphony writes JSON-RPC messages here)
Stdout:   piped (Symphony reads JSON-RPC events here)
Stderr:   captured for diagnostics
```

The subprocess starts and waits for messages.

#### Phase 5: Session Initialization (JSON-RPC over stdio)

Symphony sends structured messages to the app-server. The exact message
format follows the targeted Codex app-server protocol version (this spec
does not hardcode protocol schemas — see Section 11). Conceptually:

```text
Symphony → app-server (stdin):
  Initialize session
    cwd: "/path/to/repository-harness"
    approval_policy: "auto-edit"        ← from WORKFLOW.md codex config
    sandbox: (from WORKFLOW.md)
    
Symphony → app-server (stdin):
  Start turn
    prompt: "You are working on US-015: Add password reset flow. ..."
    
app-server → Symphony (stdout):
  { event: "session_started", thread_id: "thr_abc123" }
```

Symphony records: `session_id = "thr_abc123-turn_1"`

#### Phase 6: Agent Executes (This Is Where the Real Work Happens)

Inside the app-server, Codex is now running with the prompt. From here, **the
agent behaves exactly as it would if you typed the prompt into Codex CLI.**
Symphony has no involvement in what happens next — it just monitors events.

The agent autonomously:

```text
1. Reads AGENTS.md
   → Learns this is a Harness repo
   → Directed to read docs/HARNESS.md, docs/FEATURE_INTAKE.md, etc.

2. Reads docs/FEATURE_INTAKE.md
   → Classifies: input_type = "spec_slice", risk_lane = "normal"
   → Runs: harness-cli intake --type spec_slice \
           --summary "Password reset flow" --lane normal

3. Reads docs/CONTEXT_RULES.md
   → Phase = implementation, lane = normal
   → Loads: ARCHITECTURE.md, relevant product docs, story packet

4. Does the actual work
   → Reads the story acceptance criteria
   → Writes code (controllers, views, tests)
   → Runs existing test suite
   → Creates git branch, commits changes

5. Records trace
   → Runs: harness-cli trace --story US-015 \
           --summary "Implemented password reset with email flow" \
           --outcome completed

6. Runs verification
   → Runs: harness-cli story verify US-015
   → Verification command from story packet executes
   → If passes: story status → "implemented"

7. Records friction (if any)
   → Runs: harness-cli backlog add --title "Auth docs unclear" \
           --source friction
```

While this happens, the app-server streams events to Symphony:

```text
app-server → Symphony (stdout):
  { event: "notification", message: "Reading AGENTS.md..." }
  { event: "notification", message: "Running harness-cli intake..." }
  { event: "notification", message: "Creating password reset controller..." }
  { event: "notification", message: "Running test suite..." }
  { event: "turn_completed", usage: { input: 15000, output: 9000, total: 24000 } }
```

Symphony updates its tracking: token counts, last event timestamp, etc.

#### Phase 7: Turn Completion

The app-server signals `turn_completed`. Symphony now decides:

```text
1. Was this a success?            → Yes (turn_completed, not turn_failed)
2. Has the item gone terminal?    → Check: harness.db shows US-015 status = "implemented"
3. More turns needed?             → No (work is done, status is terminal)
```

Symphony:
- Stops the app-server subprocess
- Runs `after_run` hook (e.g., `harness-cli audit || true`)
- Releases the claim: `state.claimed.remove("US-015")`
- Adds to completed: `state.completed.add("US-015")`
- Frees the slot

#### Phase 8: Next Poll Cycle

30 seconds later, Symphony polls again:

```sql
SELECT ... FROM story WHERE status IN ('planned', 'in_progress')
```

US-015 no longer appears (it's `implemented`). If US-016 exists and is
`planned`, the cycle repeats for that story.

### 12.3 What Happens on Failure

If the agent fails (turn_failed, timeout, subprocess crash):

```text
1. Symphony catches the failure event or detects stall
2. Kills the app-server subprocess
3. Queues a retry:
     attempt = 1
     delay = min(10000 * 2^0, max_retry_backoff_ms) = 10 seconds
4. When retry timer fires:
     - Re-checks: is US-015 still in an active status?
     - If yes: re-dispatches with attempt=1 in the prompt template
     - The retry prompt includes "This is continuation attempt 1.
       Review previous work and continue."
5. On second failure: delay = 20 seconds, attempt = 2
6. Continues until max_retry_backoff_ms ceiling
```

### 12.4 Side-by-Side: Manual vs Symphony

```
┌───────────────────────────────────┬────────────────────────────────────┐
│  TODAY (Codex CLI, manual)        │  WITH SYMPHONY (Codex app-server)  │
├───────────────────────────────────┼────────────────────────────────────┤
│                                   │                                    │
│  1. Human looks at backlog        │  1. Symphony polls harness.db      │
│     $ harness-cli query stories   │     (automatic, every 30s)         │
│                                   │                                    │
│  2. Human picks a story           │  2. Symphony picks next planned    │
│     "I'll work on US-015"         │     story (priority + age sort)    │
│                                   │                                    │
│  3. Human reads story file        │  3. Symphony reads story file      │
│     $ cat docs/stories/US-015-*   │     and injects into prompt        │
│                                   │                                    │
│  4. Human types in terminal:      │  4. Symphony sends via JSON-RPC:   │
│     $ codex "Work on US-015..."   │     {prompt: "Work on US-015..."}  │
│                                   │                                    │
│  5. Human watches output          │  5. Symphony monitors events       │
│     and may approve actions       │     (auto-edit, no human needed)   │
│                                   │                                    │
│  6. Codex does the work           │  6. Codex does the SAME work       │
│     - reads AGENTS.md             │     - reads AGENTS.md              │
│     - follows Harness             │     - follows Harness              │
│     - writes code, tests          │     - writes code, tests           │
│     - runs harness-cli            │     - runs harness-cli             │
│                                   │                                    │
│  7. Human checks result           │  7. Symphony reads turn_completed  │
│     "Did it pass verify?"         │     Checks story status in db      │
│                                   │                                    │
│  8. If failed, human retries      │  8. If failed, Symphony retries    │
│     "Try again..."                │     with exponential backoff       │
│                                   │                                    │
│  9. Human picks next story        │  9. Symphony picks next story      │
│     (go back to step 1)           │     (automatic, next poll cycle)   │
│                                   │                                    │
│  ─── Human is the scheduler ───   │  ─── Symphony is the scheduler ── │
│  ─── Codex is the worker    ───   │  ─── Codex is the SAME worker ─── │
└───────────────────────────────────┴────────────────────────────────────┘
```

### 12.5 What Symphony Controls vs What the Agent Controls

```
┌─────────────────────────────┬──────────────────────────────────────┐
│  SYMPHONY (the scheduler)   │  AGENT (Codex in the repo)           │
├─────────────────────────────┼──────────────────────────────────────┤
│                             │                                      │
│  Which story to work on     │  How to classify the work (intake)   │
│  When to start the agent    │  Which docs to read (context rules)  │
│  The initial prompt         │  What code to write                  │
│  When to retry              │  What tests to run                   │
│  When to stop (timeout)     │  Whether to record a trace           │
│  Subprocess lifecycle       │  Whether verification passed         │
│  Token accounting           │  Whether to record friction          │
│  Slot management            │  Git operations (branch, commit, PR) │
│                             │  harness-cli invocations             │
│                             │                                      │
│  Knows: is the agent alive? │  Knows: is the work correct?         │
│  Doesn't know: what the     │  Doesn't know: that Symphony exists  │
│  agent is actually doing    │  (just follows AGENTS.md)            │
└─────────────────────────────┴──────────────────────────────────────┘
```

The agent doesn't know or care that Symphony launched it. It just sees a
prompt and a repo with Harness docs. It would behave identically if a human
typed the same prompt into Codex CLI.

## 13. Observability

### 12.1 Logging

REQUIRED context fields for item-related logs:

- `item_id`, `item_identifier`, `source_kind`

REQUIRED context for session logs:

- `session_id`

### 12.2 Token Accounting

Identical to [Symphony §13.5]:

- Prefer absolute thread totals.
- Track deltas to avoid double-counting.
- Accumulate in orchestrator state.

### 12.3 TUI Dashboard (OPTIONAL, future)

When `--tui` flag is provided:

- Display active sessions, retry queue, aggregate totals.
- Keyboard controls for pause/resume/force-retry.
- Driven from orchestrator state only — MUST NOT affect correctness.

### 12.4 HTTP API (OPTIONAL, future)

When `--port <N>` is provided:

- `GET /api/v1/state` — runtime snapshot.
- `GET /api/v1/<identifier>` — item-specific debug details.
- `POST /api/v1/refresh` — trigger immediate poll.

## 14. Failure Model and Recovery

### 14.1 Failure Classes

1. `Workflow/Config` — Missing `WORKFLOW.md`, invalid YAML, missing source
   credentials.
2. `Agent Session` — Startup failure, turn failure/timeout/cancellation,
   stall, subprocess exit.
3. `Work Source` — API errors, auth failures, malformed payloads.
4. `Observability` — Log sink failure (non-fatal).

### 14.2 Recovery Behavior

- Config failures → skip dispatch, keep service alive.
- Agent failures → retry with exponential backoff.
- Source failures → skip this tick, retry next.
- Observability failures → do not crash orchestrator.

### 14.3 Restart Recovery

State is in-memory. After restart:

- No retry timers restored.
- No running sessions assumed recoverable.
- Recovery by: fresh polling + re-dispatch of eligible items.

## 15. Security and Safety

### 15.1 Trust Boundary

Implementation-defined [Symphony §15.1]. Each implementation MUST document
whether it targets trusted or restrictive environments.

### 15.2 Filesystem Safety

- Agent cwd MUST be the repository root.
- Repository path MUST be validated as a real directory before agent launch.

### 15.3 Secret Handling

- Support `$VAR` indirection in workflow config.
- Do not log API tokens or secret values.

### 15.4 Hook Safety

- Hooks are trusted config from `WORKFLOW.md`.
- Hooks run in the repo directory.
- Hook timeouts are REQUIRED.

## 16. Reference Algorithms

### 16.1 Service Startup

```text
function start_service():
  configure_logging()
  start_workflow_watch(on_change=reload_workflow)

  state = {
    poll_interval_ms: config.polling.interval_ms,
    running: {},
    claimed: set(),
    retry_attempts: {},
    completed: set(),
    codex_totals: {input: 0, output: 0, total: 0, seconds: 0}
  }

  validate_config() or fail_startup()
  schedule_tick(delay_ms=0)
  event_loop(state)
```

### 16.2 Poll-and-Dispatch Tick

```text
on_tick(state):
  state = reconcile(state)

  if validate_config() fails:
    log_error(); schedule_tick(); return state

  items = source_adapter.fetch_candidates()
  if items failed:
    log_error(); schedule_tick(); return state

  for item in sort_for_dispatch(items):
    if no_available_slots(state):
      break
    if should_dispatch(item, state):
      mode = route_intake(item, config)
      state = dispatch_item(item, state, attempt=null, mode=mode)

  schedule_tick(state.poll_interval_ms)
  return state
```

### 16.3 Dispatch One Item

```text
function dispatch_item(item, state, attempt, mode):
  worker = spawn_worker(
    fn -> run_agent(item, attempt, mode)
  )

  if spawn failed:
    return schedule_retry(state, item.id, ...)

  state.running[item.id] = {
    worker, identifier: item.identifier,
    item, mode, session_id: null,
    tokens: {0,0,0}, started_at: now()
  }
  state.claimed.add(item.id)
  return state
```

### 16.4 Worker Attempt

```text
function run_agent(item, attempt, mode):
  if run_hook("before_run") failed:
    fail_worker("before_run hook error")

  session = codex.start_session(cwd=repo_root)
  if session failed:
    run_hook_best_effort("after_run")
    fail_worker("session startup error")

  max_turns = config.agent.max_turns
  turn = 1

  while true:
    prompt = render_prompt(item, attempt, mode, turn, max_turns)
    result = codex.run_turn(session, prompt)

    if result failed:
      codex.stop(session)
      run_hook_best_effort("after_run")
      fail_worker("turn error")

    refreshed = source_adapter.fetch_states_by_ids([item.id])
    if refreshed.state is not active:
      break
    if turn >= max_turns:
      break
    turn += 1

  codex.stop(session)
  run_hook_best_effort("after_run")
  exit_normal()
```

### 16.5 Worker Exit Handling

```text
on_worker_exit(item_id, reason, state):
  entry = state.running.remove(item_id)
  state = add_runtime_to_totals(state, entry)

  if reason == normal:
    state.completed.add(item_id)
    state = schedule_retry(state, item_id, 1, continuation)
  else:
    state = schedule_retry(state, item_id, next_attempt(entry), error)

  return state
```

## 17. Implementation Checklist

### 17.1 REQUIRED for v1 Conformance

- [ ] `harness-core` crate with shared types, db access, config parsing
- [ ] `harness-symphony` crate as optional workspace member
- [ ] Workflow file loader with YAML front matter + prompt body
- [ ] Config layer with defaults and `$VAR` resolution
- [ ] Dynamic `WORKFLOW.md` watch/reload
- [ ] Work source adapter trait (`WorkSource`)
- [ ] Linear adapter (candidate fetch + state refresh + terminal fetch)
- [ ] Harness backlog adapter (read stories/backlog from `harness.db`)
- [ ] Intake router (inline vs dedicated mode dispatch)
- [ ] Polling orchestrator with single-authority state
- [ ] Single-slot dispatch (one agent at a time)
- [ ] Codex app-server subprocess client
- [ ] Strict prompt rendering with `item`, `attempt`, `mode` variables
- [ ] Retry queue with exponential backoff + continuation retries
- [ ] Reconciliation (stall detection + state refresh)
- [ ] Structured logs with `item_id`, `item_identifier`, `session_id`
- [ ] `before_run` and `after_run` hooks with timeout
- [ ] `install-harness.sh --with-symphony` flag

### 17.2 RECOMMENDED Extensions (v2+)

- [ ] Multi-agent concurrency with shared-state strategy
- [ ] TUI dashboard (`--tui`)
- [ ] HTTP API (`--port`)
- [ ] GitHub Issues adapter
- [ ] SSH worker extension for remote execution
- [ ] Persistent retry queue across restarts

### 17.3 Operational Validation

- [ ] Run with valid Linear credentials end-to-end
- [ ] Verify hook execution on target OS
- [ ] Verify `WORKFLOW.md` reload applies without restart

## 18. Interaction with Harness Lifecycle

This section documents how the Harness protocol plays out inside a
Symphony-launched agent session, for implementor reference. Symphony does NOT
enforce any of these steps — the agent follows them autonomously.

### 18.1 Inline Mode Session

```text
Agent starts in repo with rendered prompt containing work item.
  1. Agent reads AGENTS.md → directed to Harness docs.
  2. Agent reads FEATURE_INTAKE.md → classifies input type + risk lane.
  3. Agent records: harness-cli intake --type X --summary "..." --lane Y.
  4. Agent reads CONTEXT_RULES.md → loads docs per phase + lane.
  5. Agent does the work (code, tests, docs).
  6. Agent records: harness-cli trace --summary "..." --outcome completed.
  7. Agent runs: harness-cli story verify <id> (if applicable).
  8. Agent records friction: harness-cli backlog add (if encountered).
  9. Agent exits.
```

### 18.2 Dedicated Intake Mode Session

```text
Agent starts in repo with intake-mode prompt.
  1. Agent reads AGENTS.md → directed to Harness docs.
  2. Agent reads FEATURE_INTAKE.md → classifies input type.
  3. Agent generates work artifacts:
     - For new_spec: product docs, candidate epics, architecture questions.
     - For new_initiative: initiative notes, candidate story packets.
  4. Agent writes artifacts to docs/stories/, docs/product/, etc.
  5. Agent records: harness-cli intake --type new_spec --summary "...".
  6. Agent records: harness-cli story add (for each generated story).
  7. Agent exits. Generated stories are now in the repo and harness.db.
```

The scheduler picks up generated stories on the next cycle (if using a
Harness backlog adapter) or the operator creates tracker tickets for them.

### 18.3 Cross-Run Intelligence

After N agent runs, accumulated data in `harness.db` supports:

- `harness-cli audit` → entropy/drift score.
- `harness-cli propose` → improvement proposals from friction patterns.
- `harness-cli query friction` → repeated pain points.
- `harness-cli query traces` → execution patterns.

These can be run manually, via cron, or by a future intelligence service
extension. Symphony does not run them automatically in v1.

## Appendix A. Example WORKFLOW.md (Linear Source)

```yaml
---
source:
  kind: linear
  api_key: $LINEAR_API_KEY
  project_slug: harness-demo
  active_states: ["Todo", "In Progress"]
  terminal_states: ["Done", "Cancelled"]

polling:
  interval_ms: 30000

agent:
  max_turns: 20
  max_retry_backoff_ms: 300000

codex:
  command: codex app-server
  approval_policy: auto-edit
  turn_timeout_ms: 3600000
  stall_timeout_ms: 300000

hooks:
  before_run: |
    git fetch origin
    git checkout -B work/$ITEM_IDENTIFIER origin/main
  after_run: |
    harness-cli audit || true

intake:
  dedicated_types: ["new_spec", "new_initiative"]
  default_mode: inline
---
You are working on {{ item.identifier }}: {{ item.title }}.

Follow AGENTS.md in this repository. It will direct you to the Harness
operating docs for intake classification, context loading, and trace recording.

{% if mode == "intake" %}
## Intake Mode

This is a DEDICATED INTAKE session. Your job is to:
1. Read docs/FEATURE_INTAKE.md and classify this input.
2. Generate the appropriate work artifacts (stories, epics, product docs).
3. Record the intake via harness-cli intake.
4. Do NOT implement code — only decompose and plan.
{% endif %}

{% if item.description %}
## Work Item

{{ item.description }}
{% endif %}

{% if attempt %}
This is continuation attempt {{ attempt }}. Review previous work and continue
from where you left off.
{% endif %}
```

## Appendix A2. Example WORKFLOW.md (Harness Backlog Source)

This configuration uses `harness.db` as the work source instead of an external
tracker. Stories and backlog items created via `harness-cli` are automatically
dispatched to agents.

```yaml
---
source:
  kind: harness_backlog
  active_statuses: ["planned", "in_progress"]
  terminal_statuses: ["implemented", "verified", "cancelled"]
  include_backlog: false
  db_path: harness.db

polling:
  interval_ms: 30000

agent:
  max_turns: 20
  max_retry_backoff_ms: 300000

codex:
  command: codex app-server
  approval_policy: auto-edit
  turn_timeout_ms: 3600000
  stall_timeout_ms: 300000

hooks:
  before_run: |
    git fetch origin
    git checkout -B work/$ITEM_IDENTIFIER origin/main
  after_run: |
    harness-cli audit || true

intake:
  dedicated_types: ["new_spec", "new_initiative"]
  default_mode: inline
---
You are working on {{ item.identifier }}: {{ item.title }}.

Follow AGENTS.md in this repository. It will direct you to the Harness
operating docs for intake classification, context loading, and trace recording.

Your story packet is at: docs/stories/{{ item.identifier }}-*.md
Read it before starting implementation.

{% if mode == "intake" %}
## Intake Mode

This is a DEDICATED INTAKE session. Your job is to:
1. Read docs/FEATURE_INTAKE.md and classify this input.
2. Generate the appropriate work artifacts (stories, epics, product docs).
3. Record the intake via harness-cli intake.
4. Do NOT implement code — only decompose and plan.
{% endif %}

{% if item.description %}
## Work Item

{{ item.description }}
{% endif %}

{% if attempt %}
This is continuation attempt {{ attempt }}. Review previous work and continue
from where you left off.
{% endif %}
```

Usage:

```bash
# 1. Create stories (human or intake agent)
$ harness-cli story add --id US-015 --title "Add password reset flow" --lane normal
$ harness-cli story add --id US-016 --title "Fix email validation" --lane tiny

# 2. Start Symphony — it picks up planned stories automatically
$ harness-symphony start --workflow WORKFLOW.md

# 3. Symphony dispatches US-015, then US-016 when done
# Each agent follows AGENTS.md, records traces, runs verification

# 4. Check results
$ harness-cli query stories    # see updated statuses
$ harness-cli query traces     # see execution records
$ harness-cli query friction   # see what agents struggled with
```

## Appendix B. Glossary Additions

- **Work Source** — Pluggable adapter that fetches dispatchable work items
  (Linear issues, GitHub issues, Harness stories/backlog items).
- **Intake Router** — Component that decides whether a work item needs a
  dedicated intake session or can be dispatched directly for inline intake.
- **Inline Intake** — The agent handles intake classification as its first
  step within the same session that does the work.
- **Dedicated Intake** — A separate agent session that only does intake
  (classify, decompose, generate stories) without implementing.
- **Harness Protocol** — The set of behaviors an agent follows by reading
  Harness docs (AGENTS.md, FEATURE_INTAKE.md, CONTEXT_RULES.md, etc.).
  Not enforced by the orchestrator.
- **Codex app-server** — Headless subprocess mode of Codex that accepts
  JSON-RPC commands over stdio. Same agent brain as the Codex CLI, but
  controlled programmatically by Symphony instead of by a human.
- **Harness Backlog Adapter** — Work source adapter that reads dispatchable
  stories and backlog items from `harness.db` instead of an external tracker.

## Appendix C. Migration from v1 Spec

The previous draft (v1) made several assumptions corrected by the audit:

| v1 Assumption | v2 Correction |
|---|---|
| Orchestrator classifies intake | Agent classifies intake autonomously |
| Per-story workspaces with own harness.db | Single repo clone, shared harness.db |
| Orchestrator assembles context per lane | Agent follows CONTEXT_RULES.md |
| Orchestrator runs verification gates | Agent runs harness-cli story verify |
| Lane → Codex approval policy mapping | Orthogonal concerns, not coupled |
| Orchestrator state in harness.db | In-memory state (scheduler ≠ ops memory) |
| Full Symphony complexity (100+ agents) | Single agent v1, concurrency deferred |
| Linear-only work source | Pluggable adapter interface |
