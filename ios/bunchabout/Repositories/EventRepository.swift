import Foundation

@Observable
final class EventRepository {
    private(set) var events: [String: Event] = [:]
    private(set) var feedEventIds: [String] = []
    private(set) var feedPageInfo: PageInfo?
    private(set) var isLoadingFeed = false
    private let client: GraphQLClient

    init(client: GraphQLClient) { self.client = client }

    func fetchFeed(lat: Double, lng: Double, cursor: String? = nil) async throws {
        isLoadingFeed = true
        defer { isLoadingFeed = false }
        let variables = EventQueries.FeedVariables(
            location: EventQueries.LocationInput(lat: lat, lng: lng), cursor: cursor, limit: 20)
        let response: EventQueries.FeedResponse = try await client.execute(
            query: EventQueries.feed, variables: variables)
        for edge in response.feed.edges { events[edge.node.id] = edge.node }
        let newIds = response.feed.edges.map(\.node.id)
        if cursor == nil { feedEventIds = newIds } else { feedEventIds.append(contentsOf: newIds) }
        feedPageInfo = response.feed.pageInfo
    }

    func fetchEvent(id: String) async throws -> Event {
        if let cached = events[id] { return cached }
        let response: EventQueries.EventDetailResponse = try await client.execute(
            query: EventQueries.event, variables: EventQueries.EventVariables(id: id))
        guard let event = response.event else { throw AppError.graphQL(["Event not found"]) }
        events[id] = event
        return event
    }

    func event(for id: String) -> Event? { events[id] }
}
