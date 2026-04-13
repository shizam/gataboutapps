enum ActivityCategory: String, Codable, CaseIterable {
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
