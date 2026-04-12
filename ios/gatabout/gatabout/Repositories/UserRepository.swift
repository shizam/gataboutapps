import Foundation

@Observable
final class UserRepository {
    private(set) var currentUser: User?
    private(set) var users: [String: User] = [:]
    private let client: GraphQLClient

    init(client: GraphQLClient) { self.client = client }

    func fetchCurrentUser() async throws {
        let response: UserQueries.MeResponse = try await client.execute(query: UserQueries.me)
        currentUser = response.me
        users[response.me.id] = response.me
    }

    func fetchUser(id: String) async throws -> User {
        if let cached = users[id] { return cached }
        let response: UserQueries.UserResponse = try await client.execute(
            query: UserQueries.user, variables: UserQueries.UserVariables(id: id))
        guard let user = response.user else { throw AppError.graphQL(["User not found"]) }
        users[id] = user
        return user
    }

    func createProfile(displayName: String) async throws {
        let variables = UserMutations.CreateProfileVariables(
            input: UserMutations.CreateProfileInput(displayName: displayName))
        let response: UserMutations.CreateProfileResponse = try await client.execute(
            query: UserMutations.createProfile, variables: variables)
        currentUser = response.createProfile
        users[response.createProfile.id] = response.createProfile
    }
}
