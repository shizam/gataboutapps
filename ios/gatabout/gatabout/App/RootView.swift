import SwiftUI

struct RootView: View {
    let authService: AuthService
    let eventRepository: EventRepository
    let locationManager: LocationManager

    var body: some View {
        Group {
            switch authService.state {
            case .unknown:
                ProgressView()
            case .loggedOut:
                LoginView(authService: authService)
            case .loggedIn:
                FeedView(
                    eventRepository: eventRepository,
                    locationManager: locationManager
                )
            }
        }
        .animation(.default, value: authService.state)
    }
}
