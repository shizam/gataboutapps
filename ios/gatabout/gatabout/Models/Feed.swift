import Foundation

struct EventConnection: Decodable, Sendable {
    let edges: [EventEdge]
    let pageInfo: PageInfo
    let totalCount: Int
}

struct EventEdge: Decodable, Identifiable, Sendable {
    let node: Event
    let cursor: String
    let distance: Double?
    let score: Double?

    var id: String { node.id }
}

struct PageInfo: Decodable, Sendable {
    let hasNextPage: Bool
    let endCursor: String?
}

enum FeedSort: String, Codable, Sendable {
    case score = "SCORE"
    case date = "DATE"
    case distance = "DISTANCE"
}
