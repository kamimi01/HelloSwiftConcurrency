struct Quake {
    var location: String
    var magnitude: Int
}

class QuakeMonitor {
    var quakeHandler: (_ quake: Quake) -> Void

    func startMonitoring() {
        print("start")
    }

    func stopMonitoring() {
        print("stop")
    }

//    func doSomething(quake: Quake) {
//        print("do something")
//    }

    init() {

    }
}

// 従来の使い方
let monitor = QuakeMonitor()
monitor.quakeHandler = { quake in

}

monitor.startMonitoring()
monitor.stopMonitoring()

// AsyncStreamを使った使い方
let quakes = AsyncStream(Quake.self) { continuation in  // 要素の型を指定する
    let monitor = QuakeMonitor()
    monitor.quakeHandler = { quake in
        continuation.yield(quake)
    }
    continuation.onTermination = { _ in
        monitor.stopMonitoring()
    }

    monitor.startMonitoring()
}

// ↑のループを使う時
let significantQuakes = quakes.filter { quake in
    quake.magnitude > 3
}

for await quake in significantQuakes {
    
}
