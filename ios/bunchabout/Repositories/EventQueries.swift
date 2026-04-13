enum EventQueries {
    static let feed = """
    query Feed($location: LocationInput!, $cursor: String, $limit: Int) {
        feed(location: $location, cursor: $cursor, limit: $limit) {
            edges {
                node {
                    id title category date time totalSlots slotsRemaining status fillMode visibility
                    location { name lat lng }
                    organizer { id displayName photoURL }
                }
                cursor
            }
            pageInfo { hasNextPage endCursor }
        }
    }
    """

    static let event = """
    query Event($id: ID!) {
        event(id: $id) {
            id title description category date time duration
            totalSlots friendReservedSlots openSlots slotsRemaining fillMode visibility status
            location { name address lat lng radius placeId }
            venue { placeId displayName formattedAddress rating photos { url } }
            organizer { id displayName photoURL }
            participants { user { id displayName photoURL } status slotType joinedAt }
            myParticipantStatus createdAt
        }
    }
    """

    struct FeedResponse: Decodable { let feed: EventConnection }
    struct FeedVariables: Encodable {
        let location: LocationInput
        var cursor: String?
        var limit: Int?
    }
    struct LocationInput: Encodable { let lat: Double; let lng: Double }
    struct EventDetailResponse: Decodable { let event: Event? }
    struct EventVariables: Encodable { let id: String }
}
