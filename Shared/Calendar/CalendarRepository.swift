import UIKit
import EventKit

enum CalendarAuthStatus: Int {
    case notDetermined = 1
    case authorized = 2
    case denied = 3
}

class CalendarRepository: ObservableObject {
    public var authorizationStatus = getAuthorizationStatus()
    private let store = EKEventStore()
    @Published var calendarEvents: [CalendarEvent] = []

    init() {
        NotificationCenter.default.addObserver(self, selector: #selector(onForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onEventStoreDidChange), name: .EKEventStoreChanged, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc
    func onForeground() {
        updateAuthorizationStatus()
        sync() // TODO: temp?
    }

    @objc
    func onEventStoreDidChange(notification: NSNotification) {
        print("System calendar did change")
        DispatchQueue.main.async {
            self.sync()
        }
    }

    private static func getAuthorizationStatus() -> CalendarAuthStatus {
        switch EKEventStore.authorizationStatus(for: .event) {
        case .authorized:
            return .authorized
        case .denied, .restricted:
            return .denied
        case .notDetermined:
            return .notDetermined
        default:
            // Assume authorized if we don't recognize the status
            return .authorized
        }
    }

    private func updateAuthorizationStatus() {
        let newAuthorizationStatus = Self.getAuthorizationStatus()
        if newAuthorizationStatus != authorizationStatus {
            authorizationStatus = newAuthorizationStatus
            app.store.dispatch(CalendarAccessChanged(status: newAuthorizationStatus))
            if newAuthorizationStatus == .authorized {
                sync()
            }
        }
    }

    public func requestAuthorization() {
        assert(Thread.isMainThread)

        store.requestAccess(to: .event) { ok, error in
            DispatchQueue.main.async {
                self.updateAuthorizationStatus()
            }
        }
    }

    public func sync() {
        assert(Thread.isMainThread)

        if authorizationStatus != .authorized {
            return
        }
        Task.init {
            let newCalendarEvents = await fetchSystemCalendarEvents()
            DispatchQueue.main.async {
                self.setCalendarEvents(newCalendarEvents)
            }
        }
    }

    // Fetching from system calendar

    private func fetchSystemCalendarEvents() async -> [CalendarEvent] {
        store.refreshSourcesIfNecessary()
        var calendarEvents: [CalendarEvent] = []
        let calendars = store.calendars(for: .event)
        let start = Date().addingTimeInterval(-60 * 60 * 24 * 365) // Look back 1 year
        let end = Date().addingTimeInterval(60 * 60 * 24 * 365) // Look forward 1 year
        for calendar in calendars {
            // This checking will remove Birthdays and Hollidays callendars
            guard calendar.allowsContentModifications else {
                continue
            }
            if calendar.title != "Personal" {
                continue
            }
            let predicate = store.predicateForEvents(withStart: start, end: end, calendars: [calendar])
            let events = store.events(matching: predicate)
            for event in events {
                if !(event.organizer?.isCurrentUser ?? false) {
                    continue
                }
                if !event.hasAttendees {
                    continue
                }
                // TODO: what a hack!
                if event.title == "Family chat" {
                    continue
                }
                var attendeeEmails: [String] = []
                event.attendees?.forEach({ participant in
                    if !participant.isCurrentUser && participant.participantStatus != .declined {
                        if let email = participant.email {
                            attendeeEmails.append(email.lowercased())
                        }
                    }
                })
                calendarEvents.append(CalendarEvent(
                    id: event.eventIdentifier,
                    title: event.title,
                    startDate: event.startDate,
                    endDate: event.endDate,
                    isAllDay: event.isAllDay,
                    attendeeEmails: attendeeEmails
                ))
            }
        }
        return calendarEvents
    }

    private func setCalendarEvents(_ newCalendarEvents: [CalendarEvent]) {
        let sortedCalendarEvents = newCalendarEvents.sorted()
        if calendarEvents == sortedCalendarEvents {
            return
        }
        calendarEvents = sortedCalendarEvents
        app.store.dispatch(CalendarChanged(newCalendarEvents: sortedCalendarEvents))
    }

    // Fetching

    public func getCalendarEvent(_ id: String) -> CalendarEvent {
        assert(Thread.isMainThread)

        return calendarEvents.first { c in c.id == id }!
    }

}

extension EKParticipant {
    var email: String? {
        // Try to get email from inner property
        if self.responds(to: Selector(("emailAddress"))), let email = value(forKey: "emailAddress") as? String {
            return email
        }
        // Getting email from URL
        let urlString = self.url.absoluteString
        if urlString.hasPrefix("mailto:") {
            return String(urlString.split(separator: "mailto:")[1])
        }
        // Getting info from description
        let emailComponents = description.split(separator: "email = ")
        if emailComponents.count > 1 {
            let email = emailComponents[1].split(separator: ";")[0]
            return String(email)
        }
        return nil
    }
}
