import SwiftUI
import FirebaseCore

@main
struct gataboutApp: App {
    let authService: AuthService
    let graphQLClient: GraphQLClient
    let userRepository: UserRepository
    let eventRepository: EventRepository
    let locationService: LocationService

    init() {
        FirebaseApp.configure()
        let auth = AuthService()
        let client = GraphQLClient(getToken: { try await auth.getToken() })
        authService = auth
        graphQLClient = client
        userRepository = UserRepository(client: client)
        eventRepository = EventRepository(client: client)
        locationService = LocationService()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(authService)
                .environment(userRepository)
                .environment(eventRepository)
                .environment(locationService)
        }
    }
}
