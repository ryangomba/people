import Foundation
import UIKit

enum ContactAffinity: Int, Codable, CaseIterable {
    case best = 1
    case close = 2
    case loose = 3
    case keep = 4
    case undefined = 10

    struct AffinityInfo: Identifiable {
        var title: String
        var affinity: ContactAffinity
        var days: Int
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
            .init(
                title: "Best",
                affinity: .best,
                days: 7,
                iconName: "heart",
                selectedIconName: "heart.fill",
                smallIconName: "heart.circle.fill",
                iconTintColor: .red
            ),
            .init(
                title: "Close",
                affinity: .close,
                days: 30,
                iconName: "star",
                selectedIconName: "star.fill",
                smallIconName: "star.circle.fill",
                iconTintColor: .blue
            ),
            .init(
                title: "Loose",
                affinity: .loose,
                days: 90,
                iconName: "circle",
                selectedIconName: "circle.fill",
                smallIconName: "record.circle.fill",
                iconTintColor: .gray
            ),
            .init(
                title: "Keep",
                affinity: .keep,
                days: 180,
                iconName: "hand.wave",
                selectedIconName: "hand.wave.fill",
                smallIconName: "figure.wave.circle.fill",
                iconTintColor: .darkGray
            ),
            .init(
                title: "Distant",
                affinity: .undefined,
                days: 1000000,
                iconName: "infinity",
                selectedIconName: "infinity",
                smallIconName: nil,
                iconTintColor: .black
            )
        ]
    }

    var info: AffinityInfo {
        return Self.all().first { info in info.affinity == self }!
    }
}

private struct ContactInfo: Codable, Equatable {
    var affinity: ContactAffinity
}

private typealias ContactInfoData = [String: ContactInfo]

class ContactAffinityStore {
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

    private func getInfo(_ key: String) -> ContactInfo {
        return data[key] ?? ContactInfo(affinity: .undefined)
    }

    public func get(_ key: String) -> ContactAffinity {
        return getInfo(key).affinity
    }

    private func updateInfo(_ key: String, info: ContactInfo) {
        data[key] = info
        save()
    }

    public func update(_ key: String, affinity: ContactAffinity) {
        var info = getInfo(key)
        info.affinity = affinity
        updateInfo(key, info: info)
    }
}

// TODO: make not global
let affinityStore = ContactAffinityStore()
