import ArgumentParser
import Foundation
import CloudflareDNS

struct DomainRegister: ParsableCommand {

    static let configuration = CommandConfiguration(
        abstract: "在 cloudflare 中注册所给定的域名，且自动更新 nginx 配置文件",
        aliases: ["dr"]
    )

    @Option(name: .shortAndLong, help: "要注册的域名，勿重复输入根域名。根域名为: \"\(Certi.env.rootDomain)\"") var domain: String
    @Option(name: .shortAndLong, help: "该域名的转发端口") var port: Int
    @Option(name: .shortAndLong, help: "该域名指向的计算机 ip 地址，若不指定，默认为本机地址") var ipAddress: String? = nil
    @Flag(name: .shortAndLong, help: "是否申请泛域名") var wildcard = false
    @Flag(name: .shortAndLong, help: "强制申请新证书，尽管已经有同域名证书") var force = false
    @Flag(name: [.customLong("onlyHttp"), .customShort("n")], help: "是否配置 HTTPS 加密") var onlyHttp = false

    func run() throws {
        let cf = Cloudflare(
            token: Certi.env.cfToken, 
            accountId: Certi.env.cfAccountId, 
            zoneId: Certi.env.cfZoneId
        )

        let ip =  try ipAddress ?? waitAsync { try await getPublicIPAddress() }
        let fullDomain = domain + "." + Certi.env.rootDomain

        _ = try waitAsync {
            try await cf.createRecord(.init(
                .A, 
                domain: fullDomain, 
                to: ip
            ))
        }
        print("域名 \"\(fullDomain)\" CloudFlare DNS 记录注册完成".info)

        if wildcard {
            _ = try waitAsync {
                try await cf.createRecord(.init(
                    .A, 
                    domain: "*." + fullDomain, 
                    to: ip
                ))
            }
            print("域名 \"*.\(fullDomain)\" CloudFlare DNS 记录注册完成".info)
        }

        try Sh.Acme.create(
            acmeDir: Certi.acmePath, 
            domain: fullDomain, 
            port: port, 
            wildcard: wildcard, 
            force: force, 
            env: Certi.env
        )

        try Sh.Nginx.create(
            domain: fullDomain, 
            port: port, 
            https: !onlyHttp, 
            wildcard: wildcard, 
            env: Certi.env
        )

        try Sh.Nginx.restart(env: Certi.env)
    }
}