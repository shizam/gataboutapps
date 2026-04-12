import SwiftUI

struct MainTabView: View {
    @Environment(EventRepository.self) private var eventRepository
    @Environment(LocationService.self) private var locationService

    var body: some View {
        TabView {
            Tab("Feed", systemImage: "magnifyingglass") {
                NavigationStack {
                    FeedView(eventRepository: eventRepository, locationService: locationService)
                }
            }
            Tab("Profile", systemImage: "person") {
                NavigationStack {
                    ProfileView()
                }
            }
        }
    }
}
