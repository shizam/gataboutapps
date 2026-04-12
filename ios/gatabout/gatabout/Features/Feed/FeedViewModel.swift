import CoreLocation
import Observation

@Observable
@MainActor
final class FeedViewModel {
    private(set) var events: [EventEdge] = []
    private(set) var isLoading = false
    private(set) var isLoadingMore = false
    private(set) var errorMessage: String?
    private(set) var hasMorePages = false

    private let eventRepository: EventRepository
    private let locationManager: LocationManager
    private var endCursor: String?

    init(eventRepository: EventRepository, locationManager: LocationManager) {
        self.eventRepository = eventRepository
        self.locationManager = locationManager
    }

    func loadFeed() async {
        guard let location = locationManager.currentLocation else {
            if locationManager.needsPermissionRequest {
                locationManager.requestPermission()
            } else if locationManager.hasPermission {
                locationManager.requestLocation()
            } else {
                errorMessage = "Location access is required to find events near you. Please enable it in Settings."
            }
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let connection = try await eventRepository.feed(
                lat: location.latitude,
                lng: location.longitude
            )
            events = connection.edges
            endCursor = connection.pageInfo.endCursor
            hasMorePages = connection.pageInfo.hasNextPage
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func loadMore() async {
        guard hasMorePages, !isLoadingMore, let cursor = endCursor,
              let location = locationManager.currentLocation else { return }

        isLoadingMore = true

        do {
            let connection = try await eventRepository.feed(
                lat: location.latitude,
                lng: location.longitude,
                cursor: cursor
            )
            events.append(contentsOf: connection.edges)
            endCursor = connection.pageInfo.endCursor
            hasMorePages = connection.pageInfo.hasNextPage
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoadingMore = false
    }

    func retry() async {
        await loadFeed()
    }
}
