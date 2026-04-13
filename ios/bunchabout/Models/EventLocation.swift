struct EventLocation: Codable, Hashable {
    let name: String
    var address: String?
    let lat: Double
    let lng: Double
    var radius: Double?
    var placeId: String?
}
