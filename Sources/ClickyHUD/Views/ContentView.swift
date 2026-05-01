import SwiftUI

struct ContentView: View {
    var store: ClickyHUDStore

    var body: some View {
        ZStack(alignment: .top) {
            ClickyTheme.appBackground
                .ignoresSafeArea()

            WorkspaceBackdrop(store: store)
                .padding(.top, store.isShellExpanded ? 88 : 72)
                .padding(.horizontal, 18)
                .padding(.bottom, 18)
                .blur(radius: store.isShellExpanded ? 1.4 : 0)
                .opacity(store.isShellExpanded ? 0.58 : 1)

            NotchShell(store: store)
                .padding(.top, 8)
        }
        .foregroundStyle(ClickyTheme.ink)
        .animation(.spring(response: 0.34, dampingFraction: 0.88), value: store.isShellExpanded)
    }
}

private struct WorkspaceBackdrop: View {
    var store: ClickyHUDStore

    var body: some View {
        HStack(spacing: 0) {
            BackdropRail(store: store)
                .frame(width: 230)

            VStack(spacing: 0) {
                BackdropToolbar(store: store)
                Divider()
                    .overlay(ClickyTheme.line)
                BackdropWorkstream(store: store)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(ClickyTheme.surface)
        }
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(ClickyTheme.line, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.12), radius: 28, x: 0, y: 20)
    }
}

private struct BackdropRail: View {
    var store: ClickyHUDStore

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 10) {
                ClickyMark(size: 28)
                VStack(alignment: .leading, spacing: 1) {
                    Text("Clicky")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.white)
                    Text("Agent workspace")
                        .font(.caption2)
                        .foregroundStyle(ClickyTheme.inverseMuted)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                RailItem(title: "Agents", systemImage: "sparkles", isSelected: true)
                RailItem(title: "Changed files", systemImage: "doc.text.magnifyingglass")
                RailItem(title: "Stash", systemImage: "tray.and.arrow.down")
                RailItem(title: "Commands", systemImage: "bolt")
            }

            Spacer()

            VStack(alignment: .leading, spacing: 8) {
                Text("\(store.activeAgentCount) active agents")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
                Text("Open the island to capture pages, route files, and inspect live agent work.")
                    .font(.caption)
                    .foregroundStyle(ClickyTheme.inverseMuted)
                    .lineLimit(3)
            }
            .padding(12)
            .background(Color.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .padding(18)
        .frame(maxHeight: .infinity)
        .background(ClickyTheme.rail)
    }
}

private struct RailItem: View {
    let title: String
    let systemImage: String
    var isSelected = false

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .frame(width: 16)
            Text(title)
                .lineLimit(1)
            Spacer()
        }
        .font(.callout.weight(isSelected ? .semibold : .regular))
        .foregroundStyle(isSelected ? .white : ClickyTheme.inverseMuted)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(isSelected ? Color.white.opacity(0.10) : .clear, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct BackdropToolbar: View {
    var store: ClickyHUDStore

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(store.selectedAgent?.name ?? "Clicky")
                    .font(.title3.weight(.semibold))
                Text(store.selectedAgent?.taskSummary ?? "Agent workspace")
                    .font(.caption)
                    .foregroundStyle(ClickyTheme.textMuted)
                    .lineLimit(1)
            }

            Spacer()

            Button {
                store.toggleShell()
            } label: {
                Label("Open island", systemImage: "rectangle.expand.vertical")
            }
            .buttonStyle(.borderedProminent)
            .tint(ClickyTheme.ink)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 15)
        .background(ClickyTheme.surface)
    }
}

private struct BackdropWorkstream: View {
    var store: ClickyHUDStore

    var body: some View {
        HStack(alignment: .top, spacing: 18) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Live agent thread")
                    .font(.headline.weight(.semibold))

                ForEach(store.actions.prefix(3)) { action in
                    HStack(alignment: .top, spacing: 12) {
                        ClickyEventGlyph(eventName: action.eventName)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(action.title)
                                .font(.callout.weight(.semibold))
                            Text(action.detail)
                                .font(.caption)
                                .foregroundStyle(ClickyTheme.textMuted)
                                .lineLimit(2)
                        }
                        Spacer()
                        Text(ClickyFormatters.relativeTime(action.timestamp))
                            .font(.caption2)
                            .foregroundStyle(ClickyTheme.textMuted)
                    }
                    .padding(12)
                    .clickyInsetPanel()
                }
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)

            VStack(alignment: .leading, spacing: 12) {
                Text("Recent files")
                    .font(.headline.weight(.semibold))

                ForEach(store.recentFiles.prefix(3)) { file in
                    HStack(spacing: 9) {
                        Image(systemName: "doc")
                            .foregroundStyle(ClickyTheme.accent)
                        VStack(alignment: .leading, spacing: 2) {
                            Text((file.path as NSString).lastPathComponent)
                                .font(.caption.weight(.semibold))
                                .lineLimit(1)
                            Text(file.changeType.label)
                                .font(.caption2)
                                .foregroundStyle(ClickyTheme.textMuted)
                        }
                        Spacer()
                    }
                    .padding(10)
                    .clickyInsetPanel()
                }
            }
            .frame(width: 260, alignment: .topLeading)
        }
        .padding(20)
    }
}

struct ClickyMark: View {
    let size: CGFloat

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
                .fill(.white)
            Image(systemName: "cursorarrow.click.2")
                .font(.system(size: size * 0.48, weight: .bold))
                .foregroundStyle(ClickyTheme.ink)
        }
        .frame(width: size, height: size)
    }
}

struct ClickyEventGlyph: View {
    let eventName: ClickyEventName

    var body: some View {
        ZStack {
            Circle()
                .fill(color.opacity(0.16))
            Image(systemName: icon)
                .font(.caption.weight(.bold))
                .foregroundStyle(color)
        }
        .frame(width: 30, height: 30)
    }

    private var icon: String {
        switch eventName {
        case .agentStatus: "antenna.radiowaves.left.and.right"
        case .agentAction: "sparkles"
        case .filesChanged: "doc.text"
        case .stashUpdated: "tray.and.arrow.down"
        }
    }

    private var color: Color {
        switch eventName {
        case .agentStatus: ClickyTheme.violet
        case .agentAction: ClickyTheme.accent
        case .filesChanged: ClickyTheme.accentSecondary
        case .stashUpdated: ClickyTheme.success
        }
    }
}
