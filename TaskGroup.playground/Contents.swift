import Foundation

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
