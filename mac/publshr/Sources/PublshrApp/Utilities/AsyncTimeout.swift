import Foundation

enum AsyncTimeoutError: LocalizedError {
    case timedOut(seconds: TimeInterval)

    var errorDescription: String? {
        switch self {
        case .timedOut(let seconds):
            return "Timed out after \(Int(seconds)) seconds."
        }
    }
}

/// Runs `operation` and fails with `AsyncTimeoutError` if it does not finish in time.
func withAsyncTimeout<T>(
    seconds: TimeInterval,
    operation: @escaping () async throws -> T
) async throws -> T {
    try await withThrowingTaskGroup(of: T.self) { group in
        group.addTask { try await operation() }
        group.addTask {
            try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            throw AsyncTimeoutError.timedOut(seconds: seconds)
        }
        guard let result = try await group.next() else {
            throw AsyncTimeoutError.timedOut(seconds: seconds)
        }
        group.cancelAll()
        return result
    }
}

func withAsyncTimeout<T>(
    seconds: TimeInterval,
    operation: @escaping () async -> T
) async throws -> T {
    try await withAsyncTimeout(seconds: seconds) {
        await operation()
    }
}
