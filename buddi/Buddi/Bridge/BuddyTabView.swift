import SwiftUI

struct BuddyTabView: View {
    @EnvironmentObject var vm: BuddiViewModel
    @ObservedObject private var bridge = BuddiSessionBridge.shared
    @ObservedObject private var panelVM = BuddiSessionBridge.shared.panelViewModel
    @ObservedObject private var clickyRuntime = ClickySessionAdapter.shared
    @State private var suppressionToken = UUID()
    @State private var isSuppressing = false

    private var isInChat: Bool {
        if case .chat = panelVM.contentType { return true }
        return false
    }

    var body: some View {
        VStack(spacing: 0) {
            if isInChat, case .chat(let session) = panelVM.contentType {
                ChatView(
                    sessionId: session.sessionId,
                    initialSession: session,
                    sessionMonitor: bridge.sessionMonitor,
                    viewModel: panelVM
                )
                .onHover { hovering in
                    updateSuppression(for: hovering)
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .trailing).combined(with: .opacity)
                ))
            } else {
                homeContent
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: isInChat)
        .onDisappear {
            updateSuppression(for: false)
            panelVM.saveChatState()
            panelVM.exitChat()
        }
    }

    private var homeContent: some View {
        HStack(alignment: .top, spacing: 15) {
            VStack(spacing: 3) {
                ASCIIFullSpriteView(
                    animator: BuddyManager.shared.animator,
                    identity: BuddyManager.shared.effectiveIdentity,
                    fontSize: 8
                )

                Text(BuddyManager.shared.effectiveIdentity.name
                     ?? "Clicky")
                    .font(.caption2.weight(.medium).monospaced())
                    .foregroundColor(Color(nsColor: BuddyManager.shared.effectiveIdentity.rarity.nsColor).opacity(0.8))

                ClickyRuntimeSummary(runtime: clickyRuntime, sessions: sessions)
            }
            .frame(width: 100)

            ClaudeInstancesView(
                sessionMonitor: bridge.sessionMonitor,
                viewModel: panelVM
            )
            .frame(maxWidth: .infinity)
        }
        .padding(.top, 10)
        .padding(.leading, 5)
        .transition(.asymmetric(insertion: .opacity.combined(with: .move(edge: .top)), removal: .opacity))
        .blur(radius: vm.notchState == .closed ? 30 : 0)
        .onHover { hovering in
            updateSuppression(for: hovering)
        }
    }

    private var sessions: [SessionState] { bridge.sessionMonitor.instances }

    private static let dayTimeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEE h a"
        return f
    }()

    private func formatResetTime(_ date: Date) -> String {
        let remaining = date.timeIntervalSinceNow
        if remaining <= 0 { return "now" }
        let hours = Int(remaining) / 3600
        let minutes = (Int(remaining) % 3600) / 60
        if hours > 24 {
            return Self.dayTimeFormatter.string(from: date)
        }
        if hours > 0 { return "\(hours)h \(minutes)m" }
        return "\(minutes)m"
    }

    private func updateSuppression(for hovering: Bool) {
        guard hovering != isSuppressing else { return }
        isSuppressing = hovering
        vm.setScrollGestureSuppression(hovering, token: suppressionToken)
    }
}

private struct ClickyRuntimeSummary: View {
    @ObservedObject var runtime: ClickySessionAdapter
    let sessions: [SessionState]

    private var clickySessions: [SessionState] {
        sessions.filter { ClickySessionAdapter.shared.isClickySession($0.sessionId) }
    }

    private var activeClickyCount: Int {
        clickySessions.filter { $0.phase.isActive || $0.phase.needsAttention }.count
    }

    private var latestSnippet: String? {
        runtime.latestTranscript ?? runtime.latestResponse
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            RuntimeMetricRow(label: "Voice", detail: runtime.voiceState.title)
            RuntimeMetricRow(label: "Agents", detail: "\(activeClickyCount)/\(max(clickySessions.count, runtime.activeAgentCount))")
            RuntimeMetricRow(label: "Model", detail: runtime.selectedModel)
            RuntimeMetricRow(label: "Worker", detail: runtime.workerStatusText)
            RuntimeMetricRow(
                label: "Cursor",
                detail: runtime.isClickyCursorEnabled
                    ? (runtime.isCursorOverlayVisible ? "Visible" : "Ready")
                    : "Off"
            )
            RuntimeMetricRow(label: "Perms", detail: runtime.permissions.summary)

            if let snippet = latestSnippet, !snippet.isEmpty {
                Text(snippet)
                    .font(.system(size: 9, weight: .regular, design: .rounded))
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 2)
            }
        }
        .padding(.top, 3)
    }
}

private struct RuntimeMetricRow: View {
    let label: String
    let detail: String

    var body: some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.system(size: 9, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)
            Spacer(minLength: 2)
            Text(detail)
                .font(.system(size: 9, weight: .medium, design: .rounded))
                .foregroundColor(Color(red: 0.35, green: 0.55, blue: 1.0))
                .lineLimit(1)
                .truncationMode(.middle)
        }
    }
}
