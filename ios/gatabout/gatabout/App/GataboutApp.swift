import SwiftUI

@main
struct GataboutApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @State private var services = AppServices()

    var body: some Scene {
        WindowGroup {
            RootView(
                authService: services.authService,
                eventRepository: services.eventRepository,
                locationManager: services.locationManager
            )
        }
    }
}

@MainActor
final class AppServices {
    let authService: AuthService
    let graphQLClient: GraphQLClient
    let eventRepository: EventRepository
    let locationManager: LocationManager

    init() {
        let auth = AuthService()
        let client = GraphQLClient(authService: auth)

        self.authService = auth
        self.graphQLClient = client
        self.eventRepository = EventRepository(client: client)
        self.locationManager = LocationManager()
    }
}
