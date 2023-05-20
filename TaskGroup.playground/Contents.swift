import Foundation
import UIKit

// https://zenn.dev/dena/articles/0c4f7a8232e64b#taskgroup-%E3%81%AE%E5%9F%BA%E6%9C%AC

func num1() async -> Int {
    try! await Task.sleep(for: .seconds(1))
    return 1
}

func num2() async -> Int {
    try! await Task.sleep(for: .seconds(2))
    return 2
}

let results = await withTaskGroup(of: (Int, Int).self) { group in
    var results: [Int: Int] = [:]

    group.addTask {
        print("print No.1")
        return (1, await num1())
    }

    group.addTask {
        print("print No.2")
        return (2, await num2())
    }

    for await (index, result) in group {
        print("print No.3:", index)
        results[index] = result
    }

    return results
}

print(results[1]!, results[2]!)

func imageRequest(for: String) -> URLRequest {
    return URLRequest(url: URL(string: "")!)
}

func metadataRequest(for: String) -> URLRequest {
    return URLRequest(url: URL(string: "")!)
}

func parseSize(from: Data) -> CGSize? {
    return .zero
}

// https://developer.apple.com/videos/play/wwdc2021/10134
// async let
func fetchOneThumbnail(withID id: String) async throws -> UIImage {
    let imageReq = imageRequest(for: id), metaDataReq = metadataRequest(for: id)
    // 以下２つのデータダウンロードは、子タスクで実行されるので、awaitすることは不要になる
    async let (data, _) = URLSession.shared.data(for: imageReq)
    async let (metadata, _) = URLSession.shared.data(for: metaDataReq)
    // 代わりに、使用する時には値が必要なので、ここでawaitをする
    guard let size = try await parseSize(from: metadata),
          let image = try await UIImage(data: data)?.byPreparingThumbnail(ofSize: size)
    else { throw NSError() }
    return image
}

func fetchThumbnails(for ids: [String]) async throws -> [String: UIImage] {
    var thumbnails: [String: UIImage] = [:]
    for id in ids {
        // タスクがキャンセルされた場合にエラーをthrowする
        try Task.checkCancellation()
        // エラーをthrowするのではなく、何か独自の処理をしたい場合は、以下のように書ける
//        if Task.isCancelled { break }
        thumbnails[id] = try await fetchOneThumbnail(withID: id)
    }
    return thumbnails
}

func fetchThumbnailsMoreEfficiently(for ids: [String]) async throws -> [String: UIImage] {
    var thumbnails: [String: UIImage] = [:]
    // 動的な数のループがある場合、各要素の処理を同時に実行したい場合
    try await withThrowingTaskGroup(of: (String, UIImage).self) { group in
        for id in ids {
            // 子タスクを作成する→任意のタイミングで実行を開始する
            group.addTask {
                return (id, try await fetchOneThumbnail(withID: id))
                // 以下の書き方のままだと、1つのthumbnailsに複数のタスクが同時に値を挿入しようとした時にクラッシュなどを引き起こす可能性がある（=データ競合）
//                thumbnails[id] = try await fetchOneThumbnail(withID: id)
            }
        }
        // 子タスクが完了した順に結果を取得する
        for try await (id, thumbnail) in group {
            thumbnails[id] = thumbnail
        }
    }
    return thumbnails
}
