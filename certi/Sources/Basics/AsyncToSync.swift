import Foundation

final class ResultBox<T> {
    var value: Result<T, Error>? = nil
    init() {}
}
extension ResultBox: @unchecked Sendable {}

func waitAsync<T>(_ operation: @Sendable @escaping () async throws -> T) throws -> T {
    let semaphore = DispatchSemaphore(value: 0)
    let box = ResultBox<T>()

    Task {
        do {
            let value = try await operation()
            box.value = .success(value)
        } catch {
            box.value = .failure(error)
        }
        semaphore.signal()
    }

    semaphore.wait()
    return try box.value!.get()
}