import Foundation

extension Array where Element: Hashable {
    func removingDuplicates() -> [Element] {
        var addedDict = [Element: Bool]()
        return filter {
            addedDict.updateValue(true, forKey: $0) == nil
        }
    }
    mutating func removeDuplicates() {
        self = self.removingDuplicates()
    }
}

extension Array where Element: Identifiable {
    func removingDuplicateIDs() -> [Element] {
        var addedDict = [Element.ID: Bool]()
        return filter {
            addedDict.updateValue(true, forKey: $0.id) == nil
        }
    }
    mutating func removeDuplicateIDs() {
        self = self.removingDuplicateIDs()
    }
}
