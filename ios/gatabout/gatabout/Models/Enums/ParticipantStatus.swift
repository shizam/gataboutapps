enum ParticipantStatus: String, Codable {
    case invited = "INVITED"
    case requested = "REQUESTED"
    case confirmed = "CONFIRMED"
    case declined = "DECLINED"
    case waitlisted = "WAITLISTED"
    case left = "LEFT"
    case removed = "REMOVED"
}
