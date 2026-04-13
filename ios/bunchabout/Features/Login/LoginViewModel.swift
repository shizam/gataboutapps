import Foundation

@Observable
final class LoginViewModel {
    var email = ""
    var password = ""
    var isLoading = false
    var errorMessage: String?

    private let authService: any AuthServiceProtocol
    private let userRepository: UserRepository

    var isValid: Bool {
        !email.trimmingCharacters(in: .whitespaces).isEmpty && !password.isEmpty
    }

    init(authService: any AuthServiceProtocol, userRepository: UserRepository) {
        self.authService = authService
        self.userRepository = userRepository
    }

    func signIn() async {
        isLoading = true
        defer { isLoading = false }
        errorMessage = nil
        do {
            try await authService.signIn(email: email.trimmingCharacters(in: .whitespaces), password: password)
            try await userRepository.fetchCurrentUser()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
