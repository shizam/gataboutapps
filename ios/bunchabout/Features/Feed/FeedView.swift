import SwiftUI

struct FeedView: View {
    let eventRepository: EventRepository
    @State private var viewModel: FeedViewModel

    init(eventRepository: EventRepository, locationService: LocationService) {
        self.eventRepository = eventRepository
        _viewModel = State(initialValue: FeedViewModel(eventRepository: eventRepository, locationService: locationService))
    }

    var body: some View {
        Group {
            if viewModel.needsLocationPermission { locationPermissionView }
            else if viewModel.locationDenied { locationDeniedView }
            else if viewModel.feedEvents.isEmpty && !viewModel.isLoading { emptyFeedView }
            else { feedList }
        }
        .navigationTitle("Events Near You")
        .task {
            if viewModel.needsLocationPermission { viewModel.requestLocationPermission() }
            else { await viewModel.loadFeed() }
        }
    }

    private var feedList: some View {
        ScrollView {
            LazyVStack(spacing: Sizes.spacing12) {
                ForEach(viewModel.feedEvents) { event in
                    NavigationLink(value: event.id) {
                        EventCardView(event: event)
                    }.buttonStyle(.plain)
                }
                if viewModel.isLoading {
                    ProgressView().padding(Sizes.spacing16)
                }
                if viewModel.hasNextPage && !viewModel.isLoading {
                    Color.clear.frame(height: 1).task { await viewModel.loadNextPage() }
                }
            }
            .padding(.horizontal, Sizes.spacing16)
            .padding(.top, Sizes.spacing8)
        }
        .navigationDestination(for: String.self) { eventId in
            EventDetailView(eventId: eventId, eventRepository: eventRepository)
        }
    }

    private var locationPermissionView: some View {
        ContentUnavailableView {
            Label("Location Required", systemImage: "location")
        } description: {
            Text("bunchabout needs your location to find events near you.")
        } actions: {
            Button("Allow Location Access") { viewModel.requestLocationPermission() }
                .buttonStyle(.borderedProminent)
        }
    }

    private var locationDeniedView: some View {
        ContentUnavailableView {
            Label("Location Denied", systemImage: "location.slash")
        } description: { Text("Enable location access in Settings to find events near you.") }
    }

    private var emptyFeedView: some View {
        ContentUnavailableView {
            Label("No Events", systemImage: "calendar.badge.exclamationmark")
        } description: { Text("No events found near you. Check back later!") }
    }
}
