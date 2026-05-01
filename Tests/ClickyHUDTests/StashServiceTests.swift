import XCTest
@testable import ClickyHUD

final class StashServiceTests: XCTestCase {
    func testAcceptsSupportedFile() throws {
        let url = try temporaryFile(named: "note.md", bytes: 12)
        let service = MockStashService()

        let validation = try service.validateFile(at: url)

        XCTAssertEqual(validation.fileName, "note.md")
        XCTAssertEqual(validation.fileExtension, "md")
        XCTAssertEqual(validation.sizeInBytes, 12)
    }

    func testRejectsUnsupportedExtension() throws {
        let url = try temporaryFile(named: "archive.zip", bytes: 12)
        let service = MockStashService()

        XCTAssertThrowsError(try service.validateFile(at: url)) { error in
            XCTAssertEqual(error as? StashError, .unsupportedFileType("zip"))
        }
    }

    func testRejectsOversizedFile() throws {
        let url = try temporaryFile(named: "large.txt", bytes: 20)
        let service = MockStashService(maximumFileSize: 10)

        XCTAssertThrowsError(try service.validateFile(at: url)) { error in
            XCTAssertEqual(error as? StashError, .fileTooLarge(maximumBytes: 10))
        }
    }

    private func temporaryFile(named name: String, bytes: Int) throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appendingPathComponent(name)
        try Data(repeating: 0x41, count: bytes).write(to: url)
        addTeardownBlock {
            try? FileManager.default.removeItem(at: directory)
        }
        return url
    }
}
