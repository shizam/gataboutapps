import FirebaseCore
import SwiftUI

@main
struct GataboutApp: App {
    private let authService: AuthService
    private let graphQLClient: GraphQLClient
    private let eventRepository: EventRepository
    private let locationManager: LocationManager

    init() {
        FirebaseApp.configure()

        let auth = AuthService()
        let client = GraphQLClient(authService: auth)

        self.authService = auth
        self.graphQLClient = client
        self.eventRepository = EventRepository(client: client)
        self.locationManager = LocationManager()
    }

    var body: some Scene {
        WindowGroup {
            RootView(
                authService: authService,
                eventRepository: eventRepository,
                locationManager: locationManager
            )
        }
    }
}
