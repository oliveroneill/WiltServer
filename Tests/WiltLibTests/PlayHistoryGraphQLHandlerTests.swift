import XCTest
@testable import WiltLib

final class PlayHistoryGraphQLHandlerTests: XCTestCase {
    class FakeDatabase: DatabaseInterface {
        private let records: [PlayRecord]
        var calls: [(userId: String, start: Date?, end: Date?)] = []
        init(toReturn: [PlayRecord]) {
            self.records = toReturn
        }
        func getHistory(userId: String, start: Date?, end: Date?) throws -> [PlayRecord] {
            calls.append((userId: userId, start: start,  end: end))
            return records
        }
    }

    static let currentDate = Date()
    static let currentTimestamp = currentDate.timeIntervalSince1970
    static let userId = "xyz123"
    let query = "{ history(userId: \"\(userId)\") { userId date primaryArtist name artists trackId } }"
    let records = [
        PlayRecord(
            userId: userId,
            date: currentDate,
            primaryArtist: "Death Grips",
            name: "Turned Off",
            artists: ["Death Grips"],
            trackId: "track-id-123"
        ),
        PlayRecord(
            userId: userId,
            date: currentDate,
            primaryArtist: "Whitney",
            name: "No Woman",
            artists: ["Whitney"],
            trackId: "track-id-567"
        )
    ]
    let graphQLResult = "{\"data\":{\"history\":[{\"artists\":[\"Death Grips\"],\"date\":\(currentTimestamp),\"name\":\"Turned Off\",\"primaryArtist\":\"Death Grips\",\"trackId\":\"track-id-123\",\"userId\":\"xyz123\"},{\"artists\":[\"Whitney\"],\"date\":\(currentTimestamp),\"name\":\"No Woman\",\"primaryArtist\":\"Whitney\",\"trackId\":\"track-id-567\",\"userId\":\"xyz123\"}]}}"

    func testHandleRequest() {
        let handler = PlayHistoryGraphQLHandler(dao: FakeDatabase(toReturn: records))
        let items = [URLQueryItem(name: "query", value: query)]
        XCTAssertEqual(
            graphQLResult,
            try handler.handle(queryItems: items)
        )
    }

    func testHandleRequestCallsDatabase() {
        let db = FakeDatabase(toReturn: records)
        let handler = PlayHistoryGraphQLHandler(dao: db)
        let items = [URLQueryItem(name: "query", value: query)]
        XCTAssertNoThrow(
            try handler.handle(queryItems: items)
        )
        XCTAssertEqual(1, db.calls.count)
        XCTAssertEqual(PlayHistoryGraphQLHandlerTests.userId, db.calls.first?.userId)
        XCTAssertNil(db.calls.first?.start)
        XCTAssertNil(db.calls.first?.end)
    }

    func testHandleRequestCallsDatabaseWithDate() {
        let start = Date()
        let end = Date().addingTimeInterval(10000)
        let startTimestamp = start.timeIntervalSince1970
        let endTimestamp = end.timeIntervalSince1970
        let userId = PlayHistoryGraphQLHandlerTests.userId
        let query = "{ history(userId: \"\(userId)\", start: \(startTimestamp), end: \(endTimestamp)) { primaryArtist }}"
        let db = FakeDatabase(toReturn: records)
        let handler = PlayHistoryGraphQLHandler(dao: db)
        let items = [URLQueryItem(name: "query", value: query)]
        XCTAssertNoThrow(
            try handler.handle(queryItems: items)
        )
        XCTAssertEqual(1, db.calls.count)
        XCTAssertEqual(
            PlayHistoryGraphQLHandlerTests.userId,
            db.calls.first?.userId
        )
        // Timestamps are rounded since GraphQL loses some precisions from the
        // input dates
        XCTAssertEqual(
            startTimestamp.rounded(),
            db.calls.first?.start?.timeIntervalSince1970.rounded()
        )
        XCTAssertEqual(
            endTimestamp.rounded(),
            db.calls.first?.end?.timeIntervalSince1970.rounded()
        )
    }

    func testHandleRequestExcludingFields() {
        let userId = PlayHistoryGraphQLHandlerTests.userId
        let query = "{ history(userId: \"\(userId)\") {primaryArtist} }"
        let expected = "{\"data\":{\"history\":[{\"primaryArtist\":\"Death Grips\"},{\"primaryArtist\":\"Whitney\"}]}}"
        let handler = PlayHistoryGraphQLHandler(dao: FakeDatabase(toReturn: records))
        let items = [URLQueryItem(name: "query", value: query)]
        XCTAssertEqual(
            expected,
            try handler.handle(queryItems: items)
        )
    }

    func testHandleRequestIncorrectQuery() {
        let handler = PlayHistoryGraphQLHandler(dao: FakeDatabase(toReturn: []))
        let items = [URLQueryItem(name: "query", value: "{x")]
        XCTAssertThrowsError(try handler.handle(queryItems: items))
    }

    func testHandleRequestNoQuery() {
        let handler = PlayHistoryGraphQLHandler(dao: FakeDatabase(toReturn: []))
        let items = [URLQueryItem(name: "query", value: "")]
        XCTAssertThrowsError(try handler.handle(queryItems: items))
    }

    func testHandleQuery() {
        let handler = PlayHistoryGraphQLHandler(
            dao: FakeDatabase(toReturn: records)
        )
        let userId = PlayHistoryGraphQLHandlerTests.userId
        let query = "{ history(userId: \"\(userId)\") { userId date primaryArtist name artists trackId } }"
        XCTAssertEqual(graphQLResult, try handler.handle(query: query))
    }

    func testHandleQueryInvalidSchema() {
        let handler = PlayHistoryGraphQLHandler(dao: FakeDatabase(toReturn: []))
        XCTAssertThrowsError(try handler.handle(query: "}"))
    }

    func testHandleQueryUnexpectedQuery() {
        let handler = PlayHistoryGraphQLHandler(dao: FakeDatabase(toReturn: []))
        let expected = "{\"errors\":[{\"locations\":[{\"column\":3,\"line\":1}],\"message\":\"Cannot query field \\\"hello\\\" on type \\\"Query\\\".\"}]}"
        let items = [URLQueryItem(name: "query", value: "{ hello }")]
        XCTAssertEqual(
            expected,
            try handler.handle(queryItems: items)
        )
    }
}
