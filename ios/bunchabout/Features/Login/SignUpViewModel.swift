import Foundation

@Observable
final class SignUpViewModel {
    var displayName = ""
    var email = ""
    var password = ""
    var isLoading = false
    var errorMessage: String?

    private let authService: any AuthServiceProtocol
    private let userRepository: UserRepository

    var isValid: Bool {
        !displayName.trimmingCharacters(in: .whitespaces).isEmpty
        && !email.trimmingCharacters(in: .whitespaces).isEmpty
        && password.count >= 6
    }

    init(authService: any AuthServiceProtocol, userRepository: UserRepository) {
        self.authService = authService
        self.userRepository = userRepository
    }

    func signUp() async {
        isLoading = true
        defer { isLoading = false }
        errorMessage = nil
        do {
            try await authService.signUp(email: email.trimmingCharacters(in: .whitespaces), password: password)
            try await userRepository.createProfile(displayName: displayName.trimmingCharacters(in: .whitespaces))
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
