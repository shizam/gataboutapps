struct EventConnection: Codable {
    let edges: [EventEdge]
    let pageInfo: PageInfo
}
struct EventEdge: Codable {
    let node: Event
    let cursor: String
}
struct PageInfo: Codable {
    let hasNextPage: Bool
    var endCursor: String?
}
