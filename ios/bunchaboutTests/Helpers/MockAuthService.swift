import Foundation
@testable import bunchabout

final class MockAuthService: AuthServiceProtocol {
    var shouldFail = false
    var failureError: Error = AppError.unauthorized
    var signInCallCount = 0
    var signUpCallCount = 0
    var resetPasswordCallCount = 0
    var lastEmail: String?
    var lastPassword: String?

    func signIn(email: String, password: String) async throws {
        signInCallCount += 1
        lastEmail = email
        lastPassword = password
        if shouldFail { throw failureError }
    }

    func signUp(email: String, password: String) async throws {
        signUpCallCount += 1
        lastEmail = email
        lastPassword = password
        if shouldFail { throw failureError }
    }

    func signOut() throws {}

    func resetPassword(email: String) async throws {
        resetPasswordCallCount += 1
        lastEmail = email
        if shouldFail { throw failureError }
    }
}
