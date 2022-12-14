import Foundation
import CoreLocation

struct Person: Identifiable, Equatable, Comparable {
    static func < (lhs: Person, rhs: Person) -> Bool {
        let a1 = lhs.affinity;
        let a2 = rhs.affinity;
        if (a1 != a2) {
            return a1.rawValue < a2.rawValue
        }
        return lhs.contact < rhs.contact
    }
    let contact: Contact
    let affinity: Affinity
    let calendarEvents: [CalendarEvent]
    let latestEvent: CalendarEvent?
    var id: String {
        get {
            return contact.id
        }
    }
    var overdue: Bool {
        if let latestEvent = latestEvent {
            let days = affinity.info.days
            return Date().timeIntervalSince(latestEvent.endDate) > 60 * 60 * 24 * TimeInterval(days)
        } else {
            return true
        }
    }
}

private func personFromContact(_ contact: Contact, rawCalendarEvents: [CalendarEvent]) -> Person {
    let affinity = affinityStore.get(contact.id)
    let days = affinity.info.days
    let calendarEvents = rawCalendarEvents.sorted().filter { calendarEvent in
        // Look ahead the same number of days
        calendarEvent.startDate < Date().addingTimeInterval(60 * 60 * 24 * TimeInterval(days))
    }
    return Person(
        contact: contact,
        affinity: affinity,
        calendarEvents: calendarEvents,
        latestEvent: calendarEvents.first
    )
}

func personsFromContacts(_ contacts: [Contact], calendarEvents: [CalendarEvent]) -> [Person] {
    if contacts.isEmpty || calendarEvents.isEmpty {
        return []
    }
    var emailToCalendarEventsMap: [String: [CalendarEvent]] = [:]
    for calendarEvent in calendarEvents {
        for attendeeEmail in calendarEvent.attendeeEmails {
            if let events = emailToCalendarEventsMap[attendeeEmail] {
                emailToCalendarEventsMap[attendeeEmail] = events + [calendarEvent]
            } else {
                emailToCalendarEventsMap[attendeeEmail] = [calendarEvent]
            }
        }
    }
    return contacts.map { contact in
        var matchingCalendarEvents: [CalendarEvent] = []
        for email in contact.emailAddresses {
            matchingCalendarEvents += emailToCalendarEventsMap[email] ?? []
        }
        return personFromContact(contact, rawCalendarEvents: matchingCalendarEvents)
    }
}

// PersonLocation

struct PersonLocation: Identifiable, Equatable {
    let person: Person
    let postalAddress: PostalAddress?
    var id: String {
        get {
            var id = person.id + "-"
            if let postalAddress = postalAddress {
                id += postalAddress.id
            } else {
                id += "null"
            }
            return id
        }
    }
}

struct PersonLocationResult {
    let personLocation: PersonLocation
    let distance: CLLocationDistance
}

extension Person {
    func nearestHomeLocation(to target: CLLocationCoordinate2D) -> PersonLocationResult {
        var nearestPostalAddress: PostalAddress?
        var nearestDistance: CLLocationDistance = .infinity
        contact.homeAddresses.forEach { postalAddress in
            if let coordinate = postalAddress.coordinate {
                let distance = CLLocation.distance(from: coordinate, to: target)
                if distance < nearestDistance {
                    nearestPostalAddress = postalAddress
                    nearestDistance = distance
                }
            }
        }
        return PersonLocationResult(
            personLocation: PersonLocation(person: self, postalAddress: nearestPostalAddress),
            distance: nearestDistance
        )
    }
}
