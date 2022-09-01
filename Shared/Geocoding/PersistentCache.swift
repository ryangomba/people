import Foundation

private struct CacheResult<T: Codable>: Codable {
    let result: T?
    let lastAccessed: Date
}

private struct CacheData<T: Codable>: Codable {
    var requests: [String: CacheResult<T>]
}

class PersistentCache<T: Codable> {
    private var name: String
    private var maxSize: Int
    private var cacheData = CacheData<T>(requests: [:])

    init(name: String, maxSize: Int = 100) {
        self.name = name
        self.maxSize = maxSize
        load()
    }

    private var cacheURL: URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentDirectory = paths[0]
        return documentDirectory.appendingPathComponent(name + ".json")
    }

    private func load() {
        if FileManager.default.fileExists(atPath: cacheURL.path) {
            let jsonData = try! String(contentsOfFile: cacheURL.path).data(using: .utf8)!
            let decodedData = try! JSONDecoder().decode(CacheData<T>.self, from: jsonData)
            cacheData = decodedData
        }
    }

    private func save() {
        let data = try! JSONEncoder().encode(cacheData)
        try! data.write(to: cacheURL)
    }

    func get(_ key: String) -> (cached: Bool, result: T?) {
        if let cacheResult = cacheData.requests[key] {
            update(key, result: cacheResult.result)
            return (true, cacheResult.result)
        } else {
            return (false, nil)
        }
    }

    func update(_ key: String, result: T?) {
        let cacheResult = CacheResult(result: result, lastAccessed: .now)
        cacheData.requests[key] = cacheResult
        trim()
        save()
    }

    private struct CacheEntry: Codable {
        let key: String
        let timeSinceLastAccessed: TimeInterval
    }
    private func trim() {
        if cacheData.requests.count <= maxSize {
            return
        }
        let now = Date.now
        let purgeCount = max(maxSize / 10, 1)
        let sortedEntries = cacheData.requests.map { key, cacheResult in
            return CacheEntry(key: key, timeSinceLastAccessed: now.timeIntervalSince(cacheResult.lastAccessed))
        }.sorted { e1, e2 in
            e1.timeSinceLastAccessed < e2.timeSinceLastAccessed
        }
        sortedEntries.suffix(purgeCount).forEach { e in
            cacheData.requests.removeValue(forKey: e.key)
        }
    }

}
