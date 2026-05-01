import SwiftUI

enum ClickyTheme {
    static let appBackground = LinearGradient(
        colors: [
            Color(red: 0.955, green: 0.948, blue: 0.932),
            Color(red: 0.898, green: 0.914, blue: 0.908)
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    static let ink = Color(red: 0.055, green: 0.058, blue: 0.055)
    static let inkSoft = Color(red: 0.11, green: 0.115, blue: 0.105)
    static let canvas = Color(red: 0.965, green: 0.958, blue: 0.94)
    static let surface = Color(red: 0.985, green: 0.98, blue: 0.968)
    static let elevated = Color.white.opacity(0.86)
    static let rail = Color(red: 0.08, green: 0.082, blue: 0.076)
    static let panel = Color.black.opacity(0.045)
    static let panelStrong = Color.black.opacity(0.075)
    static let line = Color.black.opacity(0.11)
    static let inverseLine = Color.white.opacity(0.13)
    static let textMuted = Color.black.opacity(0.54)
    static let inverseMuted = Color.white.opacity(0.58)
    static let accent = Color(red: 0.22, green: 0.72, blue: 0.52)
    static let accentSecondary = Color(red: 0.93, green: 0.62, blue: 0.24)
    static let violet = Color(red: 0.45, green: 0.40, blue: 0.88)
    static let error = Color(red: 0.86, green: 0.18, blue: 0.17)
    static let success = Color(red: 0.20, green: 0.62, blue: 0.36)

    static let radius: CGFloat = 8
    static let notchRadius: CGFloat = 22

    static func statusColor(_ status: AgentStatus) -> Color {
        switch status {
        case .idle: Color.black.opacity(0.34)
        case .running: accent
        case .waiting: accentSecondary
        case .error: error
        }
    }
}

extension View {
    func clickyPanel(cornerRadius: CGFloat = ClickyTheme.radius) -> some View {
        self
            .background(ClickyTheme.elevated, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(ClickyTheme.line, lineWidth: 1)
            )
    }

    func clickyInsetPanel(cornerRadius: CGFloat = ClickyTheme.radius) -> some View {
        self
            .background(ClickyTheme.panel, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(ClickyTheme.line, lineWidth: 1)
            )
    }
}
