import FirebaseAuth

@Observable
final class AuthService: AuthServiceProtocol {
    private(set) var authState: AuthState = .unknown
    private var handle: AuthStateDidChangeListenerHandle?

    init() {
        handle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.authState = user != nil ? .signedIn : .signedOut
        }
    }

    deinit {
        if let handle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }

    func signIn(email: String, password: String) async throws {
        try await Auth.auth().signIn(withEmail: email, password: password)
    }

    func signUp(email: String, password: String) async throws {
        try await Auth.auth().createUser(withEmail: email, password: password)
    }

    func signOut() throws {
        try Auth.auth().signOut()
    }

    func resetPassword(email: String) async throws {
        try await Auth.auth().sendPasswordReset(withEmail: email)
    }

    func getToken() async throws -> String {
        guard let user = Auth.auth().currentUser else {
            throw AppError.unauthorized
        }
        return try await user.getIDToken()
    }
}
