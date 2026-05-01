import Foundation

protocol CommandService: Sendable {
    func saveFocusedPage() async -> CommandResult
    func saveSelectedText() async -> CommandResult
    func savePageByURL(_ url: URL) async -> CommandResult
}

protocol StashService: Sendable {
    func validateFile(at url: URL) throws -> StashValidation
    func addFile(at url: URL) async throws -> StashItem
    func removeFile(_ item: StashItem) async throws
}

protocol AgentEventService: Sendable {
    func seedAgents() -> [Agent]
    func seedActions() -> [AgentAction]
    func seedRecentFiles() -> [RecentFileChange]
}

struct StashValidation: Equatable {
    var fileName: String
    var fileExtension: String
    var sizeInBytes: Int64
}

enum StashError: LocalizedError, Equatable {
    case directoryNotAllowed
    case unsupportedFileType(String)
    case fileTooLarge(maximumBytes: Int64)
    case unreadableFile

    var errorDescription: String? {
        switch self {
        case .directoryNotAllowed:
            "Folders are not supported in the MVP stash."
        case let .unsupportedFileType(fileExtension):
            "Unsupported file type: .\(fileExtension.isEmpty ? "none" : fileExtension)."
        case let .fileTooLarge(maximumBytes):
            "File exceeds the \(ByteCountFormatter.string(fromByteCount: maximumBytes, countStyle: .file)) limit."
        case .unreadableFile:
            "The file could not be read."
        }
    }
}
