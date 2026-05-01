import Foundation

struct Agent: Identifiable, Hashable {
    let id: String
    var name: String
    var taskSummary: String
    var status: AgentStatus
    var lastUpdated: Date
}

enum AgentStatus: String, CaseIterable, Hashable {
    case idle
    case running
    case waiting
    case error

    var label: String {
        switch self {
        case .idle: "Idle"
        case .running: "Running"
        case .waiting: "Waiting"
        case .error: "Needs attention"
        }
    }
}

struct AgentAction: Identifiable, Hashable {
    let id: UUID
    var agentID: Agent.ID
    var eventName: ClickyEventName
    var title: String
    var detail: String
    var timestamp: Date

    init(
        id: UUID = UUID(),
        agentID: Agent.ID,
        eventName: ClickyEventName,
        title: String,
        detail: String,
        timestamp: Date
    ) {
        self.id = id
        self.agentID = agentID
        self.eventName = eventName
        self.title = title
        self.detail = detail
        self.timestamp = timestamp
    }
}

struct RecentFileChange: Identifiable, Hashable {
    let id: UUID
    var path: String
    var changeType: FileChangeType
    var timestamp: Date
    var agentID: Agent.ID

    init(
        id: UUID = UUID(),
        path: String,
        changeType: FileChangeType,
        timestamp: Date,
        agentID: Agent.ID
    ) {
        self.id = id
        self.path = path
        self.changeType = changeType
        self.timestamp = timestamp
        self.agentID = agentID
    }
}

enum FileChangeType: String, CaseIterable, Hashable {
    case created
    case updated
    case deleted

    var label: String {
        switch self {
        case .created: "Created"
        case .updated: "Updated"
        case .deleted: "Deleted"
        }
    }
}

struct StashItem: Identifiable, Hashable {
    let id: UUID
    var fileName: String
    var fileExtension: String
    var originalPath: String
    var sizeInBytes: Int64
    var addedAt: Date
    var availabilityEvent: ClickyEventName

    init(
        id: UUID = UUID(),
        fileName: String,
        fileExtension: String,
        originalPath: String,
        sizeInBytes: Int64,
        addedAt: Date,
        availabilityEvent: ClickyEventName = .stashUpdated
    ) {
        self.id = id
        self.fileName = fileName
        self.fileExtension = fileExtension
        self.originalPath = originalPath
        self.sizeInBytes = sizeInBytes
        self.addedAt = addedAt
        self.availabilityEvent = availabilityEvent
    }
}

struct CommandResult: Identifiable, Hashable {
    let id: UUID
    var kind: CommandKind
    var isSuccess: Bool
    var message: String
    var artifactPath: String?
    var timestamp: Date

    init(
        id: UUID = UUID(),
        kind: CommandKind,
        isSuccess: Bool,
        message: String,
        artifactPath: String? = nil,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.kind = kind
        self.isSuccess = isSuccess
        self.message = message
        self.artifactPath = artifactPath
        self.timestamp = timestamp
    }
}

enum CommandKind: String, CaseIterable, Hashable {
    case focusedPage
    case selectedText
    case pageByURL

    var label: String {
        switch self {
        case .focusedPage: "Save focused page"
        case .selectedText: "Save selected text"
        case .pageByURL: "Save page by URL"
        }
    }

    var systemImage: String {
        switch self {
        case .focusedPage: "safari"
        case .selectedText: "text.quote"
        case .pageByURL: "link"
        }
    }
}

enum CommandRunState: Equatable {
    case idle
    case running(CommandKind)
    case finished(CommandResult)

    var runningKind: CommandKind? {
        if case let .running(kind) = self {
            return kind
        }
        return nil
    }
}

enum ClickyEventName: String, Hashable {
    case agentStatus = "agent:status"
    case agentAction = "agent:action"
    case filesChanged = "files:changed"
    case stashUpdated = "stash:updated"
}
