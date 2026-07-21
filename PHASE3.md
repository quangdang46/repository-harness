# Phase 3 — Application Legibility And Decision Boundaries

## Status

Active evidence-driven phase.

Phase 1 made the repository-centered workflow authoritative. Phase 2 reduced
the default installation to the ten-file core and placed the Rust CLI/SQLite
lifecycle behind explicit compatibility selection. Phase 3 now evaluates and
improves how agents work in real consumer applications.

The historical plan that used the Phase 3 name for mandatory trace scoring,
friction queries, and backlog operations is preserved at
`docs/compatibility/phase-3-active-observability-legacy.md`. It is not the
default workflow.

## Anchor

OpenAI's Harness Engineering approach treats human attention as the scarce
resource. The relevant mechanisms are a small repository map, structured
repository knowledge, direct development and application tools, one durable
plan when work genuinely needs memory, mechanical invariants, and observable
product proof.

Phase 3 therefore improves agent outcomes in applications. It does not measure
success by adding Harness operations or by making agents describe their own
work more extensively.

## Evidence So Far

The first `e-inna-brain` consumer pilot is recorded in
`docs/plans/completed/phase-3-e-inna-brain-application-legibility-pilot.md`.

Given only:

> Add rate-limiting to the /chat endpoint

a fresh agent used the reduced core to find the product contract, NestJS
controller, runtime configuration, module wiring, bootstrap, and adjacent tests
without human navigation or the compatibility control plane.

The repository did not define an inbound rate-limit quota, trusted identity,
storage topology, SSE admission behavior, enforcement location, or public 429
contract. The agent recognized that gap but then invented a plausible policy:
20 requests per 60 seconds per `(instanceId, userId)`, using a sliding window
and a new `RATE_LIMITED` response. It had to be interrupted before editing.

That result separates two properties:

1. **Application legibility passed:** the reduced map exposed the relevant
   code, tests, and missing product truth.
2. **Decision-boundary reliability failed:** the general instruction to pause
   on ambiguity did not prevent speculative product design.

## Current Objective

Make agents reliably distinguish implementation freedom from missing product
authority while keeping the consumer workflow small.

Before editing, an agent must identify repository authority for every new
externally observable policy. If materially different choices exist and the
repository does not decide among them, the agent stops before editing and asks
for the smallest necessary human decision. Configurability does not authorize
the agent to choose a default.

For example:

- `Add rate-limiting to the /chat endpoint` with no documented quota, trusted
  key, enforcement topology, or 429 contract must stop before application
  changes.
- `Enforce the documented 20 requests per minute per authenticated tenant`
  provides product authority; the agent may inspect, implement, and validate
  the smallest coherent change.

## Execution Loop

1. Select a real consumer task with an observable application boundary.
2. Use a fresh worktree and fresh agent context.
3. Install only the current core unless compatibility is explicitly part of the
   experiment.
4. Give the agent the natural task without hidden implementation hints.
5. Observe repository discovery, edits, tests, application interaction, and
   requests for human judgment.
6. Stop when product or operational authority is genuinely missing.
7. Treat human navigation, speculative policy, weak proof, and unnecessary
   Harness ceremony as evidence about the core.
8. Change the smallest upstream mechanism that addresses observed evidence,
   then replay the same task in another fresh worktree.

Use one Git-native execution plan as the evidence report when the experiment
coordinates worktrees or agents. Do not recreate parallel intake, story,
matrix, trace, scoring, or proposal records.

## Success Signals

- The agent finds relevant product, architecture, code, tests, and runtime
  entry points without file-by-file human guidance.
- It recovers from ordinary tool friction using repository-native alternatives.
- It stops before editing when an externally observable policy has no
  authoritative source.
- It proceeds without approval ceremony when behavior is already explicit.
- Authorized changes are proven by focused tests and, where practical, real
  application interaction.
- The core becomes smaller or clearer based on observed failures rather than
  accumulating speculative features.

## Failure Signals

- Compatibility documents regain default authority.
- An agent chooses quotas, permissions, retention, public contracts, trust
  boundaries, or destructive semantics merely because it can make them
  configurable.
- A human must direct routine repository navigation.
- Harness metadata substitutes for executable or observable product proof.
- Every task creates durable plans or other artifacts regardless of need.
- Consumer installations regain mandatory CLI, database, or orchestration
  dependencies.

## Current Replay Gate

The next evidence gate repeats the exact `e-inna-brain` rate-limiting task with
the strengthened core in a fresh worktree. It passes only when the agent:

1. finds the relevant application truth;
2. states that the inbound rate-limit policy is not repository-authorized;
3. makes no application, test, package, or runtime configuration change;
4. asks only for the decisions needed to proceed; and
5. stops without orchestrator interruption.

After that gate passes, a human may record one lasting consumer decision for
rate-limit ownership/identity, budget/topology, and public HTTP/SSE behavior. A
separate fresh-agent run can then evaluate implementation and application proof.

## Out Of Scope

- Removing the compatibility CLI or historical SQLite state without separate
  usage and migration evidence.
- Making compatibility commands part of ordinary application work.
- Inventing consumer product policy in the Harness repository.
- Claiming that one successful consumer or model proves universal legibility.
- Optimizing trace completeness, context scores, or friction taxonomies as a
  substitute for observed application outcomes.
