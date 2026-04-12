import Foundation

// MARK: - Enums

enum ActivityCategory: String, Codable, CaseIterable, Sendable {
    case dinner = "DINNER"
    case coffee = "COFFEE"
    case drinks = "DRINKS"
    case boardGames = "BOARD_GAMES"
    case videoGames = "VIDEO_GAMES"
    case outdoors = "OUTDOORS"
    case sports = "SPORTS"
    case fitness = "FITNESS"
    case music = "MUSIC"
    case arts = "ARTS"
    case movies = "MOVIES"
    case networking = "NETWORKING"
    case study = "STUDY"
    case other = "OTHER"

    var displayName: String {
        switch self {
        case .dinner: "Dinner"
        case .coffee: "Coffee"
        case .drinks: "Drinks"
        case .boardGames: "Board Games"
        case .videoGames: "Video Games"
        case .outdoors: "Outdoors"
        case .sports: "Sports"
        case .fitness: "Fitness"
        case .music: "Music"
        case .arts: "Arts"
        case .movies: "Movies"
        case .networking: "Networking"
        case .study: "Study"
        case .other: "Other"
        }
    }

    var systemImage: String {
        switch self {
        case .dinner: "fork.knife"
        case .coffee: "cup.and.saucer"
        case .drinks: "wineglass"
        case .boardGames: "dice"
        case .videoGames: "gamecontroller"
        case .outdoors: "leaf"
        case .sports: "sportscourt"
        case .fitness: "figure.run"
        case .music: "music.note"
        case .arts: "paintbrush"
        case .movies: "film"
        case .networking: "person.2"
        case .study: "book"
        case .other: "star"
        }
    }
}

enum EventStatus: String, Codable, Sendable {
    case open = "OPEN"
    case full = "FULL"
    case inProgress = "IN_PROGRESS"
    case completed = "COMPLETED"
    case cancelled = "CANCELLED"
}

enum FillMode: String, Codable, Sendable {
    case firstComeFirstServed = "FIRST_COME_FIRST_SERVED"
    case approvalRequired = "APPROVAL_REQUIRED"

    var displayName: String {
        switch self {
        case .firstComeFirstServed: "First Come First Served"
        case .approvalRequired: "Approval Required"
        }
    }

    var shortName: String {
        switch self {
        case .firstComeFirstServed: "Open"
        case .approvalRequired: "Approval"
        }
    }
}

enum Visibility: String, Codable, Sendable {
    case `public` = "PUBLIC"
    case friendsOnly = "FRIENDS_ONLY"
}

enum ParticipantStatus: String, Codable, Sendable {
    case invited = "INVITED"
    case requested = "REQUESTED"
    case confirmed = "CONFIRMED"
    case declined = "DECLINED"
    case waitlisted = "WAITLISTED"
    case left = "LEFT"
    case removed = "REMOVED"
}

// MARK: - Models

struct Event: Decodable, Identifiable, Sendable {
    let id: String
    let title: String
    let description: String?
    let category: ActivityCategory
    let date: String
    let time: String?
    let duration: Int?
    let status: EventStatus
    let totalSlots: Int
    let slotsRemaining: Int
    let fillMode: FillMode
    let visibility: Visibility
    let location: EventLocation?
    let organizer: User
    let myParticipantStatus: ParticipantStatus?
}

struct EventLocation: Decodable, Sendable {
    let name: String
    let address: String?
    let lat: Double
    let lng: Double
    let radius: Double
    let placeId: String?
}
