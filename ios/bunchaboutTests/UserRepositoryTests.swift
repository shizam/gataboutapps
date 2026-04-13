import Testing
import Foundation
@testable import bunchabout

@Suite(.serialized)
@MainActor
struct UserRepositoryTests {
    @Test func fetchCurrentUserPopulatesCache() async throws {
        RepoMockURLProtocol.requestHandler = { _ in
            mockResponse(json: """
            {"data": {"me": {"id": "u1", "displayName": "Sam", "bio": "Hello"}}}
            """)
        }
        let repo = UserRepository(client: makeRepoTestClient())
        #expect(repo.currentUser == nil)
        try await repo.fetchCurrentUser()
        #expect(repo.currentUser?.id == "u1")
        #expect(repo.users["u1"]?.displayName == "Sam")
    }

    @Test func fetchUserReturnsCachedUser() async throws {
        var networkCallCount = 0
        RepoMockURLProtocol.requestHandler = { _ in
            networkCallCount += 1
            return mockResponse(json: """
            {"data": {"user": {"id": "u2", "displayName": "Alex"}}}
            """)
        }
        let repo = UserRepository(client: makeRepoTestClient())
        let user1 = try await repo.fetchUser(id: "u2")
        #expect(user1.displayName == "Alex")
        #expect(networkCallCount == 1)
        let user2 = try await repo.fetchUser(id: "u2")
        #expect(user2.displayName == "Alex")
        #expect(networkCallCount == 1)
    }

    @Test func createProfilePopulatesCurrentUser() async throws {
        RepoMockURLProtocol.requestHandler = { _ in
            mockResponse(json: """
            {"data": {"createProfile": {"id": "u3", "displayName": "New User"}}}
            """)
        }
        let repo = UserRepository(client: makeRepoTestClient())
        try await repo.createProfile(displayName: "New User")
        #expect(repo.currentUser?.id == "u3")
    }
}
