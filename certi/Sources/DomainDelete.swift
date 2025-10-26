import ArgumentParser
import Foundation
import CloudflareDNS

struct DomainDelete: ParsableCommand {

    static let configuration = CommandConfiguration(
        abstract: "在 cloudflare 中删除所给定的域名，证书以及 nginx 配置文件",
        aliases: ["dd"]
    )

    @Option(name: .shortAndLong, help: "要删除的域名，勿重复输入根域名。根域名为: \"\(Certi.env.rootDomain)\"") var domain: String = ""

    func run() throws {
        let cf = Cloudflare(
            token: Certi.env.cfToken, 
            accountId: Certi.env.cfAccountId, 
            zoneId: Certi.env.cfZoneId
        )

        let records = try waitAsync { try await cf.listRecords() }
        let fullDomain = domain == "" ? Certi.env.rootDomain : (domain + "." + Certi.env.rootDomain)

        var count = 0

        for record in records {
            if record.name == fullDomain {
                _ = try waitAsync { try await cf.deleteRecord(record.id) }
                print("[CloudFlare] 域名 \"\(fullDomain)\" DNS 记录被删除".info)
                count += 1
                if count == 2 { break }
            } else if record.name == ("*." + fullDomain) {
                _ = try waitAsync { try await cf.deleteRecord(record.id) }
                print("[CloudFlare] 域名 \"*.\(fullDomain)\" DNS 记录被删除".info)
                count += 1
                if count == 2 { break }
            }
        }

        guard count > 0 else {
            print("[CloudFlare] 未找到该域名 \"\(fullDomain)\" 的 DNS 记录".err)
            return
        }

        try Sh.Acme.delete(
            acmeDir: Certi.acmePath, 
            domain: fullDomain, 
            wildcard: count == 1 ? false : true, 
            env: Certi.env
        )

        try Sh.Nginx.delete(domain: fullDomain, env: Certi.env)

        try Sh.Nginx.restart(env: Certi.env)
    }
}