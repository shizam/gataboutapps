import Foundation
import CoreLocation

@Observable
final class FeedViewModel {
    var errorMessage: String?
    var testLocation: (lat: Double, lng: Double)?

    private let eventRepository: EventRepository
    private let locationService: LocationService

    var feedEvents: [Event] { eventRepository.feedEventIds.compactMap { eventRepository.event(for: $0) } }
    var isLoading: Bool { eventRepository.isLoadingFeed }
    var hasNextPage: Bool { eventRepository.feedPageInfo?.hasNextPage ?? false }
    var needsLocationPermission: Bool { locationService.needsPermissionRequest }
    var locationDenied: Bool { locationService.authorizationStatus == .denied }

    init(eventRepository: EventRepository, locationService: LocationService) {
        self.eventRepository = eventRepository
        self.locationService = locationService
    }

    func requestLocationPermission() { locationService.requestPermission() }

    func loadFeed() async {
        errorMessage = nil
        guard let location = resolveLocation() else {
            if !locationService.needsPermissionRequest { locationService.requestLocation() }
            return
        }
        do { try await eventRepository.fetchFeed(lat: location.lat, lng: location.lng) }
        catch { errorMessage = error.localizedDescription }
    }

    func loadNextPage() async {
        guard let cursor = eventRepository.feedPageInfo?.endCursor,
              let location = resolveLocation() else { return }
        do { try await eventRepository.fetchFeed(lat: location.lat, lng: location.lng, cursor: cursor) }
        catch { errorMessage = error.localizedDescription }
    }

    private func resolveLocation() -> (lat: Double, lng: Double)? {
        if let test = testLocation { return test }
        guard let coord = locationService.currentLocation else { return nil }
        return (coord.latitude, coord.longitude)
    }
}
