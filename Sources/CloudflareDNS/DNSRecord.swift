import Foundation

public struct DNSRecord: Decodable, CustomStringConvertible {
    
    public typealias ID = String
    
    public let id: ID
    public let name: String
    public let type: DNSType
    public let content: String
    public let proxiable: Bool
    public let proxied: Bool
    public let ttl: Int
    public let settings: Settings
    public let comment: String?
    public let tags: [String]
    public let created_on: DNSDate
    public let modified_on: DNSDate
    
    public struct Settings: Codable {
        let ipv4Only: Bool?
        let ipv6Only: Bool?

        enum CodingKeys: String, CodingKey {
            case ipv4Only = "ipv4_only"
            case ipv6Only = "ipv6_only"
        }
    }
    
    public enum DNSType: String, Codable {
        case A = "A"
        case AAAA = "AAAA"
        case CAA = "CAA"
        case CERT = "CERT"
        case CNAME = "CNAME"
        case DNSKEY = "DNSKEY"
        case DS = "DS"
        case HTTPS = "HTTPS"
        case LOC = "LOC"
        case MX = "MX"
        case NAPTR = "NAPTR"
        case NS = "NS"
        case OPENPGPKEY = "OPENPGPKEY"
        case PTR = "PTR"
        case SMIMEA = "SMIMEA"
        case SRV = "SRV"
        case SSHFP = "SSHFP"
        case SVCB = "SVCB"
        case TLSA = "TLSA"
        case TXT = "TXT"
        case URI = "URI"
    }
    
    public var description: String {
        "\(type.rawValue) | \(name) -> \(content) \(created_on)"
    }
}

public struct DNSRecordPara: Encodable {
    let name: String
    let proxied: Bool
    let content: String
    let comment: String
    let ttl: Int
    let type: DNSRecord.DNSType
}

public struct DNSDate: Codable, CustomStringConvertible {
    public let date: Date

    public init(date: Date) {
        self.date = date
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let dateString = try container.decode(String.self)
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = formatter.date(from: dateString) else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Invalid DNS date format: \(dateString)"
            )
        }
        self.date = date
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let dateString = formatter.string(from: date)
        try container.encode(dateString)
    }
    
    public var description: String { date.description }
}
