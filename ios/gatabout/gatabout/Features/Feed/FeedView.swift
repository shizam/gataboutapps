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
                    errorView(error)
                } else if viewModel.events.isEmpty {
                    emptyView
                } else {
                    eventList
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

    private var eventList: some View {
        ScrollView {
            LazyVStack(spacing: Sizes.spacing12) {
                ForEach(viewModel.events) { edge in
                    EventCardView(edge: edge)
                }

                if viewModel.hasMorePages {
                    ProgressView()
                        .padding(Sizes.padding16)
                        .task {
                            await viewModel.loadMore()
                        }
                }
            }
            .padding(.horizontal, Sizes.padding16)
            .padding(.vertical, Sizes.padding8)
        }
        .refreshable {
            await viewModel.loadFeed()
        }
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: Sizes.spacing16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: Sizes.iconSize40))
                .foregroundStyle(.secondary)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Retry") {
                Task { await viewModel.retry() }
            }
            .buttonStyle(.bordered)
        }
        .padding(Sizes.padding32)
    }

    private var emptyView: some View {
        VStack(spacing: Sizes.spacing16) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: Sizes.iconSize40))
                .foregroundStyle(.secondary)
            Text("No events nearby")
                .font(.headline)
            Text("Check back soon or expand your search radius.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(Sizes.padding32)
    }
}
