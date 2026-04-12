import Testing
import Foundation
@testable import gatabout

private let feedJSON = """
{"data":{"feed":{"edges":[{"node":{"id":"e1","title":"Dinner Club","category":"DINNER","date":"2026-04-15T19:00:00.000Z","totalSlots":6,"slotsRemaining":3,"status":"OPEN","location":{"name":"Bistro","lat":37.77,"lng":-122.42},"organizer":{"id":"u1","displayName":"Sam"}},"cursor":"c1"}],"pageInfo":{"hasNextPage":false,"endCursor":"c1"}}}}
"""

@Suite(.serialized)
@MainActor
struct FeedViewModelTests {
    @Test func loadFeedPopulatesEvents() async {
        FeedMockURLProtocol.requestHandler = { _ in mockResponse(json: feedJSON) }
        let repo = EventRepository(client: makeFeedTestClient())
        let vm = FeedViewModel(eventRepository: repo, locationService: LocationService())
        vm.testLocation = (lat: 37.77, lng: -122.42)
        await vm.loadFeed()
        #expect(vm.feedEvents.count == 1)
        #expect(vm.feedEvents.first?.title == "Dinner Club")
        #expect(vm.errorMessage == nil)
    }

    @Test func loadFeedSetsErrorOnFailure() async {
        FeedMockURLProtocol.requestHandler = { _ in
            mockResponse(json: """
            {"data": null, "errors": [{"message": "Server error"}]}
            """)
        }
        let repo = EventRepository(client: makeFeedTestClient())
        let vm = FeedViewModel(eventRepository: repo, locationService: LocationService())
        vm.testLocation = (lat: 37.77, lng: -122.42)
        await vm.loadFeed()
        #expect(vm.errorMessage != nil)
        #expect(vm.feedEvents.isEmpty)
    }
}
