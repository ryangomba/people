import Foundation
import UIKit

enum ContactAffinity: Int, Codable {
    case best = 1
    case close = 2
    case loose = 3
    case undefined = 10

    struct AffinityInfo: Identifiable {
        var title: String
        var affinity: ContactAffinity
        var iconName: String
        var selectedIconName: String
        var smallIconName: String?
        var iconTintColor: UIColor
        var id: String {
            title
        }
    }
    static func all() -> [AffinityInfo] {
        return [
            AffinityInfo(title: "Best", affinity: .best, iconName: "heart", selectedIconName: "heart.fill", smallIconName: "heart.circle.fill", iconTintColor: .red),
            AffinityInfo(title: "Close", affinity: .close, iconName: "star", selectedIconName: "star.fill", smallIconName: "star.circle.fill", iconTintColor: .orange),
            AffinityInfo(title: "Loose", affinity: .loose, iconName: "circle", selectedIconName: "circle.fill", smallIconName: "record.circle.fill", iconTintColor: .blue),
            AffinityInfo(title: "Distant", affinity: .undefined, iconName: "infinity", selectedIconName: "infinity", smallIconName: nil, iconTintColor: .black)
        ]
    }
    var info: AffinityInfo {
        return Self.all().first { info in info.affinity == self }!
    }
    var name: String {
        return ContactAffinity.all().first { i in
            i.affinity == self
        }!.title
    }
}

struct ContactInfo: Codable, Equatable {
    var affinity: ContactAffinity
}

typealias ContactInfoData = [String: ContactInfo]

class ContactInfoStore {
    private var data: ContactInfoData = [:]

    init() {
        load()
    }

    private var cacheURL: URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentDirectory = paths[0]
        return documentDirectory.appendingPathComponent("contactInfo2.json")
    }

    private func load() {
        if FileManager.default.fileExists(atPath: cacheURL.path) {
            let jsonData = try! String(contentsOfFile: cacheURL.path).data(using: .utf8)!
            let decodedData = try! JSONDecoder().decode(ContactInfoData.self, from: jsonData)
            data = decodedData
        }
    }

    private func save() {
        let data = try! JSONEncoder().encode(data)
        try! data.write(to: cacheURL)
    }

    func get(_ key: String) -> ContactInfo {
        return data[key] ?? ContactInfo(affinity: .undefined)
    }

    func update(_ key: String, info: ContactInfo) {
        data[key] = info
        save()
    }
}
