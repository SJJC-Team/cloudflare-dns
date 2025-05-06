import Testing
@testable import CloudflareDNS

class SharedState {
    nonisolated(unsafe) static var id: DNSRecord.ID? = nil
}

@Suite(.serialized)
struct Tests {
    
    let cloudflare = Cloudflare(token: token, accountId: account_id, zoneId: zone_id)
    
    @Test func getAllRecords() async throws {
        let records = try await cloudflare.listRecords()
        for r in records {
            print(r)
        }
    }
    
    @Test mutating func createNewRecord() async throws {
        SharedState.id = try await cloudflare.createRecord(.init(.A, domain: "test.test.test.whooshings.space", to: "111.93.29.60", ttl: 60, proxied: false, comment: "")).id
    }
    
    @Test mutating func updateDNSRecord() async throws {
        let records = try await cloudflare.listRecords()
        let record = try #require(records.first { $0.name == "test.test.test.whooshings.space" })
        #expect(record.id == SharedState.id)
        SharedState.id = try await cloudflare.updateRecord(.init(.A, domain: "test.testing.whooshings.space", to: "123.93.29.60", ttl: 60, proxied: false, comment: ""), id: record.id).id
        let newRecords: [DNSRecord] = try await cloudflare.listRecords()
        let _ = try #require(newRecords.first { $0.name == "test.testing.whooshings.space" })
    }
    
    @Test func deleteDNSRecord() async throws {
        let records = try await cloudflare.listRecords()
        let record = try #require(records.first { $0.name == "test.testing.whooshings.space" })
        #expect(record.id == SharedState.id)
        let _ = try await cloudflare.deleteRecord(record.id)
        let newRecords: [DNSRecord] = try await cloudflare.listRecords()
        #expect(newRecords.first { $0.name == "test.testing.whooshings.space" } == nil)
    }
}

