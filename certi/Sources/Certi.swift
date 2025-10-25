import ArgumentParser
import Foundation
import SwiftDotenv

@main
struct Certi: ParsableCommand {
    static let envPath = "/etc/certi/env"
    static let env: Env = {
        do {
            let e = try Env()
            return e
        } catch let err {
            print("环境变量读取失败 (从该路径读取: \"\(envPath)\")".err)
            fatalError(err.localizedDescription)
        }
    }()
    
    @Argument(help: "域名，不加顶级域名 \(Certi.env.cfToken)") var module: String
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
            "CERTI_CF_Token": cfToken,
            "CERTI_CF_Account_ID": cfAccountId,
            "CERTI_CF_Zone_ID": cfZoneId,
            "CERTI_NGINX_DIR": nginxDir,
            "CERTI_ROOT_DOMAIN": rootDomain
        ]
    }

    init() throws {
        try Dotenv.configure(atPath: Certi.envPath)
        guard
            let cfToken = ProcessInfo.processInfo.environment["CERTI_CF_Token"],
            let cfAccountId = ProcessInfo.processInfo.environment["CERTI_CF_Account_ID"],
            let cfZoneId = ProcessInfo.processInfo.environment["CERTI_CF_Zone_ID"],
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
