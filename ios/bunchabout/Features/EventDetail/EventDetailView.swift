import SwiftUI

struct EventDetailView: View {
    @State private var viewModel: EventDetailViewModel

    init(eventId: String, eventRepository: EventRepository) {
        _viewModel = State(initialValue: EventDetailViewModel(eventId: eventId, eventRepository: eventRepository))
    }

    var body: some View {
        Group {
            if let event = viewModel.event { eventContent(event) }
            else if viewModel.isLoading { ProgressView() }
            else if let error = viewModel.errorMessage {
                ContentUnavailableView {
                    Label("Error", systemImage: "exclamationmark.triangle")
                } description: { Text(error) }
            }
        }
        .navigationTitle(viewModel.event?.title ?? "Event")
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.loadEvent() }
    }

    private func eventContent(_ event: Event) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Sizes.spacing16) {
                HStack {
                    Label(event.category.displayName, systemImage: event.category.systemImage)
                        .font(.subheadline).foregroundStyle(AppColors.primary)
                    Spacer()
                    if let status = event.status {
                        Text(statusText(status))
                            .font(.caption.bold())
                            .padding(.horizontal, Sizes.spacing8)
                            .padding(.vertical, Sizes.spacing4)
                            .background(statusColor(status).opacity(0.15))
                            .foregroundStyle(statusColor(status))
                            .clipShape(Capsule())
                    }
                }

                Text(event.title).font(.title2.bold())

                if let date = event.date.toDate {
                    Label(date.shortDisplay, systemImage: "calendar").foregroundStyle(.secondary)
                }
                if let duration = event.duration {
                    Label("\(duration) min", systemImage: "clock").foregroundStyle(.secondary)
                }

                if let location = event.location {
                    Label(location.name, systemImage: "mappin")
                    if let address = location.address {
                        Text(address).font(.caption).foregroundStyle(.secondary)
                            .padding(.leading, Sizes.spacing32)
                    }
                }

                if let description = event.description {
                    Text(description).padding(.top, Sizes.spacing8)
                }

                Divider()

                if let remaining = event.slotsRemaining, let total = event.totalSlots {
                    HStack {
                        Text("Spots").font(.headline)
                        Spacer()
                        Text("\(remaining) of \(total) available")
                            .foregroundStyle(remaining > 0 ? .primary : AppColors.error)
                    }
                }

                if let organizer = event.organizer {
                    VStack(alignment: .leading, spacing: Sizes.spacing8) {
                        Text("Organizer").font(.headline)
                        HStack(spacing: Sizes.spacing12) {
                            Image(systemName: "person.circle.fill").font(.title).foregroundStyle(.secondary)
                            Text(organizer.displayName)
                        }
                    }
                }

                if !viewModel.confirmedParticipants.isEmpty {
                    VStack(alignment: .leading, spacing: Sizes.spacing8) {
                        Text("Participants (\(viewModel.confirmedParticipants.count))").font(.headline)
                        ForEach(viewModel.confirmedParticipants) { participant in
                            HStack(spacing: Sizes.spacing12) {
                                Image(systemName: "person.circle").foregroundStyle(.secondary)
                                Text(participant.user.displayName)
                                if participant.slotType == .organizer {
                                    Text("Organizer").font(.caption).foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            .padding(Sizes.spacing16)
        }
    }

    private func statusText(_ status: EventStatus) -> String {
        switch status {
        case .open: "Open"
        case .full: "Full"
        case .inProgress: "In Progress"
        case .completed: "Completed"
        case .cancelled: "Cancelled"
        }
    }

    private func statusColor(_ status: EventStatus) -> Color {
        switch status {
        case .open: .green
        case .full: .orange
        case .inProgress: .blue
        case .completed: .secondary
        case .cancelled: .red
        }
    }
}
