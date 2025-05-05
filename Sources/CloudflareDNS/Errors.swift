import Foundation

public enum Err: String, Error, CustomStringConvertible {
    case invalidURL = "URL 无效"
    case requestFailed = "URL 请求时出现错误"
    case encodeFailed = "请求体编码失败"
    public var description: String { self.rawValue }
    func subErr(_ err: Error) -> WrappedErr { WrappedErr(self, err) }
}

public enum NetworkErr: Error {
    case invalidResponse
    case badStatusCode(code: Int)
    case decodingError(subErr: Error)
    case responseError(msg: [ResultError])
}

public struct WrappedErr: Error, CustomStringConvertible {
    public let error: Err
    public let subErr: Error
    init(_ err: Err, _ subErr: Error) {
        self.error = err
        self.subErr = subErr
    }
    public var description: String { "\(error)(\(subErr))" }
}
