import Foundation

extension String {
    var toDate: Date? {
        Self.iso8601Formatter.date(from: self)
    }
    private static let iso8601Formatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
}

extension Date {
    var relativeDisplay: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: self, relativeTo: .now)
    }
    var shortDisplay: String {
        formatted(date: .abbreviated, time: .shortened)
    }
}
