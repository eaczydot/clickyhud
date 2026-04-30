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

## UX Priorities
1. **Fast interaction path**: 1 click from notch to command.
2. **Clear provenance**: every saved artifact and changed file shows source agent and time.
3. **Low visual noise**: collapsed notch remains minimal.
4. **No style drift**: BoringNotch mechanics mapped to Clicky’s visual language.

---

## Phased Delivery Plan

### Phase 0 — Discovery & Mapping (1–2 days)
- Inventory Clicky UI assets/components and layout primitives.
- Map BoringNotch patterns to Clicky equivalents.
- Define integration boundaries and extension points.

### Phase 1 — Notch Shell Foundation (2–4 days)
- Implement collapsed/expanded shell scaffold.
- Add toggle shortcuts and motion primitives.
- Wire static mock data for agents/recent files/actions.

### Phase 2 — Agent HUD + Live Agent Data (3–5 days)
- Build agent list + detail panel.
- Connect to agent runtime events.
- Add action feed and status updates.

### Phase 3 — Recent File Tracking (2–4 days)
- Integrate changed-file event ingestion.
- Add filtering/sorting and quick open behavior.
- Provide file metadata preview panel.

### Phase 4 — Command Actions (2–4 days)
- Implement save-focused-page command.
- Implement save-selected-text command.
- Implement save-page-by-url workflow.
- Add run-state indicators and error handling.

### Phase 5 — Drag/Drop Stash (2–4 days)
- Implement dropzone + file validation.
- Persist stash entries.
- Emit `stash:updated` events for agent availability.

### Phase 6 — Polish, QA, and Hardening (3–5 days)
- Accessibility pass (keyboard, screen reader labels).
- Performance profiling for notch open/close and feed updates.
- Empty/error/loading states.
- Telemetry + usage metrics.

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
