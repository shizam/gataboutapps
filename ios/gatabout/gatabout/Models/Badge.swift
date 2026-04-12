struct Badge: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let description: String
    var awardedAt: String?
}
