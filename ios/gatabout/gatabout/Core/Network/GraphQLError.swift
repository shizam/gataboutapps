import Foundation

struct GraphQLResponseError: Decodable, Sendable {
    let message: String
    let extensions: Extensions?

    struct Extensions: Decodable, Sendable {
        let code: String?
    }
}

enum GraphQLError: Error, LocalizedError {
    case networkError(Error)
    case httpError(statusCode: Int)
    case decodingError(Error)
    case graphQLErrors([GraphQLResponseError])
    case noData
    case unauthenticated

    var errorDescription: String? {
        switch self {
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .httpError(let code):
            return "Server error (HTTP \(code))"
        case .decodingError(let error):
            return "Data error: \(error.localizedDescription)"
        case .graphQLErrors(let errors):
            return errors.first?.message ?? "Unknown error"
        case .noData:
            return "No data returned"
        case .unauthenticated:
            return "Please sign in again"
        }
    }
}
