import Foundation

enum Err: String, Error, CustomStringConvertible {
    case invalidURL = "URL 无效"
    case requestFailed = "URL 请求时出现错误"
    case encodeFailed = "请求体编码失败"
    var description: String { self.rawValue }
    func subErr(_ err: Error) -> WrappedErr { WrappedErr(self, err) }
}

enum NetworkErr: Error {
    case invalidResponse
    case badStatusCode(code: Int)
    case decodingError(subErr: Error)
    case responseError(msg: [ResultError])
}

struct WrappedErr: Error, CustomStringConvertible {
    let error: Err
    let subErr: Error
    init(_ err: Err, _ subErr: Error) {
        self.error = err
        self.subErr = subErr
    }
    var description: String { "\(error)(\(subErr))" }
}
