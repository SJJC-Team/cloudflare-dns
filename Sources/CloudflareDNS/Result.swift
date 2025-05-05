import Foundation

public struct Result<T>: Decodable where T: Decodable {
    let result: T!
    let success: Bool
    let errors: [ResultError]
    let messages: [String]
    let result_info: [String: Int]?
}

public struct ResultError: Decodable, Sendable, CustomStringConvertible {
    public let code: Int
    public let message: String
    public var description: String {
        "\(code): \(message)"
    }
}

public struct DeleteResult: Decodable {
    public let id: DNSRecord.ID
}
