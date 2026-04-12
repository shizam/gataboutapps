import Foundation

struct Event: Codable, Identifiable, Hashable {
    let id: String
    var organizer: User?
    let title: String
    var description: String?
    let category: ActivityCategory
    let date: String
    var time: String?
    var duration: Int?
    var totalSlots: Int?
    var friendReservedSlots: Int?
    var openSlots: Int?
    var slotsRemaining: Int?
    var fillMode: FillMode?
    var visibility: Visibility?
    var status: EventStatus?
    var location: EventLocation?
    var venue: Venue?
    var participants: [EventParticipant]?
    var myParticipantStatus: ParticipantStatus?
    var chatRoomId: String?
    var createdAt: String?
}
