import Foundation

enum ClickyFormatters {
    static func relativeTime(_ date: Date, relativeTo referenceDate: Date = Date()) -> String {
        let seconds = max(0, Int(referenceDate.timeIntervalSince(date)))
        switch seconds {
        case 0..<60:
            return "\(seconds)s ago"
        case 60..<3_600:
            return "\(seconds / 60)m ago"
        case 3_600..<86_400:
            return "\(seconds / 3_600)h ago"
        default:
            return "\(seconds / 86_400)d ago"
        }
    }

    static func bytes(_ count: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: count, countStyle: .file)
    }
}

extension RecentFileChange {
    func displayTimestamp(relativeTo referenceDate: Date = Date()) -> String {
        ClickyFormatters.relativeTime(timestamp, relativeTo: referenceDate)
    }
}
