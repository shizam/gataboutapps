import Testing
import Foundation
@testable import bunchabout

@Suite
struct ModelDecodingTests {
    @Test func decodesUserWithAllFields() throws {
        let json = """
        {
            "id": "u1",
            "displayName": "Sam",
            "photoURL": "https://example.com/photo.jpg",
            "bio": "Hello",
            "interests": ["DINNER", "BOARD_GAMES"],
            "traits": [{"name": "funny", "tier": "NORMAL"}],
            "badges": [{"id": "b1", "name": "First Steps", "description": "Welcome!"}],
            "eventsOrganized": 5,
            "eventsAttended": 10,
            "memberSince": "2026-01-01T00:00:00.000Z",
            "noShowCount": 0
        }
        """.data(using: .utf8)!
        let user = try JSONDecoder().decode(User.self, from: json)
        #expect(user.id == "u1")
        #expect(user.displayName == "Sam")
        #expect(user.interests == [.dinner, .boardGames])
        #expect(user.traits?.first?.name == "funny")
        #expect(user.badges?.count == 1)
    }

    @Test func decodesUserWithMinimalFields() throws {
        let json = """
        {"id": "u2", "displayName": "Alex"}
        """.data(using: .utf8)!
        let user = try JSONDecoder().decode(User.self, from: json)
        #expect(user.id == "u2")
        #expect(user.photoURL == nil)
        #expect(user.interests == nil)
    }

    @Test func decodesEvent() throws {
        let json = """
        {
            "id": "e1", "title": "Board Game Night", "category": "BOARD_GAMES",
            "date": "2026-04-15T19:00:00.000Z", "time": "7:00 PM",
            "totalSlots": 6, "slotsRemaining": 3,
            "fillMode": "FIRST_COME_FIRST_SERVED", "visibility": "PUBLIC", "status": "OPEN",
            "location": {"name": "The Game Parlour", "lat": 38.9072, "lng": -77.0369},
            "organizer": {"id": "u1", "displayName": "Sam"}
        }
        """.data(using: .utf8)!
        let event = try JSONDecoder().decode(Event.self, from: json)
        #expect(event.id == "e1")
        #expect(event.category == .boardGames)
        #expect(event.fillMode == .firstComeFirstServed)
        #expect(event.location?.name == "The Game Parlour")
        #expect(event.organizer?.displayName == "Sam")
    }

    @Test func decodesEventConnection() throws {
        let json = """
        {
            "edges": [{"node": {"id": "e1", "title": "Dinner", "category": "DINNER", "date": "2026-04-15T19:00:00.000Z"}, "cursor": "abc123"}],
            "pageInfo": {"hasNextPage": true, "endCursor": "abc123"}
        }
        """.data(using: .utf8)!
        let connection = try JSONDecoder().decode(EventConnection.self, from: json)
        #expect(connection.edges.count == 1)
        #expect(connection.pageInfo.hasNextPage == true)
    }

    @Test func parsesISO8601DateString() {
        let dateString = "2026-04-15T19:00:00.000Z"
        #expect(dateString.toDate != nil)
    }
}
