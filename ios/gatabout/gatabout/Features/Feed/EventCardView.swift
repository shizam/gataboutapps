import SwiftUI

struct EventCardView: View {
    let event: Event

    var body: some View {
        VStack(alignment: .leading, spacing: Sizes.spacing8) {
            HStack {
                Label(event.category.displayName, systemImage: event.category.systemImage)
                    .font(.caption).foregroundStyle(AppColors.primary)
                Spacer()
                if let date = event.date.toDate {
                    Text(date.shortDisplay).captionStyle()
                }
            }

            Text(event.title).headlineStyle().lineLimit(2)

            if let locationName = event.location?.name {
                Label(locationName, systemImage: "mappin")
                    .font(.subheadline).foregroundStyle(.secondary).lineLimit(1)
            }

            HStack {
                if let organizer = event.organizer {
                    Label(organizer.displayName, systemImage: "person")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                if let remaining = event.slotsRemaining, let total = event.totalSlots {
                    Text("\(remaining)/\(total) spots")
                        .font(.caption.bold())
                        .foregroundStyle(remaining > 0 ? AppColors.primary : AppColors.error)
                }
            }
        }
        .padding(Sizes.spacing16)
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: Sizes.cornerRadius12))
    }
}
