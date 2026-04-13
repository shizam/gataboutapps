import Testing
import Foundation
@testable import bunchabout

@Suite(.serialized)
@MainActor
struct LoginViewModelTests {
    @Test func signInSuccessPopulatesUser() async {
        LoginMockURLProtocol.requestHandler = { _ in
            mockResponse(json: """
            {"data": {"me": {"id": "u1", "displayName": "Sam"}}}
            """)
        }
        let mockAuth = MockAuthService()
        let userRepo = UserRepository(client: makeLoginTestClient())
        let vm = LoginViewModel(authService: mockAuth, userRepository: userRepo)
        vm.email = "test@example.com"
        vm.password = "password123"
        await vm.signIn()
        #expect(mockAuth.signInCallCount == 1)
        #expect(mockAuth.lastEmail == "test@example.com")
        #expect(vm.errorMessage == nil)
        #expect(vm.isLoading == false)
        #expect(userRepo.currentUser?.id == "u1")
    }

    @Test func signInFailureSetsErrorMessage() async {
        let mockAuth = MockAuthService()
        mockAuth.shouldFail = true
        mockAuth.failureError = AppError.graphQL(["Invalid credentials"])
        let userRepo = UserRepository(client: makeLoginTestClient())
        let vm = LoginViewModel(authService: mockAuth, userRepository: userRepo)
        vm.email = "test@example.com"
        vm.password = "wrong"
        await vm.signIn()
        #expect(vm.errorMessage != nil)
        #expect(vm.isLoading == false)
        #expect(userRepo.currentUser == nil)
    }

    @Test func isValidRequiresEmailAndPassword() {
        let vm = LoginViewModel(authService: MockAuthService(), userRepository: UserRepository(client: makeLoginTestClient()))
        #expect(!vm.isValid)
        vm.email = "test@example.com"
        #expect(!vm.isValid)
        vm.password = "password"
        #expect(vm.isValid)
    }
}
