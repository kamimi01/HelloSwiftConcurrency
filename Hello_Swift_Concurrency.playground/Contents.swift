import UIKit
import XCTest

/// Meet async/await in Swift https://developer.apple.com/videos/play/wwdc2021/10132/
enum FetchError: Error {
    case badImage
    case badID
}

func thumnailURLRequest(for id: String) -> URLRequest {
    return URLRequest(url: URL(string: id)!)
}

// 従来のコールバック関数
func fetchImageThumnail(for id: String, completion: @escaping (Result<UIImage, Error>) -> Void) {
    let request = thumnailURLRequest(for: id)  // ここは同期メソッドなので、完了ハンドラは不要
    let task = URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error {
            completion(.failure(error))
        } else if (response as? HTTPURLResponse)?.statusCode != 200 {
            completion(.failure(FetchError.badID))
        } else {
            // 正常に動いた場合
            guard let image = UIImage(data: data!) else {
                completion(.failure(FetchError.badImage))
                return  // return しかしないと、呼び出し元にエラーが通知されないので、呼び出し元は何が起こったかわからない
            }
            image.prepareThumbnail(of: CGSize(width: 40, height: 40)) { thumnail in
                guard let thumnail = thumnail else {
                    completion(.failure(FetchError.badImage))
                    return  // return しかしないと、呼び出し元にエラーが通知されないので、呼び出し元は何が起こったかわからない
                }
                completion(.success(thumnail))
            }
        }
    }
    task.resume()
}

// async / await で書き直す
func fetchThumnail(for id: String) async throws -> UIImage {
    let request = thumnailURLRequest(for: id)
    // コールバック関数と違って、エラーをチェックして、明示的に完了ハンドラを呼び出す必要がない（try に全て集約されている）
    let (data, response) = try await URLSession.shared.data(for: request)
    guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw FetchError.badID }
    let maybeImage = UIImage(data: data)
    // プロパティやイニシャライザに対しても、非同期にすることができる（awaitをつけることができる）
    guard let thumbnail = await maybeImage?.thumbnail else { throw FetchError.badImage }
    return thumbnail
}

extension UIImage {
    var thumbnail: UIImage? {
        // 明示的なゲッターは、非同期にするために必要
        // セッターがない場合、ゲッター専用プロパティのみ、非同期にすることができる
        get async {
            let size = CGSize(width: 40, height: 40)
            return await self.byPreparingThumbnail(ofSize: size)
        }
    }
}

// テスト
class MockViewModelSpec: XCTestCase {
    func testFetchThumbnails() async throws {
        // テストでもasync/await を使うことで、XCTestExpectationを使わなくて良くなる
        let expectation = XCTestExpectation(description: "mock thumbnails completion")
        let result = try await fetchThumnail(for: "mockID")
        XCTAssertEqual(result.size, CGSize(width: 40, height: 40))
    }
}

/// Use async/await with URLSession
enum DogsError: Error {
    case invalidServerResponse
    case unsupportedImage
}

// 完了ハンドラーベースの関数
func fetchPhoto(url: URL, completionHandler: @escaping (UIImage?, Error?) -> Void?) {
    let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
        if let error = error {
            completionHandler(nil, error)
        }
        if let data = data, let httpResponse = response as? HTTPURLResponse,
           httpResponse.statusCode == 200 {
            DispatchQueue.main.async {
                completionHandler(UIImage(data: data), nil)
            }
        } else {
            completionHandler(nil, DogsError.invalidServerResponse)
        }
    }
    task.resume()
}

// async/awaitベースの関数
func fetchPhoto(url: URL) async throws -> UIImage {
    let (data, response) = try await URLSession.shared.data(from: url)

    guard let httpResponse = response as? HTTPURLResponse,
          httpResponse.statusCode == 200 else {
        throw DogsError.invalidServerResponse
    }

    guard let image = UIImage(data: data) else {
        throw DogsError.unsupportedImage
    }

    return image
}
