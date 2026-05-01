import Foundation
import Observation

@MainActor
@Observable
final class ClickyHUDStore {
    var agents: [Agent]
    var selectedAgentID: Agent.ID?
    var actions: [AgentAction]
    var recentFiles: [RecentFileChange]
    var stashItems: [StashItem]
    var isShellExpanded: Bool
    var commandRunState: CommandRunState
    var urlInput: String
    var stashMessage: String?

    @ObservationIgnored private let commandService: CommandService
    @ObservationIgnored private let stashService: StashService
    @ObservationIgnored private let agentEventService: AgentEventService

    init(
        commandService: CommandService,
        stashService: StashService,
        agentEventService: AgentEventService,
        isShellExpanded: Bool = false
    ) {
        self.commandService = commandService
        self.stashService = stashService
        self.agentEventService = agentEventService
        self.agents = agentEventService.seedAgents()
        self.actions = agentEventService.seedActions()
        self.recentFiles = agentEventService.seedRecentFiles()
        self.stashItems = []
        self.isShellExpanded = isShellExpanded
        self.commandRunState = .idle
        self.urlInput = ""
        self.stashMessage = nil
        self.selectedAgentID = agents.first?.id
    }

    static func mocked() -> ClickyHUDStore {
        ClickyHUDStore(
            commandService: MockCommandService(),
            stashService: MockStashService(),
            agentEventService: MockAgentEventService()
        )
    }

    var selectedAgent: Agent? {
        agents.first { $0.id == selectedAgentID } ?? agents.first
    }

    var selectedAgentActions: [AgentAction] {
        guard let selectedAgentID else {
            return actions
        }
        return actions.filter { $0.agentID == selectedAgentID }
    }

    var activeAgentCount: Int {
        agents.filter { $0.status == .running || $0.status == .waiting }.count
    }

    func toggleShell() {
        isShellExpanded.toggle()
    }

    func selectAgent(_ agent: Agent) {
        selectedAgentID = agent.id
    }

    func runCommand(_ kind: CommandKind) {
        Task {
            await performCommand(kind)
        }
    }

    @discardableResult
    func performCommand(_ kind: CommandKind) async -> CommandResult {
        commandRunState = .running(kind)
        let result: CommandResult

        switch kind {
        case .focusedPage:
            result = await commandService.saveFocusedPage()
        case .selectedText:
            result = await commandService.saveSelectedText()
        case .pageByURL:
            result = await performURLCommand()
        }

        commandRunState = .finished(result)
        appendCommandAction(result)
        return result
    }

    func addStashFiles(from urls: [URL]) {
        Task {
            for url in urls {
                await addStashFile(from: url)
            }
        }
    }

    @discardableResult
    func addStashFile(from url: URL) async -> Result<StashItem, Error> {
        do {
            let item = try await stashService.addFile(at: url)
            stashItems.insert(item, at: 0)
            stashMessage = "Added \(item.fileName) to stash."
            actions.insert(
                AgentAction(
                    agentID: selectedAgentID ?? agents.first?.id ?? "clicky",
                    eventName: .stashUpdated,
                    title: "Stash updated",
                    detail: "\(item.fileName) is available to agents.",
                    timestamp: Date()
                ),
                at: 0
            )
            return .success(item)
        } catch {
            stashMessage = error.localizedDescription
            return .failure(error)
        }
    }

    func removeStashItem(_ item: StashItem) {
        Task {
            try? await stashService.removeFile(item)
            stashItems.removeAll { $0.id == item.id }
            stashMessage = "Removed \(item.fileName)."
        }
    }

    func displayName(for agentID: Agent.ID) -> String {
        agents.first { $0.id == agentID }?.name ?? "Clicky"
    }

    private func performURLCommand() async -> CommandResult {
        let trimmed = urlInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return CommandResult(
                kind: .pageByURL,
                isSuccess: false,
                message: "Enter a URL before saving a page."
            )
        }

        guard let url = URL(string: trimmed), let scheme = url.scheme?.lowercased(), ["http", "https"].contains(scheme) else {
            return CommandResult(
                kind: .pageByURL,
                isSuccess: false,
                message: "Use a valid http or https URL."
            )
        }

        return await commandService.savePageByURL(url)
    }

    private func appendCommandAction(_ result: CommandResult) {
        let agentID = selectedAgentID ?? agents.first?.id ?? "clicky"
        actions.insert(
            AgentAction(
                agentID: agentID,
                eventName: .agentAction,
                title: result.kind.label,
                detail: result.message,
                timestamp: result.timestamp
            ),
            at: 0
        )
    }
}
