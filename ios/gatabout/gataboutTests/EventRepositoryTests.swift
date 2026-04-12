import Testing
import Foundation
@testable import gatabout

@Suite(.serialized)
@MainActor
struct EventRepositoryTests {
    @Test func fetchFeedPopulatesCacheAndIds() async throws {
        EventMockURLProtocol.requestHandler = { _ in
            mockResponse(json: """
            {"data":{"feed":{"edges":[
                {"node":{"id":"e1","title":"Dinner","category":"DINNER","date":"2026-04-15T19:00:00.000Z"},"cursor":"c1"},
                {"node":{"id":"e2","title":"Games","category":"BOARD_GAMES","date":"2026-04-16T19:00:00.000Z"},"cursor":"c2"}
            ],"pageInfo":{"hasNextPage":true,"endCursor":"c2"}}}}
            """)
        }
        let repo = EventRepository(client: makeEventTestClient())
        try await repo.fetchFeed(lat: 37.77, lng: -122.42)
        #expect(repo.feedEventIds == ["e1", "e2"])
        #expect(repo.events["e1"]?.title == "Dinner")
        #expect(repo.feedPageInfo?.hasNextPage == true)
    }

    @Test func fetchFeedNextPageAppendsResults() async throws {
        let repo = EventRepository(client: makeEventTestClient())
        EventMockURLProtocol.requestHandler = { _ in
            mockResponse(json: """
            {"data":{"feed":{"edges":[{"node":{"id":"e1","title":"A","category":"DINNER","date":"2026-04-15T00:00:00.000Z"},"cursor":"c1"}],"pageInfo":{"hasNextPage":true,"endCursor":"c1"}}}}
            """)
        }
        try await repo.fetchFeed(lat: 37.77, lng: -122.42)
        #expect(repo.feedEventIds == ["e1"])
        EventMockURLProtocol.requestHandler = { _ in
            mockResponse(json: """
            {"data":{"feed":{"edges":[{"node":{"id":"e2","title":"B","category":"COFFEE","date":"2026-04-16T00:00:00.000Z"},"cursor":"c2"}],"pageInfo":{"hasNextPage":false,"endCursor":"c2"}}}}
            """)
        }
        try await repo.fetchFeed(lat: 37.77, lng: -122.42, cursor: "c1")
        #expect(repo.feedEventIds == ["e1", "e2"])
    }

    @Test func fetchEventCachesResult() async throws {
        var callCount = 0
        EventMockURLProtocol.requestHandler = { _ in
            callCount += 1
            return mockResponse(json: """
            {"data":{"event":{"id":"e1","title":"Dinner","category":"DINNER","date":"2026-04-15T00:00:00.000Z","totalSlots":6,"slotsRemaining":3}}}
            """)
        }
        let repo = EventRepository(client: makeEventTestClient())
        let event1 = try await repo.fetchEvent(id: "e1")
        #expect(event1.title == "Dinner")
        #expect(callCount == 1)
        let event2 = try await repo.fetchEvent(id: "e1")
        #expect(event2.title == "Dinner")
        #expect(callCount == 1)
    }
}
