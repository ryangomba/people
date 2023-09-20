import Foundation

extension Calendar {
    func numberOfDaysBetween(_ from: Date, and to: Date) -> Int {
        let fromDate = startOfDay(for: from) // <1>
        let toDate = startOfDay(for: to) // <2>
        let numberOfDays = dateComponents([.day], from: fromDate, to: toDate) // <3>
        return numberOfDays.day!
    }
}

extension Date {
    func formatRelative() -> String {
        let days = Calendar.current.numberOfDaysBetween(self, and: Date())
        if days == -1 {
            return "tomorrow"
        } else if days == 0 {
            return "today"
        } else if days == 1 {
            return "yesterday"
        } else if days < 0 {
            if days <= -30 {
                let months = days / 30
                if months == 1 {
                    return "in a month"
                } else {
                    return "in \(days / 30) months"
                }
            } else if days > -7 {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "EEEE"
                return dateFormatter.string(from: self)
            } else {
                return "in \(-days) days"
            }
        } else if days < 30 {
            return "\(days) days ago"
        } else {
            let months = days / 30
            if months == 1 {
                return "a month ago"
            } else {
                return "\(days / 30) months ago"
            }
        }
    }
}
