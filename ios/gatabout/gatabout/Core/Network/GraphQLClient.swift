import Foundation

final class GraphQLClient {
    private let url: URL
    private let authService: AuthService
    private let session: URLSession

    init(authService: AuthService, url: URL = AppConfig.graphQLURL) {
        self.authService = authService
        self.url = url
        self.session = .shared
    }

    /// Execute a GraphQL query or mutation.
    /// `T` is the shape of the `data` field in the response —
    /// e.g. `struct FeedResponse: Decodable { let feed: EventConnection }`.
    func execute<T: Decodable>(
        query: String,
        variables: [String: Any]? = nil,
        as type: T.Type
    ) async throws -> T {
        let token: String
        do {
            token = try await authService.getIDToken()
        } catch {
            throw GraphQLError.unauthenticated
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let body: [String: Any] = [
            "query": query,
            "variables": variables ?? [:]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let responseData: Data
        let response: URLResponse
        do {
            (responseData, response) = try await session.data(for: request)
        } catch {
            throw GraphQLError.networkError(error)
        }

        if let httpResponse = response as? HTTPURLResponse,
           !(200...299).contains(httpResponse.statusCode) {
            if httpResponse.statusCode == 401 {
                throw GraphQLError.unauthenticated
            }
            throw GraphQLError.httpError(statusCode: httpResponse.statusCode)
        }

        let graphQLResponse: GraphQLResponse<T>
        do {
            graphQLResponse = try JSONDecoder().decode(GraphQLResponse<T>.self, from: responseData)
        } catch {
            throw GraphQLError.decodingError(error)
        }

        if let errors = graphQLResponse.errors, !errors.isEmpty {
            if errors.contains(where: { $0.extensions?.code == "UNAUTHENTICATED" }) {
                throw GraphQLError.unauthenticated
            }
            throw GraphQLError.graphQLErrors(errors)
        }

        guard let data = graphQLResponse.data else {
            throw GraphQLError.noData
        }

        return data
    }
}

// MARK: - Response wrapper

private struct GraphQLResponse<T: Decodable>: Decodable {
    let data: T?
    let errors: [GraphQLResponseError]?
}
