import Combine
import ApplicationServices
import AVFoundation
import CoreGraphics
import Foundation

enum ClickyVoiceState: String {
    case idle
    case listening
    case processing
    case responding

    var title: String {
        switch self {
        case .idle:
            return "Idle"
        case .listening:
            return "Listening"
        case .processing:
            return "Processing"
        case .responding:
            return "Responding"
        }
    }
}

struct ClickyPermissionState: Equatable {
    var hasAccessibilityPermission = false
    var hasScreenRecordingPermission = false
    var hasMicrophonePermission = false
    var hasScreenContentPermission = false

    var grantedCount: Int {
        [
            hasAccessibilityPermission,
            hasScreenRecordingPermission,
            hasMicrophonePermission,
            hasScreenContentPermission
        ].filter { $0 }.count
    }

    var summary: String {
        "\(grantedCount)/4 granted"
    }
}

@MainActor
final class ClickySessionAdapter: ObservableObject {
    static let shared = ClickySessionAdapter()

    private struct ClickyAgentTranscript {
        let sessionId: String
        let name: String
        var phase: SessionPhase
        var userMessages: [String]
        var agentOutputs: [String]

        var chatItems: [ChatHistoryItem] {
            var items: [ChatHistoryItem] = []
            for (index, userMessage) in userMessages.enumerated() {
                items.append(ChatHistoryItem(
                    id: "\(sessionId)-user-\(index)",
                    type: .user(userMessage),
                    timestamp: Date().addingTimeInterval(Double(index) * 2)
                ))
                if index < agentOutputs.count {
                    items.append(ChatHistoryItem(
                        id: "\(sessionId)-agent-\(index)",
                        type: .assistant(agentOutputs[index]),
                        timestamp: Date().addingTimeInterval(Double(index) * 2 + 1)
                    ))
                }
            }
            if agentOutputs.count > userMessages.count, let output = agentOutputs.last {
                items.append(ChatHistoryItem(
                    id: "\(sessionId)-agent-latest",
                    type: .assistant(output),
                    timestamp: Date()
                ))
            }
            return items
        }

        var lastUserMessage: String? {
            userMessages.last
        }

        var lastAgentOutput: String {
            agentOutputs.last ?? "\(name) is ready."
        }
    }

    private var agents: [ClickyAgentTranscript] = []
    private var timer: Timer?
    private var transientVoiceStateExpiresAt: Date?

    @Published private(set) var voiceState: ClickyVoiceState = .idle
    @Published private(set) var activeAgentCount = 0
    @Published private(set) var selectedModel: String = "claude-sonnet-4-6"
    @Published private(set) var workerBaseURL: String?
    @Published private(set) var isClickyCursorEnabled = true
    @Published private(set) var isCursorOverlayVisible = false
    @Published private(set) var latestTranscript: String?
    @Published private(set) var latestResponse: String?
    @Published private(set) var permissions = ClickyPermissionState()

    var workerStatusText: String {
        guard let workerBaseURL, !workerBaseURL.isEmpty else {
            return "Worker not configured"
        }
        return URL(string: workerBaseURL)?.host ?? workerBaseURL
    }

    var workerEndpointSummary: String {
        "/chat /tts /transcribe-token"
    }

    private static let defaultSelectedModel = "claude-sonnet-4-6"
    private static let workerBaseURLKey = "clickyWorkerBaseURL"
    private static let selectedModelKey = "selectedClaudeModel"
    private static let clickyCursorEnabledKey = "isClickyCursorEnabled"
    private static let screenContentPermissionKey = "hasScreenContentPermission"

    private init() {}

    func start() {
        guard timer == nil else { return }
        refreshRuntimeState()
        agents = [
            ClickyAgentTranscript(
                sessionId: "clicky-agent-companion",
                name: "Clicky Companion",
                phase: .waitingForInput,
                userMessages: [],
                agentOutputs: ["Clicky is ready. Hold Control+Option to talk, or configure the worker URL to enable voice runtime calls."]
            )
        ]
        publishAgents()

        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.refreshRuntimeState()
                self?.publishAgents()
            }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    func spawnAgent() {
        let nextIndex = agents.count + 1
        let agent = ClickyAgentTranscript(
            sessionId: "clicky-agent-\(nextIndex)",
            name: "Clicky Agent \(nextIndex)",
            phase: .processing,
            userMessages: ["Spawned from the notch."],
            agentOutputs: ["Launching pointer and preparing the conversation stream."]
        )
        agents.append(agent)
        setTransientVoiceState(.processing)
        publishAgents()
    }

    func sendMessage(_ message: String, to sessionId: String) {
        guard let index = agents.firstIndex(where: { $0.sessionId == sessionId }) else { return }
        agents[index].phase = .processing
        agents[index].userMessages.append(message)
        agents[index].agentOutputs.append("Clicky received: \(message). The active agent output is now streaming through the notch.")
        latestTranscript = message
        latestResponse = agents[index].lastAgentOutput
        setTransientVoiceState(.responding)
        publishAgents()
    }

    func isClickySession(_ sessionId: String) -> Bool {
        sessionId.hasPrefix("clicky-agent-")
    }

    private func setTransientVoiceState(_ state: ClickyVoiceState) {
        voiceState = state
        transientVoiceStateExpiresAt = Date().addingTimeInterval(2.5)
    }

    private func refreshRuntimeState() {
        selectedModel = UserDefaults.standard.string(forKey: Self.selectedModelKey) ?? Self.defaultSelectedModel
        workerBaseURL = UserDefaults.standard.string(forKey: Self.workerBaseURLKey)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        isClickyCursorEnabled = UserDefaults.standard.object(forKey: Self.clickyCursorEnabledKey) == nil
            ? true
            : UserDefaults.standard.bool(forKey: Self.clickyCursorEnabledKey)

        let permissionState = ClickyPermissionState(
            hasAccessibilityPermission: AXIsProcessTrusted(),
            hasScreenRecordingPermission: CGPreflightScreenCaptureAccess(),
            hasMicrophonePermission: AVCaptureDevice.authorizationStatus(for: .audio) == .authorized,
            hasScreenContentPermission: UserDefaults.standard.bool(forKey: Self.screenContentPermissionKey)
        )
        permissions = permissionState
        isCursorOverlayVisible = isClickyCursorEnabled && permissionState.grantedCount == 4

        if let transientVoiceStateExpiresAt, Date() >= transientVoiceStateExpiresAt {
            voiceState = .idle
            self.transientVoiceStateExpiresAt = nil
        }
    }

    private func publishAgents() {
        refreshRuntimeState()
        activeAgentCount = agents.filter { $0.phase.isActive || $0.phase.needsAttention }.count
        latestTranscript = agents.last?.lastUserMessage ?? latestTranscript
        latestResponse = agents.last?.lastAgentOutput ?? latestResponse

        for agent in agents {
            Task {
                await SessionStore.shared.upsertClickyAgentSession(
                    sessionId: agent.sessionId,
                    agentName: agent.name,
                    status: agent.phase,
                    lastUserMessage: agent.lastUserMessage,
                    lastAgentOutput: agent.lastAgentOutput,
                    chatItems: agent.chatItems
                )
            }
        }
    }
}
