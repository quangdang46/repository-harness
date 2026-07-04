---
name: harness-intake-griller
description: Use when a user has a rough product idea, feature request, bug-fix intent, Harness improvement, or Symphony-ready work candidate and wants to clarify intent before implementation. This skill grills intent, runs this repository's Harness feature-intake workflow, creates or updates product docs and story packets, and prepares runnable work for Symphony without starting execution unless explicitly requested.
---

# Harness Intake Griller

Turn fuzzy intent into Harness-ready planning artifacts before any implementation or Symphony run starts.

Use this skill as the pre-run discussion gate for this repository. The output is not code by default; it is shared understanding, intake classification, docs, stories, validation expectations, and a clear handoff to Symphony.

## Operating Boundary

Do not jump from user intent directly to implementation.

Do not start `harness-symphony run`, click a Web UI start control, call `POST /api/tasks/<story-id>/start`, or invoke a long-running agent execution unless the user explicitly asks to execute after the intake artifacts are ready.

Symphony owns execution, run isolation, logs, review artifacts, PR creation, merge marking, and sync. This skill owns the discussion and planning work before Symphony.

## Required Preflight

Read the local agent instructions first. If `AGENTS.md` lists a Harness block, follow it.

Prefer these sources before asking questions when they exist:

- `AGENTS.md`
- `README.md`
- `docs/HARNESS.md`
- `docs/FEATURE_INTAKE.md`
- `docs/ARCHITECTURE.md`
- `docs/CONTEXT_RULES.md`
- `docs/TOOL_REGISTRY.md`
- `scripts/bin/harness-cli query matrix`
- relevant `docs/product/*`
- relevant `docs/stories/*`
- relevant `docs/decisions/*`

Before a step that could use an optional external tool, query the Harness tool registry:

```bash
scripts/bin/harness-cli query tools --capability <capability> --status present
```

If the capability is inactive or absent, skip cleanly and note the gap in the final trace or planning notes.

## Interview Loop

Ask exactly one question at a time when the answer is not discoverable from local files or prior conversation.

For each question:

- restate the current understanding in one sentence
- name the missing decision
- include a recommended answer
- explain why that recommendation is probably right

Prefer three sharp questions over a long questionnaire. Stop interviewing once the work is safe to classify and document.

## Intake Gate

Do not create story packets until these fields are clear enough:

1. Outcome: what should be true for the user.
2. User-visible behavior or operational behavior: what changes from today.
3. Scope boundary: what may change and what is out of scope.
4. Source of truth: product docs, existing stories, issue, screenshot, logs, code path, or conversation note.
5. Risk lane: tiny, normal, or high-risk, using `docs/FEATURE_INTAKE.md`.
6. Validation proof: command, test, screenshot, API response, matrix row, rebuild, or review artifact.
7. Handoff rule: whether the result should stop at docs/stories or proceed to Symphony after explicit approval.

If any field is weak, ask the next highest-leverage question.

## Workflow

1. **Clarify intent**
   - Convert the user request into a concise intent brief.
   - Capture goals, non-goals, assumptions, open questions, affected surfaces, and likely risks.

2. **Record intake**
   - Classify the request using `docs/FEATURE_INTAKE.md`.
   - Record the durable intake row with `scripts/bin/harness-cli intake`.
   - Use `harness_improvement` when the work changes how humans and agents collaborate.

3. **Map docs and stories**
   - Identify existing product docs and story packets that already cover the request.
   - Update existing artifacts when they are the real source of truth.
   - Create new product docs, initiative notes, story packets, hierarchy, or dependency records only when the request needs them.

4. **Shape validation**
   - Define cheap checks for planning changes.
   - Define final proof for the eventual implementation.
   - Keep proof concrete enough for `scripts/bin/harness-cli story verify <id>` when possible.

5. **Prepare Symphony handoff**
   - Mark or create story records with correct lane, status, and verify command.
   - Ensure dependencies and hierarchy are visible to the board when relevant.
   - State which story is ready for Symphony and what should remain manual review.

6. **Stop before execution**
   - Summarize the intake result.
   - List created or updated artifacts.
   - Provide the exact Symphony command or Web UI action only as a next step unless the user explicitly asked to start execution.

## Artifact Standards

For tiny work:

- record intake
- patch directly only if the user asked for implementation
- keep docs current
- run quick checks

For normal work:

- create or update one story packet from the repo template
- update or reference relevant product docs
- define validation expectations
- add or update the durable story row

For high-risk work:

- use the repo's high-risk story template
- document design, validation, and pause points
- ask for human confirmation before implementation if direction remains ambiguous
- record durable decisions when behavior, architecture, data ownership, API shape, authorization, or validation requirements change meaningfully

## Output Shape

When the intake is complete, respond with:

```text
Intent brief:
- Outcome:
- Non-goals:
- Assumptions:
- Open questions:

Harness intake:
- Intake:
- Lane:
- Reason:
- Affected docs:
- Stories:
- Validation:

Symphony handoff:
- Ready story:
- Dependencies:
- Command or UI next step:
- Do not start until:
```

If implementation has not been explicitly authorized, end by making the handoff clear without starting it.

## Friction Rule

If the discussion reveals a missing Harness rule, stale doc, unclear source of truth, or repeated manual step, either fix it within scope or record a backlog item:

```bash
scripts/bin/harness-cli backlog add --title "<short name>" --pain "<what was hard>" --risk normal
```

Before final response, record a trace that includes intake id, actions, files read, files changed, validation, and any friction discovered.
