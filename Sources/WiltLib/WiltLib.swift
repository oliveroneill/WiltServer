import Foundation
import Graphiti
import GraphQL
import BigQuerySwift
import NIO

/// GraphQL Date specification
/// Date should be a unix timestamp in milliseconds
extension Date: InputType, OutputType {
    public init(map: Map) throws {
        self.init(timeIntervalSince1970: try map.asDouble())
    }

    public func asMap() throws -> Map {
        return .double(self.timeIntervalSince1970)
    }
}

/// The play record information returned from GraphQL
public struct PlayRecord: MapFallibleRepresentable {
    let userId: String
    let date: Date
    let primaryArtist: String
    let name: String
    let artists: [String]
    let trackId: String
}

public struct BigQueryPlayRecord: Codable, Equatable {
    let user_id: String
    let date: String
    let primary_artist: String
    let name: String
    let artists: [String]
    let track_id: String
}

/// Search query for history
struct SearchArguments: Arguments {
    let userId: String
    let start: Date?
    let end: Date?

    static let descriptions = [
        "user_id": "The ID of the user to search for.",
        "start": "If omitted, history will start from the first play.",
        "end": "If omitted, will end at the last play."
    ]
}

/// Errors that occur during query response
///
/// - unexpectedFailure: Something went wrong with query
public enum PlayHistoryQueryError: Error {
    case unexpectedFailure
    case bigQueryError([BigQueryError])
    case unexpectedTimestamp(String)
}

/// Errors that occur when validating HTTP request
///
/// - invalidRequest: The request was invalid
public enum GraphQLRequestError: Error {
    case invalidRequest
}


/// Protocol for database interaction
public protocol DatabaseInterface {
    func getHistory(userId: String, start: Date?, end: Date?) throws -> [PlayRecord]
}

/// DynamoDB implementation for making database queries
public class BigQueryAccess: DatabaseInterface {
    private let db: BigQueryClient<BigQueryPlayRecord>
    public init(projectId: String) throws {
        let s = DispatchSemaphore(value: 0)
        var response: AuthResponse?
        let provider = BigQueryAuthProvider()
        try provider.getAuthenticationToken { r in
            response = r
            s.signal()
        }
        s.wait()
        guard let r = response else {
            fatalError("Unexpected empty response")
        }
        switch r {
        case .token(let token):
            self.db = BigQueryClient(
                authenticationToken: token,
                projectID: projectId,
                datasetID: "wilt_play_history",
                tableName: "play_history"
            )
        case .error(let e):
            throw e
        }
    }

    public func getHistory(userId: String, start: Date?, end: Date?) throws -> [PlayRecord] {
        let s = DispatchSemaphore(value: 0)
        // Create query
        let query = "SELECT * FROM wilt_play_history.play_history WHERE user_id = '\(userId)' ORDER BY date ASC"
        var response: QueryCallResponse<BigQueryPlayRecord>?
        try db.query(query) { (r: QueryCallResponse<BigQueryPlayRecord>) in
            response = r
            s.signal()
        }
        s.wait()
        guard let r = response else {
            fatalError("Unexpected empty query response")
        }
        switch r {
        case .error(let e):
            throw e
        case .queryResponse(let result):
            guard let rtn = result.rows else {
                guard let errors = result.errors else {
                    throw PlayHistoryQueryError.unexpectedFailure
                }
                throw PlayHistoryQueryError.bigQueryError(errors)
            }
            // Map items to PlayRecord
            return try rtn.map {
                guard let interval = TimeInterval($0.date) else {
                    throw PlayHistoryQueryError.unexpectedTimestamp($0.date)
                }
                return PlayRecord(
                    userId: $0.user_id,
                    date: Date(timeIntervalSince1970: interval),
                    primaryArtist: $0.primary_artist,
                    name: $0.name,
                    artists: $0.artists,
                    trackId: $0.track_id
                )
            }
        }
    }
}

/// Handler that receives GraphQL queries and makes database queries based on
/// them
public class PlayHistoryGraphQLHandler {
    private let schema: Schema<NoRoot, NoContext, BasicEventLoop>

    /// Create handler for responding to GraphQL queries
    ///
    /// - Parameter dao: Optionally specify the datbase access object
    public init(dao: DatabaseInterface) {
        // Define GraphQL schema
        self.schema = try! Schema<NoRoot, NoContext, BasicEventLoop> { schema in
            // Date specification
            try schema.scalar(type: Date.self) { scalar in
                scalar.description = "A date represented as a unix timestamp in milliseconds"
                scalar.parseValue { value in
                    if case .double = value {
                        return value
                    }
                    if case .int(let int) = value {
                        return .double(Double(int))
                    }
                    return .null
                }
                scalar.parseLiteral { ast in
                    if let ast = ast as? FloatValue, let double = Double(ast.value) {
                        return .double(double)
                    }
                    if let ast = ast as? IntValue, let double = Double(ast.value) {
                        return .double(double)
                    }
                    return .null
                }
            }
            // Specify PlayRecord response object
            try schema.object(type: PlayRecord.self) { record in
                record.description = "A record of a track playing for a specific user"
                try record.exportFields()
            }
            // Specify query
            try schema.query { query in
                try query.field(name: "history") { (_, arguments: SearchArguments, _, eventLoop, _) -> EventLoopFuture<[PlayRecord]> in
                    do {
                        let result = try PlayHistoryGraphQLHandler.getHistory(
                            userId: arguments.userId,
                            dao: dao,
                            start: arguments.start,
                            end: arguments.end
                        )
                        return eventLoop.next().newSucceededFuture(result: result)
                    } catch {
                        return eventLoop.next().newFailedFuture(error: error)
                    }
                }
            }
        }
    }

    /// Get play history for user
    private static func getHistory(userId: String,
                                   dao: DatabaseInterface,
                                   start: Date? = nil,
                                   end: Date? = nil) throws -> [PlayRecord] {
        return try dao.getHistory(userId: userId, start: start, end: end)
    }

    /// Handle GraphQL query
    ///
    /// - Parameter query: GraphQL query
    /// - Returns: A string of the GraphQL response
    /// - Throws: If the query fails
    func handle(query: String) throws -> String {
        // Use BasicEventLoop for Lamba support
        let eventLoopGroup = BasicEventLoop()
        let result = try schema.execute(
            request: query,
            eventLoopGroup: eventLoopGroup
        ).wait()
        try eventLoopGroup.syncShutdownGracefully()
        return "\(result)"
    }

    /// Handle query
    ///
    /// - Parameter queryItems: The query items of the URL
    /// - Returns: A GraphQL response
    /// - Throws: If the query fails or the request is invalid
    public func handle(queryItems: [URLQueryItem]) throws -> String {
        guard let query = queryItems.first, query.name == "query",
            let q = query.value else {
            throw GraphQLRequestError.invalidRequest
        }
        return try handle(query: q)
    }
}
