import Testing
import Foundation
@testable import gatabout

@Suite(.serialized)
@MainActor
struct GraphQLClientTests {
    let client = makeTestClient()

    @Test func decodesSuccessResponse() async throws {
        MockURLProtocol.requestHandler = { _ in
            mockResponse(json: """
            {"data": {"me": {"id": "u1", "displayName": "Sam"}}}
            """)
        }

        struct MeResponse: Decodable {
            let me: User
        }

        let response: MeResponse = try await client.execute(query: "query { me { id displayName } }")
        #expect(response.me.id == "u1")
        #expect(response.me.displayName == "Sam")
    }

    @Test func throwsOnGraphQLErrors() async {
        MockURLProtocol.requestHandler = { _ in
            mockResponse(json: """
            {"data": null, "errors": [{"message": "Not found"}]}
            """)
        }

        struct DummyResponse: Decodable { let me: User? }

        await #expect(throws: AppError.self) {
            let _: DummyResponse = try await client.execute(query: "query { me { id } }")
        }
    }

    @Test func throwsUnauthorizedOn401() async {
        MockURLProtocol.requestHandler = { _ in
            mockResponse(json: "{}", statusCode: 401)
        }

        struct DummyResponse: Decodable { let me: User? }

        await #expect(throws: AppError.self) {
            let _: DummyResponse = try await client.execute(query: "query { me { id } }")
        }
    }

    @Test func sendsAuthorizationHeader() async throws {
        var capturedRequest: URLRequest?
        MockURLProtocol.requestHandler = { request in
            capturedRequest = request
            return mockResponse(json: """
            {"data": {"me": {"id": "u1", "displayName": "Sam"}}}
            """)
        }

        struct MeResponse: Decodable { let me: User }
        let _: MeResponse = try await client.execute(query: "query { me { id displayName } }")

        #expect(capturedRequest?.value(forHTTPHeaderField: "Authorization") == "Bearer mock-token")
        #expect(capturedRequest?.value(forHTTPHeaderField: "Content-Type") == "application/json")
    }
}
