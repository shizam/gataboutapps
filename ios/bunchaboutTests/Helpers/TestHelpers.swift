import Foundation
@testable import bunchabout

func makeMockSession() -> URLSession {
    let config = URLSessionConfiguration.ephemeral
    config.protocolClasses = [MockURLProtocol.self]
    return URLSession(configuration: config)
}

func makeTestClient() -> GraphQLClient {
    GraphQLClient(
        url: URL(string: "https://test.example.com/graphql")!,
        session: makeMockSession(),
        getToken: { "mock-token" }
    )
}

func makeRepoTestClient() -> GraphQLClient {
    let config = URLSessionConfiguration.ephemeral
    config.protocolClasses = [RepoMockURLProtocol.self]
    return GraphQLClient(
        url: URL(string: "https://test.example.com/graphql")!,
        session: URLSession(configuration: config),
        getToken: { "mock-token" }
    )
}

func makeEventTestClient() -> GraphQLClient {
    let config = URLSessionConfiguration.ephemeral
    config.protocolClasses = [EventMockURLProtocol.self]
    return GraphQLClient(
        url: URL(string: "https://test.example.com/graphql")!,
        session: URLSession(configuration: config),
        getToken: { "mock-token" }
    )
}

func makeLoginTestClient() -> GraphQLClient {
    let config = URLSessionConfiguration.ephemeral
    config.protocolClasses = [LoginMockURLProtocol.self]
    return GraphQLClient(
        url: URL(string: "https://test.example.com/graphql")!,
        session: URLSession(configuration: config),
        getToken: { "mock-token" }
    )
}

func makeFeedTestClient() -> GraphQLClient {
    let config = URLSessionConfiguration.ephemeral
    config.protocolClasses = [FeedMockURLProtocol.self]
    return GraphQLClient(
        url: URL(string: "https://test.example.com/graphql")!,
        session: URLSession(configuration: config),
        getToken: { "mock-token" }
    )
}

func mockResponse(json: String, statusCode: Int = 200) -> (HTTPURLResponse, Data) {
    let response = HTTPURLResponse(
        url: URL(string: "https://test.example.com/graphql")!,
        statusCode: statusCode,
        httpVersion: nil,
        headerFields: ["Content-Type": "application/json"]
    )!
    return (response, json.data(using: .utf8)!)
}
