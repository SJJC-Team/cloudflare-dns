import Foundation
#if os(Linux)
import FoundationNetworking
#endif

public struct Cloudflare : Sendable {
    
    public let token: String
    public let accountId: String
    public let zoneId: String
    
    public init(token: String, accountId: String, zoneId: String) {
        self.token = token
        self.accountId = accountId
        self.zoneId = zoneId
    }
    
    @Sendable public func listRecords() async throws -> [DNSRecord] {
        let urlString = "https://api.cloudflare.com/client/v4/zones/\(zoneId)/dns_records"
        guard let url = URL(string: urlString) else { throw Err.invalidURL }
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let result: Result<[DNSRecord]> = try await URLSession.shared.sendRequest(req)
        return result.result
    }
    
    @Sendable public func createRecord(_ record: DNSRecordPara) async throws -> DNSRecord {
        let urlString = "https://api.cloudflare.com/client/v4/zones/\(zoneId)/dns_records"
        guard let url = URL(string: urlString) else { throw Err.invalidURL }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        do {
            req.httpBody = try JSONEncoder().encode(record)
        } catch let err {
            throw Err.encodeFailed.subErr(err)
        }
        let res: Result<DNSRecord> = try await URLSession.shared.sendRequest(req)
        guard res.success else {
            throw NetworkErr.responseError(msg: res.errors)
        }
        return res.result
    }
    
    @Sendable public func deleteRecord(_ id: DNSRecord.ID) async throws -> DNSRecord.ID {
        let urlString = "https://api.cloudflare.com/client/v4/zones/\(zoneId)/dns_records/\(id)"
        guard let url = URL(string: urlString) else { throw Err.invalidURL }
        var req = URLRequest(url: url)
        req.httpMethod = "DELETE"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let res: Result<DeleteResult> = try await URLSession.shared.sendRequest(req)
        guard res.success else {
            throw NetworkErr.responseError(msg: res.errors)
        }
        return res.result.id
    }
    
    @Sendable public func updateRecord(_ record: DNSRecordPara, id: DNSRecord.ID) async throws -> DNSRecord {
        let urlString = "https://api.cloudflare.com/client/v4/zones/\(zoneId)/dns_records/\(id)"
        guard let url = URL(string: urlString) else { throw Err.invalidURL }
        var req = URLRequest(url: url)
        req.httpMethod = "PATCH"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        do {
            req.httpBody = try JSONEncoder().encode(record)
        } catch let err {
            throw Err.encodeFailed.subErr(err)
        }
        let res: Result<DNSRecord> = try await URLSession.shared.sendRequest(req)
        guard res.success else {
            throw NetworkErr.responseError(msg: res.errors)
        }
        return res.result
    }
    
}

extension URLSession {
    @Sendable func sendRequest<T: Decodable>(_ request: URLRequest) async throws -> T {
        let (data, response) = try await self.data(for: request)
        
        guard response is HTTPURLResponse else {
            throw NetworkErr.invalidResponse
        }
        
        do {
            let decoded = try JSONDecoder().decode(T.self, from: data)
            return decoded
        } catch {
            throw NetworkErr.decodingError(subErr: error)
        }
    }
}
