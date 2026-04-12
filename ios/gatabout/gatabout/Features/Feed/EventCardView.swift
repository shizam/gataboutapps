import SwiftUI

struct EventCardView: View {
    let edge: EventEdge

    private var event: Event { edge.node }

    var body: some View {
        VStack(alignment: .leading, spacing: Sizes.spacing8) {
            // Category + Status
            HStack(spacing: Sizes.spacing8) {
                Label(event.category.displayName, systemImage: event.category.systemImage)
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, Sizes.padding8)
                    .padding(.vertical, Sizes.padding4)
                    .background(.tint.opacity(0.1))
                    .clipShape(Capsule())

                Spacer()

                Text(event.fillMode.shortName)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
            }

            // Title
            Text(event.title)
                .font(.headline)
                .lineLimit(2)

            // Date + Time
            HStack(spacing: Sizes.spacing4) {
                Image(systemName: "calendar")
                    .font(.system(size: Sizes.iconSize16))
                    .accessibilityHidden(true)
                Text(Self.formatDate(event.date))
                if let time = event.time {
                    Text("at \(time)")
                }
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)

            // Location + Distance
            HStack(spacing: Sizes.spacing4) {
                Image(systemName: "mappin")
                    .font(.system(size: Sizes.iconSize16))
                    .accessibilityHidden(true)
                if let location = event.location {
                    Text(location.name)
                        .lineLimit(1)
                }
                if let distance = edge.distance {
                    Text("·")
                    Text(Self.formatDistance(distance))
                }
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)

            // Bottom row: Slots + Organizer
            HStack {
                Label("\(event.slotsRemaining)/\(event.totalSlots) spots",
                      systemImage: "person.2")
                    .font(.caption)
                    .foregroundStyle(event.slotsRemaining > 0 ? Color.primary : Color.red)

                Spacer()

                Text("by \(event.organizer.displayName)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(Sizes.padding16)
        .background(.background)
        .clipShape(.rect(cornerRadius: Sizes.cornerRadius12))
        .shadow(color: .black.opacity(0.08), radius: Sizes.shadowRadius4, y: Sizes.shadowOffset2)
    }

    private static func formatDistance(_ miles: Double) -> String {
        if miles < 0.1 {
            return "Nearby"
        } else if miles < 10 {
            return String(format: "%.1f mi", miles)
        } else {
            return String(format: "%.0f mi", miles)
        }
    }

    private static func formatDate(_ isoString: String) -> String {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = isoFormatter.date(from: isoString) else {
            // Try without fractional seconds
            isoFormatter.formatOptions = [.withInternetDateTime]
            guard let date = isoFormatter.date(from: isoString) else {
                return isoString
            }
            return Self.displayFormatter.string(from: date)
        }
        return displayFormatter.string(from: date)
    }

    private static let displayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f
    }()
}
