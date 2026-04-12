import Foundation

final class GraphQLClient {
    private let url: URL
    private let session: URLSession
    private let getToken: () async throws -> String

    init(
        url: URL = URL(string: "https://lfourg-a6fe3.web.app/graphql")!,
        session: URLSession = .shared,
        getToken: @escaping () async throws -> String
    ) {
        self.url = url
        self.session = session
        self.getToken = getToken
    }

    func execute<T: Decodable>(query: String) async throws -> T {
        try await execute(query: query, variables: nil as EmptyVariables?)
    }

    func execute<T: Decodable, V: Encodable>(query: String, variables: V) async throws -> T {
        try await execute(query: query, variables: Optional.some(variables))
    }

    private func execute<T: Decodable, V: Encodable>(query: String, variables: V?) async throws -> T {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let token = try await getToken()
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let body = RequestBody(query: query, variables: variables)
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AppError.network(URLError(.badServerResponse))
        }

        if httpResponse.statusCode == 401 {
            throw AppError.unauthorized
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw AppError.network(URLError(.badServerResponse))
        }

        let graphQLResponse: GraphQLResponse<T>
        do {
            graphQLResponse = try JSONDecoder().decode(GraphQLResponse<T>.self, from: data)
        } catch {
            throw AppError.decoding(error)
        }

        if let errors = graphQLResponse.errors, !errors.isEmpty {
            throw AppError.graphQL(errors.map(\.message))
        }

        guard let responseData = graphQLResponse.data else {
            throw AppError.graphQL(["No data returned"])
        }

        return responseData
    }
}

private struct EmptyVariables: Encodable {}

private struct RequestBody<V: Encodable>: Encodable {
    let query: String
    let variables: V?
}

struct GraphQLResponse<T: Decodable>: Decodable {
    let data: T?
    let errors: [GraphQLError]?
}

struct GraphQLError: Decodable {
    let message: String
}
