# CloudflareDNS
Swift 编写的 Cloudflare DNS 库，用于编辑 Cloudflare 的域名 DNS 记录

### 安装

在 `Package.swift` 中添加依赖：

```swift
.package(url: "https://github.com/SJJC-Team/cloudflare-dns.git", from: "1.0.3")
```

为 `Target` 设置依赖：

```swift
.target(
    name: "XXXX",
    dependencies: [
	.product(name: "CloudflareDNS", package: "cloudflare-dns")
    ]
)
```



### 使用

导入该依赖库

```swift
import CloudflareDNS
```

初始化一个 `Cloudflare` 对象:

```swift
let cloudflare = Cloudflare(token: token, accountId: account_id, zoneId: zone_id)
```

> 你需要事先在 Cloudflare 云平台找到域名的 Token，Account ID 以及 Zone ID

#### [增] 创建一个 DNS 记录

```swift
try await cloudflare.createRecord(.init(.A, domain: "testing.example.com", to: "123.123.123.123"))
```

这个动作增加一个 `A` 类型的 DNS 记录，表示域名 `testing.example.com` 指向 `123.123.123.123` ipv4 地址

> DNS 记录类型枚举见 [DNSRecord.swift](Sources/CloudflareDNS/DNSRecord.swift) 的 `DNSRecord.DNSType`
>
> 该函数无返回值，如果失败会抛出错误

#### [删] 删除一个 DNS 记录

```swift
try await cloudflare.deleteRecord(record.id)
```

删除一条指定 `id` 的 DNS 记录，如果 DNS 记录中不包含该 `id` 的记录，则会抛出错误

> 该函数无返回值，如果失败会抛出错误

#### [该] 更新一个 DNS 记录

```swift
try await cloudflare.updateRecord(.init(.A, domain: "testing.example.com", to: "123.123.123.123"), id: record.id)
```

该动作将一条指定 `id` 的 DNS 记录更新为所提供的参数

> 该函数无返回值，如果失败会抛出错误

#### [查] 查询 DNS 记录

```swift
let records = try await cloudflare.listRecords()
```

其返回值是 `[DNSRecord]` ，见  [DNSRecord.swift](Sources/CloudflareDNS/DNSRecord.swift) 
