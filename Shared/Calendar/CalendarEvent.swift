import Foundation

struct CalendarEvent: Identifiable, Equatable, Comparable {
    static func < (lhs: CalendarEvent, rhs: CalendarEvent) -> Bool {
        let dateCompare = lhs.startDate.compare(rhs.startDate)
        if dateCompare == .orderedAscending {
            return false
        }
        if dateCompare == .orderedDescending {
            return true
        }
        return lhs.id < rhs.id
    }
    var id: String
    var title: String
    var startDate: Date
    var endDate: Date
    var isAllDay: Bool
    var attendeeEmails: [String]
}

extension [CalendarEvent] {
    func sorted() -> Self {
        return self.sorted(by: { $0 < $1 })
    }
}

