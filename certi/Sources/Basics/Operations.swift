import Foundation

struct Sh {

    enum Err: String, ErrList {
        case fileNotFound = "文件不存在"
        case shellExecuteFailed = "shell 执行失败"
        case shellExceptionExit = "shell 异常退出"
        case ipAddrUnknowError = "获取 IP 地址时出现未知错误"
    }

    struct File {
        enum Shell: String {
            case acmeInit = "acme_init"
            case acmeNewCert = "acme_new_cert"
            case acmeDeleteCert = "acme_delete_cert"
            case nginxNewHttp = "nginx_new_http"
            case nginxNewHttps = "nginx_new_https"
            case nginxDeleteConf = "nginx_delete_conf"
        }

        static func sh(_ shell: Shell) throws -> String {
            guard let filePath = Bundle.module.path(forResource: shell.rawValue, ofType: "sh") else { throw Err.fileNotFound }
            return filePath
        }
    }

    struct Acme {
        enum Err: String, ErrList {
            case initUnkownError = "acme 初始化时发生位置错误"
            case certIssueFailed = "acme 证书颁发失败"
            case certInstallFailed = "acme 证书安装失败"
            case certIssueUnknowError = "证书颁发时发生未知错误"
            case certDeleteFailed = "acme 证书删除失败"
            case certDeleteUnknowError = "证书删除时发生未知错误"
        }

        static func initialize(acmeDir: String = Certi.acmePath, email: String, eabKey: String, eabHmac: String, env: Env) throws {
            let res = try run(in: File.sh(.acmeInit), paras: ["email": email, "eab_kid": eabKey, "eab_hmac": eabHmac, "acme_dir": acmeDir], env: env)
            switch res.code {
                case 0: print("Acme 初始化成功，位于 \"\(acmeDir)\"".info)
                default: throw Err.initUnkownError.d(String(data: res.res, encoding: .utf8)!)
            }
        }

        static func create(acmeDir: String = Certi.acmePath, domain: String, port: Int, wildcard: Bool = false, force: Bool = true, env: Env) throws {
            let res = try run(in: File.sh(.acmeNewCert), paras: ["domain": domain, "port": String(port), "wildcard": String(wildcard ? "true" : ""), "force": String(force), "acme_dir": acmeDir], env: env)
            switch res.code {
                case 1: throw Err.certIssueFailed.d(String(data: res.res, encoding: .utf8)!)
                case 2: throw Err.certInstallFailed.d(String(data: res.res, encoding: .utf8)!)
                case 0: print("\(domain) 域名证书创建成功".info)
                default: throw Err.certIssueUnknowError.d(String(data: res.res, encoding: .utf8)!)
            }
        }

        static func delete(acmeDir: String = Certi.acmePath, domain: String, wildcard: Bool = false, env: Env) throws {
            let res = try run(in: File.sh(.acmeDeleteCert), paras: ["domain": domain, "wildcard": String(wildcard ? "true" : ""), "acme_dir": acmeDir], env: env)
            switch res.code {
                case 1: throw Err.certDeleteFailed.d(String(data: res.res, encoding: .utf8)!)
                case 0: print("\(domain) 域名证书删除成功".info)
                default: throw Err.certDeleteUnknowError.d(String(data: res.res, encoding: .utf8)!)
            }
        }
    }

    struct Nginx {

        enum Err: String, ErrList {
            case nginxCreateUnknowErr = "Nginx 配置出现未知错误"
            case nginxDeleteUnknowErr = "Nginx 删除配置时出现未知错误"
            case nginxRestartUnknowErr = "Nginx 重启时出现未知错误"
        }

        static func create(domain: String, port: Int, https: Bool, wildcard: Bool = true, env: Env) throws {
            let res = try run(in: File.sh(https ? .nginxNewHttps : .nginxNewHttp), paras: ["domain": domain, "port": String(port), "wildcard": String(wildcard ? "true" : "")], env: env)
            switch res.code {
                case 0: print("\(domain) Nginx 配置成功".info)
                default: throw Err.nginxCreateUnknowErr.d(String(data: res.res, encoding: .utf8)!)
            }
        }

        static func delete(domain: String, env: Env) throws {
            let res = try run(in: File.sh(.nginxDeleteConf), paras: ["domain": domain], env: env)
            switch res.code {
                case 0: print("\(domain) Nginx 删除配置成功".info)
                default: throw Err.nginxDeleteUnknowErr.d(String(data: res.res, encoding: .utf8)!)
            }
        }

        static func restart(env: Env) throws {
            let res = try run("systemctl restart nginx", env: env)
            switch res.code {
                case 0: print("Nginx 重启成功".info)
                default: throw Err.nginxRestartUnknowErr.d(String(data: res.res, encoding: .utf8)!)
            }
        }
        
    }

    static func isServing(port: Int) throws -> Bool {
        let res = try run("lsof -i :\(port)", env: Env())
        return res.res.count > 0
    }

    static func ipAddr() throws -> String {
        let res = try run("curl -s https://ipinfo.io/ip", env: Env())
        switch res.code {
            case 0: return String(data: res.res, encoding: .utf8)!
            default: throw Err.ipAddrUnknowError.d(String(data: res.res, encoding: .utf8)!)
        }
    }

    static func run(_ arguments: [String], paras: [String: String] = [:], env: Env) throws -> (code: Int32, res: Data) {
        let task = Process()
        let pipe = Pipe()
        task.executableURL = URL(fileURLWithPath: "/bin/bash")
        task.environment = ProcessInfo.processInfo.environment.merging(env.envs) { (_, new) in new }.merging(paras) { (_, new) in new }
        task.arguments = arguments
        task.standardOutput = pipe
        task.standardError = pipe
        do { try task.run() } catch let err { throw Err.shellExecuteFailed.d(err.localizedDescription) }
        task.waitUntilExit()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return (task.terminationStatus, data)
    }
    
    static func run(_ command: String, paras: [String: String] = [:], env: Env) throws -> (code: Int32, res: Data) { try run(["-c", command], paras: paras, env: env) }

    static func run(in path: String, paras: [String: String] = [:], env: Env) throws -> (code: Int32, res: Data) { try run([path], paras: paras, env:env) }
}

struct FS {

    enum Err: String, ErrList {
        case dirTraversalFailed = "目录遍历失败"
        case fileCreateFailed = "文件创建失败"
        case dirCreateFailed = "目录创建失败"
        case setPermissionFailed = "设置权限失败"
        case dirExist = "目录已存在"
        case mvFailed = "移动文件失败"
        case cpFailed = "拷贝文件失败"
        case rmFailed = "删除文件失败"
        case envFileNotExist = "Env 文件不存在"
        case envFileOpenFailed = "Env 文件打开失败"
        case envContentNotValid = "要写入的 Env 内容无效"
    }

    #if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
    nonisolated(unsafe) static let fileManager = FileManager.default
    #else
    static let fileManager = FileManager.default
    #endif

    static func ls(path: String, dir: Bool = false, hiddenFile: Bool = false) throws -> [String] {
        guard let files = try? fileManager.contentsOfDirectory(atPath: path) else { throw Err.dirTraversalFailed.d(path) }
        return files.filter { (file) -> Bool in
            var isDir: ObjCBool = false
            let _ = fileManager.fileExists(atPath: NSString(string: path).appendingPathComponent(file), isDirectory: &isDir)
            let isHidden = file.hasPrefix(".")
            return isDir.boolValue == dir && (hiddenFile || !isHidden)
        }
    }

    static func mkdir(path: String, slience: Bool = true, withIntermediates p: Bool = false, output: Bool = true) throws {
        if !fileManager.fileExists(atPath: path) {
            do { try fileManager.createDirectory(atPath: path, withIntermediateDirectories: p, attributes: nil) } catch let err { throw Err.dirCreateFailed.d(err.localizedDescription) }
            if (output) { print("创建目录: \(path) 成功".info) }
            return
        } else if !slience { throw Err.dirExist }
        if (output) { print("目录: \(path) 已存在，无需创建".info) }
    }

    static func mv(path: String, to: String) throws {
        do { try fileManager.moveItem(atPath: path, toPath: to) } catch let err { throw Err.mvFailed.d(err.localizedDescription) }
        print("移动文件: \(path) 到 \(to) 成功".info)
    }

    static func cp(path: String, to: String) throws {
        do { try fileManager.copyItem(atPath: path, toPath: to) } catch let err { throw Err.cpFailed.d(err.localizedDescription) }
        print("复制文件: \(path) 到 \(to) 成功".info)
    }

    static func rm(path: String) throws {
        do { try fileManager.removeItem(atPath: path) } catch let err { throw Err.rmFailed.d(err.localizedDescription) }
        print("删除文件: \(path) 成功".info)
    }

    static func createEnvFile(at path: String, with content: [String: String]) throws {
        let envContent = content.map { "\($0.key)=\($0.value)" }.joined(separator: "\n") + "\n"
        guard fileManager.createFile(atPath: path, contents: envContent.data(using: .utf8), attributes: nil) else { throw Err.fileCreateFailed.d(path) }
        print("创建 env 文件: \(path) 成功".info)
    }

    static func appendEnvFile(to path: String, with content: [String: String]) throws {
        let envContent = content.map { "\($0.key)=\($0.value)" }.joined(separator: "\n") + "\n"
        guard isExist(path: path, dir: false) else { throw Err.envFileNotExist.d(path) }
        guard let file = FileHandle(forWritingAtPath: path) else { throw Err.envFileOpenFailed.d(path) }
        file.seekToEndOfFile()
        guard let data = envContent.data(using: .utf8) else { throw Err.envContentNotValid.d(path) }
        try file.write(contentsOf: data)
        print("env 文件: \(path) 环境变量追加成功".info)
    }

    static func readEnvFile(at path: String) throws -> [String: String] {
        guard let content = fileManager.contents(atPath: path),
              let contentString = String(data: content, encoding: .utf8) else {
            throw Err.fileCreateFailed.d(path)
        }
        
        var envDict = [String: String]()
        let lines = contentString.split(separator: "\n")
        for line in lines {
            let keyValue = line.split(separator: "=", maxSplits: 1)
            if keyValue.count == 2 {
                let key = String(keyValue[0]).trimmingCharacters(in: .whitespaces)
                let value = String(keyValue[1]).trimmingCharacters(in: .whitespaces)
                envDict[key] = value
            }
        }
        return envDict
    }

    static func isExist(path: String, dir: Bool = true) -> Bool {
        var isDir: ObjCBool = false
        let exists = fileManager.fileExists(atPath: path, isDirectory: &isDir)
        return exists && (isDir.boolValue == dir)
    }
    
    static func setPermissions(path: String, owner: String, group: String, permissions: Int, recursive: Bool = false) throws {
        let attributes: [FileAttributeKey: Any] = [
            .posixPermissions: permissions,
            .ownerAccountName: owner,
            .groupOwnerAccountName: group
        ]
        
        do { try fileManager.setAttributes(attributes, ofItemAtPath: path) } catch let err { throw Err.setPermissionFailed.d(err.localizedDescription) }

        if recursive {
            let enumerator = fileManager.enumerator(atPath: path)
            while let element = enumerator?.nextObject() as? String {
                let fullPath = NSString(string: path).appendingPathComponent(element)
                do { try fileManager.setAttributes(attributes, ofItemAtPath: fullPath) } catch let err { throw Err.setPermissionFailed.d(err.localizedDescription) }
            }
        }
        print("设置权限: \(path) 成功".info)
    }
}

struct Tool {
    static func bakName(name: String) -> String { name + "-" + Date().description }
    static func portAvailable(port: Int) -> Bool { port >= 0 && port < 20 }
}
