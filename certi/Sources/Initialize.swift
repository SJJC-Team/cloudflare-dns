import ArgumentParser
import Foundation

struct Initialize: ParsableCommand {

    static let configuration = CommandConfiguration(
        abstract: "在本机初始化本服务",
        discussion: """
            初始化服务需要安装 acme.sh 用于证书自动化，该服务将从 Google CA 申请证书
            因此，您需要从 Google CA 服务申请口令，具体操作如下：

            1. 到你的 Google Cloud 控制台(https://console.cloud.google.com)
            2. 打开 Cloud Shell(一般位于右上角)
            3. 若需授权，则请赋予访问权限
            4. 输入该命令 "gcloud publicca external-account-keys create"
            5. 将所生成的 eab-keyId 与 eab-b64MacKey 分别提供于本程序的 -keyId 以及 -hmac 参数
            """,
        aliases: ["init"]
    )

    @Option(name: .shortAndLong, help: "提供一个邮箱用于接收证书服务的通知") var email: String
    @Option(name: .shortAndLong, help: "Google CA 提供的 eab-keyId") var keyId: String
    @Option(name: [.customLong("hmac"), .customShort("m")], help: "Google CA 提供的 eab-b64MacKey") var hmac: String

    func run() throws {
        if FS.isExist(path: Certi.acmePath, dir: true) {
            print("Acme 已经安装".info)
        } else {
            print("Acme 未安装，进行安装...".info)
            try Sh.Acme.initialize(email: email, eabKey: keyId, eabHmac: hmac, env: Certi.env);
        }

        guard let url = Bundle.module.url(forResource: "nginx", withExtension: "conf") else {
            print("Nginx 样板配置文件未找到".err)
            return
        }
        try FS.rm(path: "/etc/nginx/nginx.conf")
        try FS.cp(path: url.path, to: "/etc/nginx/nginx.conf")
    }
}