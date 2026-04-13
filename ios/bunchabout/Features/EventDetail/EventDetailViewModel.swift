import Foundation

@Observable
final class EventDetailViewModel {
    var event: Event?
    var isLoading = false
    var errorMessage: String?

    private let eventId: String
    private let eventRepository: EventRepository

    var confirmedParticipants: [EventParticipant] {
        event?.participants?.filter { $0.status == .confirmed } ?? []
    }

    init(eventId: String, eventRepository: EventRepository) {
        self.eventId = eventId
        self.eventRepository = eventRepository
        self.event = eventRepository.event(for: eventId)
    }

    func loadEvent() async {
        isLoading = true
        defer { isLoading = false }
        errorMessage = nil
        do { event = try await eventRepository.fetchEvent(id: eventId) }
        catch { errorMessage = error.localizedDescription }
    }
}
