import ArgumentParser
import Foundation
import SwiftDotenv

@main
struct Certi: ParsableCommand {
    static let envPath = "/etc/certi/env"
    static let acmePath = "/root/.acme.sh"
    static let env: Env = {
        do {
            let e = try Env()
            return e
        } catch let err {
            print("环境变量读取失败 (从该路径读取: \"\(envPath)\")".err)
            fatalError(err.localizedDescription)
        }
    }()

    static let configuration = CommandConfiguration(
        abstract: "提供证书以及域名相关的设置，该脚本自动连接 CloudFlare，且将自动调整 Nginx 配置文件",
        discussion: """
        当前作用配置:

            根域名: \(env.rootDomain)
            Nginx 配置文件目录: \(env.nginxDir)
            acme 工具目录: \(acmePath)

            环境配置文件: \(envPath)
        """,
        subcommands: [
            Initialize.self,
            DomainRegister.self
        ]
    )
}

struct Env {
    enum Err: String, ErrList {
        case envErr = "环境变量导入失败"
    }

    let cfToken: String
    let cfAccountId: String
    let cfZoneId: String
    let nginxDir: String
    let rootDomain: String

    var envs: [String: String] {
        [
            "CF_Token": cfToken,
            "CF_Account_ID": cfAccountId,
            "CF_Zone_ID": cfZoneId,
            "CERTI_NGINX_DIR": nginxDir,
            "CERTI_ROOT_DOMAIN": rootDomain
        ]
    }

    init() throws {
        try Dotenv.configure(atPath: Certi.envPath)
        guard
            let cfToken = ProcessInfo.processInfo.environment["CF_Token"],
            let cfAccountId = ProcessInfo.processInfo.environment["CF_Account_ID"],
            let cfZoneId = ProcessInfo.processInfo.environment["CF_Zone_ID"],
            let nginxDir = ProcessInfo.processInfo.environment["CERTI_NGINX_DIR"],
            let rootDomain = ProcessInfo.processInfo.environment["CERTI_ROOT_DOMAIN"]
        else { throw Err.envErr }
        
        self.cfToken = cfToken
        self.cfAccountId = cfAccountId
        self.cfZoneId = cfZoneId
        self.nginxDir = nginxDir
        self.rootDomain = rootDomain
    }
}
