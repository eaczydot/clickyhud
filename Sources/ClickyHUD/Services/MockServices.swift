import Foundation

struct MockCommandService: CommandService {
    var delayNanoseconds: UInt64 = 250_000_000

    func saveFocusedPage() async -> CommandResult {
        await pause()
        return CommandResult(
            kind: .focusedPage,
            isSuccess: true,
            message: "Focused page saved for agents.",
            artifactPath: "~/Clicky/Stash/focused-page.md"
        )
    }

    func saveSelectedText() async -> CommandResult {
        await pause()
        return CommandResult(
            kind: .selectedText,
            isSuccess: true,
            message: "Selected text captured.",
            artifactPath: "~/Clicky/Stash/selection.txt"
        )
    }

    func savePageByURL(_ url: URL) async -> CommandResult {
        await pause()
        let host = url.host(percentEncoded: false) ?? url.absoluteString
        return CommandResult(
            kind: .pageByURL,
            isSuccess: true,
            message: "Queued \(host) for agent review.",
            artifactPath: "~/Clicky/Stash/url-\(host).md"
        )
    }

    private func pause() async {
        try? await Task.sleep(nanoseconds: delayNanoseconds)
    }
}

struct MockStashService: StashService {
    static let maximumFileSize: Int64 = 25 * 1024 * 1024
    static let supportedExtensions: Set<String> = [
        "txt", "md", "markdown", "pdf",
        "png", "jpg", "jpeg", "gif", "webp",
        "swift", "js", "jsx", "ts", "tsx", "json", "html", "css",
        "py", "rb", "go", "rs", "java", "kt", "c", "h", "cpp", "hpp",
        "csv", "xml", "yaml", "yml"
    ]

    var maximumFileSize: Int64 = Self.maximumFileSize
    var supportedExtensions: Set<String> = Self.supportedExtensions

    func validateFile(at url: URL) throws -> StashValidation {
        let values = try? url.resourceValues(forKeys: [.isDirectoryKey, .fileSizeKey])
        guard values?.isDirectory != true else {
            throw StashError.directoryNotAllowed
        }

        let fileExtension = url.pathExtension.lowercased()
        guard supportedExtensions.contains(fileExtension) else {
            throw StashError.unsupportedFileType(fileExtension)
        }

        guard let size = values?.fileSize.map(Int64.init) else {
            throw StashError.unreadableFile
        }

        guard size <= maximumFileSize else {
            throw StashError.fileTooLarge(maximumBytes: maximumFileSize)
        }

        return StashValidation(
            fileName: url.lastPathComponent,
            fileExtension: fileExtension,
            sizeInBytes: size
        )
    }

    func addFile(at url: URL) async throws -> StashItem {
        let validation = try validateFile(at: url)
        return StashItem(
            fileName: validation.fileName,
            fileExtension: validation.fileExtension,
            originalPath: url.path,
            sizeInBytes: validation.sizeInBytes,
            addedAt: Date()
        )
    }

    func removeFile(_ item: StashItem) async throws {
        _ = item
    }
}

struct MockAgentEventService: AgentEventService {
    var now: Date = Date()

    func seedAgents() -> [Agent] {
        [
            Agent(
                id: "agent-design",
                name: "Design Mapper",
                taskSummary: "Mapping BoringNotch interactions into Clicky HUD states.",
                status: .running,
                lastUpdated: now.addingTimeInterval(-90)
            ),
            Agent(
                id: "agent-files",
                name: "File Scout",
                taskSummary: "Watching workspace edits and surfacing changed files.",
                status: .waiting,
                lastUpdated: now.addingTimeInterval(-240)
            ),
            Agent(
                id: "agent-commands",
                name: "Command Runner",
                taskSummary: "Preparing mocked capture workflows for focused pages and selections.",
                status: .idle,
                lastUpdated: now.addingTimeInterval(-560)
            )
        ]
    }

    func seedActions() -> [AgentAction] {
        [
            AgentAction(
                agentID: "agent-design",
                eventName: .agentAction,
                title: "Expanded HUD drafted",
                detail: "Shell states now map to the agent, file, command, and stash surfaces.",
                timestamp: now.addingTimeInterval(-45)
            ),
            AgentAction(
                agentID: "agent-files",
                eventName: .filesChanged,
                title: "Recent files refreshed",
                detail: "Three workspace changes are ready for review.",
                timestamp: now.addingTimeInterval(-170)
            ),
            AgentAction(
                agentID: "agent-commands",
                eventName: .agentStatus,
                title: "Command handlers available",
                detail: "Focused page, selected text, and URL capture are mocked.",
                timestamp: now.addingTimeInterval(-420)
            )
        ]
    }

    func seedRecentFiles() -> [RecentFileChange] {
        [
            RecentFileChange(
                path: "Sources/ClickyHUD/Views/NotchShell.swift",
                changeType: .created,
                timestamp: now.addingTimeInterval(-80),
                agentID: "agent-design"
            ),
            RecentFileChange(
                path: "Sources/ClickyHUD/Stores/ClickyHUDStore.swift",
                changeType: .updated,
                timestamp: now.addingTimeInterval(-190),
                agentID: "agent-files"
            ),
            RecentFileChange(
                path: "Tests/ClickyHUDTests/StoreTests.swift",
                changeType: .created,
                timestamp: now.addingTimeInterval(-620),
                agentID: "agent-commands"
            )
        ]
    }
}
