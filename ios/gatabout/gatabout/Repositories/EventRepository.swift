import Foundation

final class EventRepository {
    private let client: GraphQLClient

    init(client: GraphQLClient) {
        self.client = client
    }

    func feed(
        lat: Double,
        lng: Double,
        radius: Double = 10,
        cursor: String? = nil,
        limit: Int = 20
    ) async throws -> EventConnection {
        var variables: [String: Any] = [
            "location": ["lat": lat, "lng": lng],
            "radius": radius,
            "limit": limit
        ]
        if let cursor {
            variables["cursor"] = cursor
        }

        let response = try await client.execute(
            query: Self.feedQuery,
            variables: variables,
            as: FeedResponse.self
        )
        return response.feed
    }
}

// MARK: - Response wrappers

private extension EventRepository {
    struct FeedResponse: Decodable {
        let feed: EventConnection
    }
}

// MARK: - Queries

private extension EventRepository {
    static let feedQuery = """
        query Feed($location: LocationInput!, $radius: Float, $cursor: String, $limit: Int) {
          feed(location: $location, radius: $radius, cursor: $cursor, limit: $limit) {
            edges {
              node {
                id
                title
                description
                category
                date
                time
                duration
                status
                totalSlots
                slotsRemaining
                fillMode
                visibility
                location {
                  name
                  address
                  lat
                  lng
                  radius
                }
                organizer {
                  id
                  displayName
                  photoURL
                }
                myParticipantStatus
              }
              cursor
              distance
              score
            }
            pageInfo {
              hasNextPage
              endCursor
            }
            totalCount
          }
        }
        """
}
