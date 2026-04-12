import FirebaseAuth
import Observation

enum AuthState: Equatable {
    case unknown
    case loggedOut
    case loggedIn
}

@Observable
@MainActor
final class AuthService {
    private(set) var state: AuthState = .unknown

    private var handle: AuthStateDidChangeListenerHandle?
    private var currentUser: FirebaseAuth.User?

    init() {
        handle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                self?.currentUser = user
                self?.state = user != nil ? .loggedIn : .loggedOut
            }
        }
    }

    isolated deinit {
        if let handle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }

    func signIn(email: String, password: String) async throws {
        try await Auth.auth().signIn(withEmail: email, password: password)
    }

    func signOut() throws {
        try Auth.auth().signOut()
    }

    func getIDToken() async throws -> String {
        guard let user = currentUser else {
            throw AuthServiceError.notAuthenticated
        }
        return try await user.getIDToken()
    }
}

enum AuthServiceError: Error, LocalizedError {
    case notAuthenticated

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Not signed in"
        }
    }
}
