import Combine
import Foundation

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
    private var tick = 0

    private init() {}

    func start() {
        guard timer == nil else { return }
        agents = [
            ClickyAgentTranscript(
                sessionId: "clicky-agent-scout",
                name: "Clicky Scout",
                phase: .waitingForInput,
                userMessages: ["Watch this screen and help me understand what to do next."],
                agentOutputs: ["Scout is watching the screen, ready to point at relevant UI."]
            ),
            ClickyAgentTranscript(
                sessionId: "clicky-agent-builder",
                name: "Clicky Builder",
                phase: .processing,
                userMessages: ["Prepare a patch and narrate the important output."],
                agentOutputs: ["Builder is processing the active task and will stream output into the notch."]
            )
        ]
        publishAgents()

        timer = Timer.scheduledTimer(withTimeInterval: 4.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.advanceDemoAgentState()
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
        publishAgents()
    }

    func sendMessage(_ message: String, to sessionId: String) {
        guard let index = agents.firstIndex(where: { $0.sessionId == sessionId }) else { return }
        agents[index].phase = .processing
        agents[index].userMessages.append(message)
        agents[index].agentOutputs.append("Clicky received: \(message). The active agent output is now streaming through the notch.")
        publishAgents()
    }

    func isClickySession(_ sessionId: String) -> Bool {
        sessionId.hasPrefix("clicky-agent-")
    }

    private func advanceDemoAgentState() {
        guard !agents.isEmpty else { return }
        tick += 1
        let activeIndex = tick % agents.count
        for index in agents.indices {
            agents[index].phase = index == activeIndex ? .processing : .waitingForInput
        }
        agents[activeIndex].agentOutputs.append("Output \(tick): Clicky agent pointer moved, captured context, and updated the notch.")
        publishAgents()
    }

    private func publishAgents() {
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
