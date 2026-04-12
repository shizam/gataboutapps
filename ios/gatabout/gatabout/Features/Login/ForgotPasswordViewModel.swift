import Foundation

@Observable
final class ForgotPasswordViewModel {
    var email = ""
    var isLoading = false
    var errorMessage: String?
    var didSendReset = false

    private let authService: any AuthServiceProtocol

    var isValid: Bool { !email.trimmingCharacters(in: .whitespaces).isEmpty }

    init(authService: any AuthServiceProtocol) { self.authService = authService }

    func resetPassword() async {
        isLoading = true
        defer { isLoading = false }
        errorMessage = nil
        do {
            try await authService.resetPassword(email: email.trimmingCharacters(in: .whitespaces))
            didSendReset = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
