struct EventParticipant: Codable, Identifiable, Hashable {
    let user: User
    let status: ParticipantStatus
    var slotType: SlotType?
    var joinedAt: String?
    var id: String { user.id }
}
