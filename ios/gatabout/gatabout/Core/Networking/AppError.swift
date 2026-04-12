import Foundation

enum AppError: Error, LocalizedError {
    case network(Error)
    case unauthorized
    case graphQL([String])
    case decoding(Error)

    var errorDescription: String? {
        switch self {
        case .network(let error):
            return error.localizedDescription
        case .unauthorized:
            return "Please sign in again."
        case .graphQL(let messages):
            return messages.first ?? "Something went wrong."
        case .decoding(let error):
            return "Failed to read server response: \(error.localizedDescription)"
        }
    }
}
