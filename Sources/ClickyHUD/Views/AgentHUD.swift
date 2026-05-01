import SwiftUI
import UniformTypeIdentifiers

struct AgentHUD: View {
    var store: ClickyHUDStore

    var body: some View {
        HStack(spacing: 0) {
            AgentRail(store: store)
                .frame(width: 245)

            Divider()
                .overlay(ClickyTheme.inverseLine)

            WorkstreamPanel(store: store)
                .frame(maxWidth: .infinity)

            Divider()
                .overlay(ClickyTheme.inverseLine)

            UtilityPanel(store: store)
                .frame(width: 300)
        }
        .frame(height: 560)
        .background(Color.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(ClickyTheme.inverseLine, lineWidth: 1)
        )
    }
}

private struct AgentRail: View {
    var store: ClickyHUDStore

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            PanelTitle(title: "Workspace", detail: "Live Clicky agents", systemImage: "sidebar.left")

            VStack(spacing: 7) {
                ForEach(store.agents) { agent in
                    AgentRow(agent: agent, isSelected: store.selectedAgentID == agent.id) {
                        store.selectAgent(agent)
                    }
                }
            }

            Spacer(minLength: 12)

            VStack(alignment: .leading, spacing: 10) {
                Text("BoringNotch controls")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)

                MiniFeature(label: "Top island", systemImage: "capsule")
                MiniFeature(label: "One-click capture", systemImage: "bolt")
                MiniFeature(label: "Drag stash", systemImage: "tray.and.arrow.down")
            }
            .padding(12)
            .background(Color.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .padding(14)
    }
}

private struct AgentRow: View {
    let agent: Agent
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 10) {
                Circle()
                    .fill(ClickyTheme.statusColor(agent.status))
                    .frame(width: 8, height: 8)
                    .padding(.top, 6)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(agent.name)
                            .font(.callout.weight(.semibold))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                        Spacer()
                        Text(agent.status.label)
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(ClickyTheme.statusColor(agent.status))
                            .lineLimit(1)
                    }

                    Text(agent.taskSummary)
                        .font(.caption)
                        .foregroundStyle(ClickyTheme.inverseMuted)
                        .lineLimit(2)

                    Text(ClickyFormatters.relativeTime(agent.lastUpdated))
                        .font(.caption2)
                        .foregroundStyle(Color.white.opacity(0.34))
                }
            }
            .padding(10)
            .background(isSelected ? Color.white.opacity(0.12) : Color.white.opacity(0.045), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(isSelected ? Color.white.opacity(0.18) : Color.white.opacity(0.06), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(agent.name), \(agent.status.label)")
    }
}

private struct WorkstreamPanel: View {
    var store: ClickyHUDStore

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(store.selectedAgent?.name ?? "Agent thread")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.white)
                    Text(store.selectedAgent?.taskSummary ?? "Select an agent to inspect its activity.")
                        .font(.caption)
                        .foregroundStyle(ClickyTheme.inverseMuted)
                        .lineLimit(2)
                }

                Spacer()

                StatusPill(status: store.selectedAgent?.status ?? .idle)
            }

            QuickCaptureBar(store: store)

            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach(store.selectedAgentActions) { action in
                        ActivityBubble(action: action, agentName: store.displayName(for: action.agentID))
                    }
                }
                .padding(.bottom, 4)
            }
        }
        .padding(16)
    }
}

private struct QuickCaptureBar: View {
    var store: ClickyHUDStore

    var body: some View {
        HStack(spacing: 8) {
            CommandButton(kind: .focusedPage, store: store, compact: true)
            CommandButton(kind: .selectedText, store: store, compact: true)

            HStack(spacing: 8) {
                Image(systemName: "link")
                    .foregroundStyle(ClickyTheme.inverseMuted)
                TextField("Paste URL into Clicky", text: Bindable(store).urlInput)
                    .textFieldStyle(.plain)
                    .font(.caption)
                    .foregroundStyle(.white)
                    .onSubmit {
                        store.runCommand(.pageByURL)
                    }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 9)
            .background(Color.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(ClickyTheme.inverseLine, lineWidth: 1)
            )

            CommandButton(kind: .pageByURL, store: store, compact: true)
                .frame(width: 82)
        }
    }
}

private struct ActivityBubble: View {
    let action: AgentAction
    let agentName: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ClickyEventGlyph(eventName: action.eventName)

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(action.title)
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    Spacer()
                    Text(ClickyFormatters.relativeTime(action.timestamp))
                        .font(.caption2)
                        .foregroundStyle(Color.white.opacity(0.35))
                }

                Text(action.detail)
                    .font(.caption)
                    .foregroundStyle(ClickyTheme.inverseMuted)
                    .lineLimit(3)

                HStack(spacing: 8) {
                    Text(agentName)
                    Text(action.eventName.rawValue)
                }
                .font(.caption2.monospaced())
                .foregroundStyle(Color.white.opacity(0.42))
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.white.opacity(0.07), lineWidth: 1)
        )
    }
}

private struct UtilityPanel: View {
    var store: ClickyHUDStore

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            PanelTitle(title: "Capture", detail: "Page, text, URL, files", systemImage: "bolt")

            CommandResultCard(state: store.commandRunState)

            Divider()
                .overlay(ClickyTheme.inverseLine)

            RecentFilesList(store: store)

            Divider()
                .overlay(ClickyTheme.inverseLine)

            StashDropzone(store: store)
        }
        .padding(14)
    }
}

private struct RecentFilesList: View {
    var store: ClickyHUDStore

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Changed files")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
                Spacer()
                Text("\(store.recentFiles.count)")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(ClickyTheme.ink)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(.white, in: Capsule())
            }

            ForEach(store.recentFiles.prefix(3)) { file in
                HStack(spacing: 9) {
                    Image(systemName: icon(for: file.changeType))
                        .font(.caption)
                        .foregroundStyle(color(for: file.changeType))
                        .frame(width: 16)

                    VStack(alignment: .leading, spacing: 2) {
                        Text((file.path as NSString).lastPathComponent)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                        Text("\(file.changeType.label) by \(store.displayName(for: file.agentID))")
                            .font(.caption2)
                            .foregroundStyle(ClickyTheme.inverseMuted)
                            .lineLimit(1)
                    }

                    Spacer()
                }
                .padding(9)
                .background(Color.white.opacity(0.045), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
        }
    }
}

private struct StashDropzone: View {
    var store: ClickyHUDStore
    @State private var isTargeted = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Agent stash")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
                Spacer()
                Text("\(store.stashItems.count)")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(ClickyTheme.ink)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(.white, in: Capsule())
            }

            VStack(spacing: 7) {
                Image(systemName: "arrow.down.doc")
                    .font(.title3)
                    .foregroundStyle(isTargeted ? ClickyTheme.accent : ClickyTheme.inverseMuted)
                Text("Drop files into Clicky")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
                Text("Text, PDFs, images, source files")
                    .font(.caption2)
                    .foregroundStyle(ClickyTheme.inverseMuted)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, minHeight: 94)
            .background(isTargeted ? ClickyTheme.accent.opacity(0.18) : Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [5]))
                    .foregroundStyle(isTargeted ? ClickyTheme.accent : ClickyTheme.inverseLine)
            )
            .onDrop(of: [.fileURL], isTargeted: $isTargeted) { providers in
                handleDrop(providers)
            }

            if let message = store.stashMessage {
                Text(message)
                    .font(.caption2)
                    .foregroundStyle(message.lowercased().contains("added") || message.lowercased().contains("removed") ? ClickyTheme.success : ClickyTheme.error)
                    .lineLimit(2)
            }

            ForEach(store.stashItems.prefix(2)) { item in
                HStack(spacing: 8) {
                    Image(systemName: "doc")
                        .foregroundStyle(ClickyTheme.accent)
                    Text(item.fileName)
                        .font(.caption)
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    Spacer()
                    Button {
                        store.removeStashItem(item)
                    } label: {
                        Image(systemName: "xmark")
                            .font(.caption2.weight(.bold))
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(ClickyTheme.inverseMuted)
                }
                .padding(8)
                .background(Color.white.opacity(0.045), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
        }
    }

    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        var accepted = false
        for provider in providers where provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
            accepted = true
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
                let url: URL?
                if let data = item as? Data {
                    url = URL(dataRepresentation: data, relativeTo: nil)
                } else {
                    url = item as? URL
                }

                if let url {
                    Task { @MainActor in
                        store.addStashFiles(from: [url])
                    }
                }
            }
        }
        return accepted
    }
}

private struct CommandResultCard: View {
    let state: CommandRunState

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            switch state {
            case .idle:
                Label("Ready for capture", systemImage: "checkmark.circle")
                    .foregroundStyle(.white)
                Text("Clicky will stage artifacts here before handing them to an agent.")
                    .foregroundStyle(ClickyTheme.inverseMuted)
            case let .running(kind):
                HStack(spacing: 8) {
                    ProgressView()
                        .scaleEffect(0.7)
                    Text(kind.label)
                        .foregroundStyle(.white)
                }
                Text("Running through the mocked command service.")
                    .foregroundStyle(ClickyTheme.inverseMuted)
            case let .finished(result):
                Label(result.isSuccess ? "Captured" : "Needs input", systemImage: result.isSuccess ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .foregroundStyle(result.isSuccess ? ClickyTheme.success : ClickyTheme.error)
                Text(result.message)
                    .foregroundStyle(ClickyTheme.inverseMuted)
            }
        }
        .font(.caption)
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(ClickyTheme.inverseLine, lineWidth: 1)
        )
    }
}

private struct PanelTitle: View {
    let title: String
    let detail: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.caption.weight(.bold))
                .foregroundStyle(ClickyTheme.ink)
                .frame(width: 24, height: 24)
                .background(.white, in: RoundedRectangle(cornerRadius: 7, style: .continuous))

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(.white)
                Text(detail)
                    .font(.caption2)
                    .foregroundStyle(ClickyTheme.inverseMuted)
            }

            Spacer()
        }
    }
}

private struct MiniFeature: View {
    let label: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
                .frame(width: 16)
            Text(label)
                .lineLimit(1)
            Spacer()
        }
        .font(.caption)
        .foregroundStyle(ClickyTheme.inverseMuted)
    }
}

private struct StatusPill: View {
    let status: AgentStatus

    var body: some View {
        HStack(spacing: 7) {
            Circle()
                .fill(ClickyTheme.statusColor(status))
                .frame(width: 7, height: 7)
            Text(status.label)
                .font(.caption.weight(.semibold))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(Color.white.opacity(0.08), in: Capsule())
    }
}

private func icon(for changeType: FileChangeType) -> String {
    switch changeType {
    case .created: "plus.circle.fill"
    case .updated: "arrow.triangle.2.circlepath.circle.fill"
    case .deleted: "minus.circle.fill"
    }
}

private func color(for changeType: FileChangeType) -> Color {
    switch changeType {
    case .created: ClickyTheme.success
    case .updated: ClickyTheme.accent
    case .deleted: ClickyTheme.error
    }
}
