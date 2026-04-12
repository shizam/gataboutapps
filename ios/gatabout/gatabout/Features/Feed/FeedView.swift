import SwiftUI

struct FeedView: View {
    @State private var viewModel: FeedViewModel
    private let locationManager: LocationManager

    init(eventRepository: EventRepository, locationManager: LocationManager) {
        self.locationManager = locationManager
        _viewModel = State(initialValue: FeedViewModel(
            eventRepository: eventRepository,
            locationManager: locationManager
        ))
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.events.isEmpty {
                    ProgressView("Finding events near you...")
                } else if let error = viewModel.errorMessage, viewModel.events.isEmpty {
                    ErrorStateView(message: error) {
                        Task { await viewModel.retry() }
                    }
                } else if viewModel.events.isEmpty {
                    EmptyStateView(
                        systemImage: "calendar.badge.plus",
                        title: "No events nearby",
                        message: "Check back soon or expand your search radius."
                    )
                } else {
                    EventListView(
                        events: viewModel.events,
                        hasMorePages: viewModel.hasMorePages,
                        onLoadMore: viewModel.loadMore
                    )
                    .refreshable {
                        await viewModel.loadFeed()
                    }
                }
            }
            .navigationTitle("Events")
            .task {
                await viewModel.loadFeed()
            }
            .onChange(of: locationManager.currentLocation != nil) {
                if locationManager.currentLocation != nil && viewModel.events.isEmpty {
                    Task { await viewModel.loadFeed() }
                }
            }
        }
    }
}
