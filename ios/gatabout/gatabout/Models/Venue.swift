struct Venue: Codable, Identifiable, Hashable {
    let placeId: String
    let displayName: String
    let formattedAddress: String
    var rating: Double?
    var photos: [VenuePhoto]?
    var id: String { placeId }
}

struct VenuePhoto: Codable, Hashable {
    let url: String
}
