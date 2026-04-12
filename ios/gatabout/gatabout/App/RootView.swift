import SwiftUI

struct RootView: View {
    @Environment(AuthService.self) private var authService
    @Environment(UserRepository.self) private var userRepository

    var body: some View {
        switch authService.authState {
        case .unknown:
            ProgressView("Loading...")
        case .signedOut:
            NavigationStack {
                LoginView(authService: authService, userRepository: userRepository)
            }
        case .signedIn:
            MainTabView()
                .task {
                    if userRepository.currentUser == nil {
                        try? await userRepository.fetchCurrentUser()
                    }
                }
        }
    }
}
