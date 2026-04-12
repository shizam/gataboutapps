import Foundation

struct User: Decodable, Identifiable, Sendable {
    let id: String
    let displayName: String
    let photoURL: String?
}
