import XCTest
@testable import ClickyHUD

@MainActor
final class StoreTests: XCTestCase {
    func testShellExpansionToggles() {
        let store = testStore()

        XCTAssertFalse(store.isShellExpanded)
        store.toggleShell()
        XCTAssertTrue(store.isShellExpanded)
    }

    func testSelectedAgentCanChange() {
        let store = testStore()
        let secondAgent = store.agents[1]

        store.selectAgent(secondAgent)

        XCTAssertEqual(store.selectedAgentID, secondAgent.id)
        XCTAssertEqual(store.selectedAgent?.id, secondAgent.id)
    }

    func testFocusedPageCommandTransitionsToSuccess() async {
        let store = testStore(commandService: MockCommandService(delayNanoseconds: 0))

        let result = await store.performCommand(.focusedPage)

        XCTAssertTrue(result.isSuccess)
        XCTAssertEqual(result.kind, .focusedPage)
        XCTAssertEqual(store.commandRunState, .finished(result))
        XCTAssertEqual(store.actions.first?.eventName, .agentAction)
    }

    func testURLCommandRejectsEmptyInput() async {
        let store = testStore(commandService: MockCommandService(delayNanoseconds: 0))
        store.urlInput = "   "

        let result = await store.performCommand(.pageByURL)

        XCTAssertFalse(result.isSuccess)
        XCTAssertEqual(result.message, "Enter a URL before saving a page.")
    }

    func testRecentFileFormatting() {
        let referenceDate = Date(timeIntervalSince1970: 1_000)
        let file = RecentFileChange(
            path: "Sources/ClickyHUD/App.swift",
            changeType: .updated,
            timestamp: referenceDate.addingTimeInterval(-125),
            agentID: "agent"
        )

        XCTAssertEqual(file.displayTimestamp(relativeTo: referenceDate), "2m ago")
        XCTAssertEqual(file.changeType.label, "Updated")
    }

    private func testStore(commandService: CommandService = MockCommandService(delayNanoseconds: 0)) -> ClickyHUDStore {
        ClickyHUDStore(
            commandService: commandService,
            stashService: MockStashService(),
            agentEventService: MockAgentEventService(now: Date(timeIntervalSince1970: 2_000))
        )
    }
}
