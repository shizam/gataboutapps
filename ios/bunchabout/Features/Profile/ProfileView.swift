import SwiftUI

struct ProfileView: View {
    @Environment(AuthService.self) private var authService
    @Environment(UserRepository.self) private var userRepository

    var body: some View {
        VStack(spacing: Sizes.spacing24) {
            if let user = userRepository.currentUser {
                Text(user.displayName)
                    .font(.title)
                if let bio = user.bio {
                    Text(bio)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Button("Sign Out", role: .destructive) {
                try? authService.signOut()
            }
            .buttonStyle(.bordered)
        }
        .padding(Sizes.spacing24)
        .navigationTitle("Profile")
    }
}
