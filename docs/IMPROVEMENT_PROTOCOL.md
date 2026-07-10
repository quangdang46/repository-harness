# Improvement Protocol

Phase 5 starts the self-improvement loop:

```text
friction + interventions + audit findings
  -> harness-cli propose
  -> human accepts or rejects one stable proposal key
  -> accepted backlog occurrence plus outcome-review schedule
  -> implementation with predicted impact
  -> close with implementation proof
  -> later append measured outcome observations
```

## Generate Proposals

```bash
scripts/bin/harness-cli propose
```

The command is rule-based. It looks for:

- repeated trace friction,
- repeated intervention patterns,
- non-zero audit categories.

Each proposal includes a stable versioned key, lifecycle state, title, component,
evidence, predicted impact, risk, suggested action, validation plan, and
confidence. Running `propose` without a decision flag is read-only.

Lifecycle state is evidence-aware:

- `new`: no keyed occurrence exists.
- `pending`: a proposed occurrence already exists; the existing backlog id is
  shown.
- `accepted`: active work already exists and a second open occurrence cannot be
  created.
- `suppressed`: an implemented or rejected occurrence covers all current stable
  evidence. These rows are hidden by default.
- `regression`: evidence not covered by the occurrence lineage appeared after an
  implemented occurrence.
- `reconsideration`: evidence not covered by the occurrence lineage appeared
  after a rejected occurrence.

Inspect handled evidence without reopening it:

```bash
scripts/bin/harness-cli propose --show-suppressed
```

The explanation includes the terminal occurrence, resolver, closure proof, and
why no evidence remains uncovered. Plausible unkeyed legacy matches are reported
as `legacy-unclassified` and left for explicit US-080 reconciliation.

## Decide One Proposal

```bash
scripts/bin/harness-cli propose --accept <proposal-key> --outcome-manual
scripts/bin/harness-cli propose --accept <proposal-key> --outcome-due <RFC3339>
scripts/bin/harness-cli propose --accept <proposal-key> --outcome-after-traces <positive-integer>

# Or retain a terminal human decision without creating implementation work.
scripts/bin/harness-cli propose --reject <proposal-key> --reason "Not worth the added complexity"
```

Acceptance creates or reuses one `accepted` backlog occurrence and prints the
next `harness_improvement` intake command. Rejection records one terminal reason
and covered evidence without creating an intake, story, or Symphony run.
`propose --commit` is intentionally rejected; Harness never bulk-writes every
currently displayed suggestion.

Accepting or rejecting a `regression` or `reconsideration` candidate appends a
new occurrence with a new uid, the same proposal key, the immediately prior
terminal occurrence as `predecessor_uid`, and only the uncovered stable evidence.
The predecessor is never reopened or mutated. Recurrence candidates remain
read-only until this explicit human decision.

Humans review accepted work with:

```bash
scripts/bin/harness-cli query backlog --open
```

## Run The Daily Health Loop

Start with the read-only health view:

```bash
scripts/bin/harness-cli audit --record-evidence
scripts/bin/harness-cli query improvement-health
```

The first command explicitly records audit-evidence transitions. The second
command writes nothing: it combines the current audit entropy, proposal
decisions, accepted work, scheduled outcome reviews, measured outcomes, and
recurrence candidates in deterministic order. Each row gives the exact next
operator action.

For example, an implemented occurrence with a trace-count schedule of 20 and a
completion baseline of 100 is `scheduled_not_due` at 112 uid-bearing traces
with 8 remaining. At 120 traces it becomes `due`. If the current count is 99,
the row is `schedule_error` because Harness refuses to guess after the durable
count moves below its baseline.

## Complete Accepted Work

After implementation, the resolving story follows one explicit sequence:

```text
story enters in_progress or changed
  -> implementation finishes
  -> matching completed implementation trace is recorded
  -> story complete runs fresh verification
  -> passing proof marks the story implemented
  -> eligible accepted resolver backlog occurrences close in the same transaction
```

```bash
scripts/bin/harness-cli story complete <US-NNN>
```

Failure leaves the story completion-eligible and closes nothing. Repeated or
concurrent completion is idempotent. Resolution evidence records the story,
proof command, completion identity, and completion time; it does not claim the
later measured outcome.

## Record Measured Outcomes

After implementation, record what actually happened without changing the
completion proof or the legacy `actual_outcome` field:

```bash
scripts/bin/harness-cli backlog outcome record --id <local-id> \
  --status confirmed --outcome "Repeated friction fell from 4/5 to 0/5 traces" \
  --evidence "trace uids trc_... through trc_..."
```

Allowed statuses are `confirmed`, `ineffective`, and `reverted`. Each command
appends the next per-occurrence ordinal. A later `reverted` observation becomes
the current assessment while the earlier `confirmed` row remains immutable.
Accepted or proposed work is refused because passing implementation proof must
exist before measured impact can be claimed. A schedule is a reminder, so
evidence may be recorded before its due date or trace target.

## Review Rules

- Tiny proposals may be implemented directly when they only clarify docs.
- Normal proposals need a story packet or clear backlog acceptance.
- High-risk proposals need a durable decision record before changing source
  hierarchy, architecture direction, validation requirements, or risk policy.
- Keyed accepted work is closed by the explicit story-completion lifecycle,
  not `backlog close`; later outcome observation remains separate from
  implementation proof.

## Validation

After implementation, compare the predicted impact with:

- `scripts/bin/harness-cli audit`,
- `scripts/bin/harness-cli query friction`,
- `scripts/bin/harness-cli query interventions`,
- benchmark trace quality and harness compliance when benchmark proof applies.
