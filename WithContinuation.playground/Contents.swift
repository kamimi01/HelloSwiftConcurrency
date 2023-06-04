import Foundation

func asyncWithConcurrency() async throws -> String {
    // 内部で呼ばれる関数でcompletionhandlerがあったときでも、withCheckedThrowingContinuationを使って、async awaitの形式で大元の関数に返却することができる
    return try await withCheckedThrowingContinuation { continuation in
        asyncWithCompletionHandler { result in
            switch result {
            case .success:
                continuation.resume(returning: "success!")
            case .failure:
                continuation.resume(throwing: NSError())
            }
        }
    }
}

func asyncWithCompletionHandler(completionHandler: @escaping (Result<String, Error>) -> ()) {
    completionHandler(.success("success"))
}
