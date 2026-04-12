import Foundation

struct User: Codable, Identifiable, Hashable {
    let id: String
    let displayName: String
    var photoURL: String?
    var bio: String?
    var interests: [ActivityCategory]?
    var traits: [Trait]?
    var badges: [Badge]?
    var eventsOrganized: Int?
    var eventsAttended: Int?
    var memberSince: String?
    var gender: Gender?
    var dateOfBirth: String?
    var noShowCount: Int?
}
