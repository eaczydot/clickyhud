# Clicky + BoringNotch + HUD Integration Plan

## Goal
Integrate `clicky` agent workflows into a `boring.notch`-inspired shell/HUD experience so users can:
- See and interact with active Clicky agents.
- View recently changed files from agent actions.
- Trigger commands (save focused page, selected text, or a provided URL/page).
- Provide files via drag-and-drop and stash them for agent use.

The visual priority is **Clicky branding/assets first**, then adapt BoringNotch interaction patterns to Clicky’s style system.

---

## Product Scope (MVP)

### 1) Notch Shell (always-available top surface)
- Compact top shell inspired by BoringNotch behavior:
  - Collapsed state: agent status + quick actions badge.
  - Expanded state: recent files, quick command buttons, stash dropzone.
- Keyboard shortcut to toggle shell.
- Pointer and accessibility-friendly hit targets.

### 2) Agent HUD (expanded control panel)
- Agent list with:
  - Name/ID
  - Current task summary
  - Activity state (idle, running, waiting, error)
  - Last updated timestamp
- Conversation/action feed with latest agent actions.
- Inline action buttons:
  - “Save focused page”
  - “Save selected text”
  - “Save page by URL”

### 3) Recent File Activity
- “Recently changed files” pane:
  - File path
  - Change type (created/updated/deleted)
  - Timestamp
  - Agent/source attribution
- Clicking an item opens preview or file metadata.

### 4) File Intake / Stash
- Drag-and-drop area in shell and HUD.
- Intake pipeline:
  1. Validate file types/sizes.
  2. Copy to Clicky stash directory.
  3. Emit event for agent availability.
- Stashed file browser with remove/re-stash actions.

---

## System Architecture

### A) UI Layer
- **Clicky-first design system**
  - Reuse Clicky colors, typography, iconography, spacing.
  - Port BoringNotch behaviors, not visual identity.
- Components:
  - `NotchShell`
  - `AgentHUD`
  - `RecentFilesPanel`
  - `CommandActions`
  - `StashDropzone`

### B) State & Event Layer
- Central store for:
  - Active agents
  - Recent file changes
  - Command execution status
  - Stash contents
- Event bus/websocket channel for live updates:
  - `agent:status`
  - `agent:action`
  - `files:changed`
  - `stash:updated`

### C) Command Execution Layer
- Command handlers:
  - `saveFocusedPage()`
  - `saveSelectedText()`
  - `savePageByUrl(url)`
- Standardized result object:
  - success/failure
  - artifact path
  - agent visibility metadata

### D) Persistence Layer
- Session-local stores for transient UI state.
- Persistent stash + recent-file index.
- Optional retention policy (e.g., 7–30 days).

---

## Parallel Delivery Model

To complete the implementation faster, work is organized into **four parallel tracks** with explicit dependency gates.
All tracks **start on Day 1 in parallel**. Gates do not block starting work; gates only control integration/merge promotion.

### Track A — UX & Notch Shell
**Scope:** Interaction model, component structure, and visual implementation.
- Build `NotchShell` collapsed/expanded states.
- Implement shortcut + focus management.
- Apply Clicky design tokens and motion.
- Integrate placeholders for Agent HUD, Recent Files, and Stash panels.

**Primary outputs:**
- `NotchShell`, shell layout primitives, keyboard interactions.

### Track B — Agent Runtime + Events
**Scope:** Data contracts and live event ingestion.
- Define schemas for `agent:*`, `files:*`, `stash:*` events.
- Build event adapter/websocket client.
- Normalize runtime events into central store selectors.
- Provide mock-event generator for local dev and tests.

**Primary outputs:**
- Event contract doc, event adapter, normalized store slices.

### Track C — Commands + Artifacts
**Scope:** Command execution and save workflows.
- Implement `saveFocusedPage()`, `saveSelectedText()`, `savePageByUrl(url)`.
- Add status lifecycle (`queued/running/success/error`) and per-command toasts.
- Persist command artifacts and attach provenance (agent, timestamp, source).

**Primary outputs:**
- Command handlers, execution state machine, artifact metadata model.

### Track D — Stash + File Activity
**Scope:** File intake pipeline and recent changes surface.
- Implement `StashDropzone` validation/copy pipeline.
- Build recent-file ingestion, sorting/filtering, and preview metadata panel.
- Emit/consume `stash:updated` and `files:changed` events.

**Primary outputs:**
- Stash service, recent-files panel, file event reducers.

---

## Dependency Gates (for Safe Parallelization)

1. **Gate G1 (Day 2): Event schema freeze**
   - Required by Tracks B/C/D before wiring live runtime behavior.
2. **Gate G2 (Day 4): Shared store contract freeze**
   - Required by Tracks A/B/C/D for stable integration.
3. **Gate G3 (Day 6): Command result contract freeze**
   - Required by Tracks A/C/D for consistent UI states and file attribution.
4. **Gate G4 (Day 8): End-to-end integration branch cut**
   - All tracks merge behind flags for QA hardening.

> **Parallel-first rule:** no track waits idle for another track. If a gate is not yet frozen, teams proceed with mocks/adapters and swap to final contracts at gate freeze.

---

## Integration Strategy

- Use **feature flags** per track (`notch_shell_v1`, `agent_events_v1`, `command_actions_v1`, `stash_pipeline_v1`).
- Merge continuously into an integration branch after each gate.
- Require contract tests at merge points:
  - Event schema validation tests.
  - Store selector compatibility tests.
  - Command result contract tests.
- Run daily 30-minute cross-track sync focused only on blockers/contract drift.

---

## Execution Details (to make parallel work actionable)

### Owners and handoffs
- **Track A owner (Frontend):** owns notch/HUD interaction and all UI states.
- **Track B owner (Platform):** owns event contracts, transport, and store ingestion.
- **Track C owner (Runtime):** owns command handlers and artifact lifecycle.
- **Track D owner (Files):** owns stash intake, file indexing, and file preview metadata.
- **Tech lead:** approves gate freezes (G1–G4) and resolves cross-track contract disputes within 24 hours.

### Definition of done per track
- **Track A (UX & Notch Shell):**
  - Keyboard and pointer interactions pass accessibility checklist.
  - Empty/loading/error states implemented for all shell surfaces.
  - Feature flag supports instant rollback without app restart.
- **Track B (Runtime + Events):**
  - Schema validation enforces required fields on ingress.
  - Reconnect/backoff behavior proven in local fault simulation.
  - Store selectors documented and consumed by at least one UI workflow.
- **Track C (Commands + Artifacts):**
  - All three save commands produce standardized result envelopes.
  - Failure states include actionable user messaging and retry path.
  - Artifact provenance (agent/time/source) is persisted and queryable.
- **Track D (Stash + File Activity):**
  - Validation rejects unsupported types/sizes with clear reason.
  - File-copy pipeline is non-blocking with progress indication.
  - Recent-file list stays consistent under bursty update streams.

### Contract artifacts required at each gate
- **G1:** JSON schema files for event types, plus fixture examples.
- **G2:** Central store interface signatures and selector contract tests.
- **G3:** Command result schema + compatibility matrix for UI states.
- **G4:** End-to-end scenario checklist and release-readiness report.

### Weekly cross-track ceremony checklist
- Review gate readiness and blocked contracts.
- Confirm feature-flag defaults for staging and production.
- Triage top 5 defects by user impact and integration risk.
- Record decision log entries for any contract changes.

---

## Timeline (Parallelized)

### Day 1 kickoff (all tracks begin in parallel)
- Track A starts shell scaffold, keyboard handling, and UI states.
- Track B starts schema drafting, websocket adapter, and mock event generator.
- Track C starts command interfaces, result envelopes, and execution lifecycle.
- Track D starts dropzone validation, stash copy service, and file activity model.
- Deliverable by end of day: each track ships one vertical slice behind its feature flag.

### Week 1
- Day 1–2:
  - Track A: Shell scaffold and interactions.
  - Track B: Event schema and adapter scaffolding.
  - Track C: Command interfaces and mock executor.
  - Track D: Stash validation rules and file model.
- Day 2: **G1 freeze**.
- Day 3–4:
  - Track A: HUD shell slotting + accessibility.
  - Track B: Runtime ingestion into store.
  - Track C: Implement focused-page + selected-text save.
  - Track D: Recent-files panel with mock stream.
- Day 4: **G2 freeze**.

### Week 2
- Day 5–6:
  - Track C: Implement URL save + error handling.
  - Track D: Persist stash + `stash:updated` wiring.
  - Track A: Production loading/empty/error states.
  - Track B: Reliability hardening + reconnect logic.
- Day 6: **G3 freeze**.
- Day 7–8:
  - Cross-track integration, telemetry, and perf tuning.
  - Accessibility pass and end-to-end scenarios.
- Day 8: **G4 branch cut**.

### Week 3 (buffer / release prep)
- Bug bash, regression fixes, rollout checks, staged enablement.

### Daily parallel operating rhythm
- 15-minute async standup per track before 10:00.
- 30-minute cross-track contract sync (only blockers/contract changes).
- End-of-day integration window: each track merges at least one PR behind flag.
- If blocked >2 hours, escalate to tech lead for same-day decision.

---

## Success Metrics and Rollout Controls

### MVP success metrics
- Notch open-to-action latency: **<150ms p95** on supported hardware.
- Command completion success rate: **>98%** excluding explicit permission denies.
- Event-to-UI freshness: **<1s p95** for `agent:*` and `files:*` updates.
- Dropzone validation clarity: **100%** of rejections include a user-readable reason.

### Rollout stages
1. **Internal dogfood:** all flags on, telemetry required.
2. **Limited beta cohort:** 10–20% exposure with command and stash monitoring.
3. **General availability:** progressive rollout with kill-switch support per flag.

### Rollback triggers
- Command failure rate exceeds 5% for 15 minutes.
- Event ingestion lag exceeds 3 seconds p95 for 15 minutes.
- Crash rate regression >1% compared to baseline build.

---

## UX Priorities
1. **Fast interaction path**: 1 click from notch to command.
2. **Clear provenance**: every saved artifact and changed file shows source agent and time.
3. **Low visual noise**: collapsed notch remains minimal.
4. **No style drift**: BoringNotch mechanics mapped to Clicky’s visual language.

---

## Acceptance Criteria (MVP)
- User can open notch shell from any supported app context.
- User sees active agent status and can open detailed HUD.
- User sees latest changed files attributed to agents.
- User can run all three save commands with visible success/failure.
- User can drag/drop files into stash and agents can reference them.
- Visual style aligns with Clicky assets while preserving BoringNotch interaction model.

---

## Risks & Mitigations
- **Risk:** UI mismatch between BoringNotch behavior and Clicky design language.  
  **Mitigation:** Ship a Clicky-themed design token pass before functional expansion.
- **Risk:** Event stream inconsistencies for file-change tracking.  
  **Mitigation:** Add event schema contract + fallback polling.
- **Risk:** Command permissions/security edge cases.  
  **Mitigation:** explicit permission prompts and allowlist rules.
- **Risk:** Drag/drop large files impacts responsiveness.  
  **Mitigation:** background processing + size caps + progress UI.
- **Risk:** Parallel tracks drift in interface assumptions.  
  **Mitigation:** enforce gate freezes + contract tests as merge criteria.

---

## Suggested Backlog Seeds
- [ ] Build `NotchShell` component with collapse/expand states.
- [ ] Add global shortcut and focus management.
- [ ] Define event contract for `agent:*`, `files:*`, `stash:*`.
- [ ] Implement `RecentFilesPanel` with timestamp + source attribution.
- [ ] Add `CommandActions` with three save commands.
- [ ] Implement `StashDropzone` and stash explorer.
- [ ] Add unit tests for command handlers.
- [ ] Add integration tests for end-to-end shell/HUD interactions.
- [ ] Add contract tests for event and command schemas.
- [ ] Add rollout flags and staged-release checklist.
