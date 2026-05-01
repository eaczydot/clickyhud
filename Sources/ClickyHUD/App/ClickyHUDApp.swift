import SwiftUI

@main
struct ClickyHUDApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var store = ClickyHUDStore.mocked()

    var body: some Scene {
        WindowGroup("ClickyHUD") {
            ContentView(store: store)
                .frame(minWidth: 980, minHeight: 660)
                .preferredColorScheme(.dark)
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandMenu("ClickyHUD") {
                Button(store.isShellExpanded ? "Collapse HUD" : "Expand HUD") {
                    store.toggleShell()
                }
                .keyboardShortcut("h", modifiers: [.command, .shift])

                Button("Save Focused Page") {
                    store.runCommand(.focusedPage)
                }
                .keyboardShortcut("1", modifiers: [.command, .shift])

                Button("Save Selected Text") {
                    store.runCommand(.selectedText)
                }
                .keyboardShortcut("2", modifiers: [.command, .shift])
            }
        }
    }
}
