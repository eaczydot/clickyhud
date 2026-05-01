import SwiftUI

struct NotchShell: View {
    var store: ClickyHUDStore

    var body: some View {
        VStack(spacing: 0) {
            islandHeader

            if store.isShellExpanded {
                AgentHUD(store: store)
                    .padding(12)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .frame(width: store.isShellExpanded ? 1040 : 430)
        .background(ClickyTheme.ink, in: UnevenRoundedRectangle(
            topLeadingRadius: 0,
            bottomLeadingRadius: store.isShellExpanded ? 28 : ClickyTheme.notchRadius,
            bottomTrailingRadius: store.isShellExpanded ? 28 : ClickyTheme.notchRadius,
            topTrailingRadius: 0,
            style: .continuous
        ))
        .overlay(
            UnevenRoundedRectangle(
                topLeadingRadius: 0,
                bottomLeadingRadius: store.isShellExpanded ? 28 : ClickyTheme.notchRadius,
                bottomTrailingRadius: store.isShellExpanded ? 28 : ClickyTheme.notchRadius,
                topTrailingRadius: 0,
                style: .continuous
            )
            .stroke(ClickyTheme.inverseLine, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.30), radius: 28, x: 0, y: 18)
    }

    private var islandHeader: some View {
        Button {
            store.toggleShell()
        } label: {
            HStack(spacing: 12) {
                ClickyMark(size: 26)

                VStack(alignment: .leading, spacing: 1) {
                    Text("Clicky")
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(.white)
                    Text(headerSubtitle)
                        .font(.caption2)
                        .foregroundStyle(ClickyTheme.inverseMuted)
                        .lineLimit(1)
                }

                Spacer(minLength: 12)

                IslandMetric(value: "\(store.activeAgentCount)", label: "agents", systemImage: "sparkles")
                IslandMetric(value: "\(store.recentFiles.count)", label: "files", systemImage: "doc.text")
                IslandMetric(value: "\(store.stashItems.count)", label: "stash", systemImage: "tray")

                Image(systemName: store.isShellExpanded ? "chevron.up" : "chevron.down")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(ClickyTheme.inverseMuted)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 11)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(store.isShellExpanded ? "Collapse Clicky interface island" : "Expand Clicky interface island")
    }

    private var headerSubtitle: String {
        if let agent = store.selectedAgent {
            "\(agent.name) - \(agent.status.label)"
        } else {
            "\(store.activeAgentCount) active agents"
        }
    }
}

private struct IslandMetric: View {
    let value: String
    let label: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage)
                .font(.caption2.weight(.semibold))
            Text(value)
                .font(.caption.weight(.bold))
            Text(label)
                .font(.caption2)
                .foregroundStyle(ClickyTheme.inverseMuted)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 9)
        .padding(.vertical, 6)
        .background(Color.white.opacity(0.08), in: Capsule())
    }
}

struct CommandButton: View {
    let kind: CommandKind
    var store: ClickyHUDStore
    var compact = false
    var isInverse = false

    private var isRunning: Bool {
        store.commandRunState.runningKind == kind
    }

    var body: some View {
        Button {
            store.runCommand(kind)
        } label: {
            Label(isRunning ? "Running" : (compact ? "Save" : kind.label), systemImage: isRunning ? "progress.indicator" : kind.systemImage)
                .labelStyle(.titleAndIcon)
                .lineLimit(1)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(ClickyCommandButtonStyle(isInverse: isInverse))
        .disabled(isRunning)
        .accessibilityLabel(kind.label)
    }
}

private struct ClickyCommandButtonStyle: ButtonStyle {
    var isInverse: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.caption.weight(.semibold))
            .foregroundStyle(isInverse ? ClickyTheme.ink : .white)
            .padding(.horizontal, 10)
            .padding(.vertical, 9)
            .background(
                isInverse ? Color.white.opacity(configuration.isPressed ? 0.84 : 0.96) : Color.white.opacity(configuration.isPressed ? 0.16 : 0.10),
                in: RoundedRectangle(cornerRadius: 8, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(isInverse ? Color.black.opacity(0.08) : ClickyTheme.inverseLine, lineWidth: 1)
            )
    }
}
