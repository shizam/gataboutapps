enum EventStatus: String, Codable {
    case open = "OPEN"
    case full = "FULL"
    case inProgress = "IN_PROGRESS"
    case completed = "COMPLETED"
    case cancelled = "CANCELLED"
}
