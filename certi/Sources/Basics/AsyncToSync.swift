import Foundation

final class ResultBox<T, G: Error> {
    var value: Result<T, G>? = nil
    init() {}
}
extension ResultBox: @unchecked Sendable {}

func waitAsync<T, G>(_ operation: @Sendable @escaping () async throws(G) -> T) throws(G) -> T {
    let semaphore = DispatchSemaphore(value: 0)
    let box = ResultBox<T, G>()

    Task {
        do {
            let value = try await operation()
            box.value = .success(value)
        } catch let error {
            box.value = .failure(error as! G)
        }
        semaphore.signal()
    }

    semaphore.wait()
    return try box.value!.get()
}