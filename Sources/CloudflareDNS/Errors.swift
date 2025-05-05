import Foundation

public enum Err: String, Error, CustomStringConvertible, Sendable {
    case invalidURL = "URL 无效"
    case requestFailed = "URL 请求时出现错误"
    case encodeFailed = "请求体编码失败"
    public var description: String { self.rawValue }
    @Sendable func subErr(_ err: Error) -> WrappedErr { WrappedErr(self, err) }
}

public enum NetworkErr: Error, Sendable {
    case invalidResponse
    case badStatusCode(code: Int)
    case decodingError(subErr: Error)
    case responseError(msg: [ResultError])
}

public struct WrappedErr: Error, CustomStringConvertible, Sendable {
    public let error: Err
    public let subErr: Error
    
    @Sendable init(_ err: Err, _ subErr: Error) {
        self.error = err
        self.subErr = subErr
    }
    
    public var description: String { "\(error)(\(subErr))" }
}
