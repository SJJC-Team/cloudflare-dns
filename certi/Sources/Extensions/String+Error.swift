import ArgumentParser

protocol ErrList: Error, CustomStringConvertible {
    var rawValue: String { get }
    func d(_ detail: String) -> String
}

extension String: @retroactive Error {}

extension ErrList {
    var description: String { (String(reflecting: Self.self) + ":" + self.rawValue).err }
    func d(_ detail: String) -> String {
        let trimmedDetail = detail.trimmingCharacters(in: .whitespacesAndNewlines)
        return (String(reflecting: Self.self) + ":" + self.rawValue + (trimmedDetail.isEmpty ? "" : "(" + trimmedDetail + ")")).err
    }
}

extension String {
    var err: String { "\u{001B}[31m\(self)\u{001B}[0m" }
    var info: String { "\u{001B}[34m\(self)\u{001B}[0m" }
    var succ: String { "\u{001B}[32m\(self)\u{001B}[0m" }
    var warn: String { "\u{001B}[33m\(self)\u{001B}[0m" }
}
