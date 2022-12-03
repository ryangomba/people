import UIKit
import EventKit

enum CalendarAuthStatus: Int {
    case notDetermined = 1
    case authorized = 2
    case denied = 3
}

class CalendarRepository {
    public var authorizationStatus = getAuthorizationStatus()
    private let store = EKEventStore()
    var calendarEvents: [CalendarEvent] = []

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
        let start = Date().addingTimeInterval(-3 * 60 * 60 * 24 * 365) // Look back 3 years
        let end = Date().addingTimeInterval(1 * 60 * 60 * 24 * 365) // Look forward 1 year
        for calendar in calendars {
            // This checking will remove Birthdays and Holidays calendars
            guard calendar.allowsContentModifications else {
                continue
            }
            if calendar.title != "Personal" {
                continue
            }
            let predicate = store.predicateForEvents(withStart: start, end: end, calendars: [calendar])
            let events = store.events(matching: predicate)
            for event in events {
                if !event.hasAttendees {
                    continue
                }
                if !(event.organizer?.isCurrentUser ?? false) {
                    continue
                }
                // TODO: what a hack!
                if event.title == "Family chat" || event.title.hasSuffix("?") {
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
                    externalID: event.calendarItemExternalIdentifier,
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

    // Opening

    public func openCalendarEvent(_ calendarEvent: CalendarEvent, googleCalendar: Bool = true) {
        if (googleCalendar) {
            let compositeIDString = String(calendarEvent.externalID.split(separator: "@").first!) + " ryan@ryangomba.com" // TODO: hack!
            let eventID = compositeIDString.data(using: .utf8)!.base64EncodedString()
            let url = URL(string: "com.google.calendar://?action=view&type=event&eid=\(eventID)")!
            UIApplication.shared.open(url)
        } else {
            // It seems that it only accepts an offset from January 01, 2001.
            let seconds = Int(calendarEvent.startDate.timeIntervalSinceReferenceDate)
            let url = URL(string: "calshow:\(seconds)")!
            UIApplication.shared.open(url)
        }
    }

    // Create

    public func createCalendarEventForRecentCall(contact: Contact) {
        let start = Date()
        let end = Date().addingTimeInterval(60*30) // 30 min
        openGoogleCalendarEventCreationPrompt(contact: contact, start: start, end: end, prefix: "Called")
    }

    public func createCalendarEventForRecentTexting(contact: Contact) {
        let start = Date()
        let end = Date().addingTimeInterval(60*30) // 30 min
        openGoogleCalendarEventCreationPrompt(contact: contact, start: start, end: end, prefix: "Texted")
    }

    public func createCalendarEventForUpcomingCall(contact: Contact) {
        let start = Date()
        let end = Date().addingTimeInterval(60*30) // 30 min
        openGoogleCalendarEventCreationPrompt(contact: contact, start: start, end: end, prefix: "Call")
    }

    public func createCalendarEventForUpcomingMeetup(contact: Contact) {
        let start = Date()
        let end = Date().addingTimeInterval(60*180) // 1.5 hours
        openGoogleCalendarEventCreationPrompt(contact: contact, start: start, end: end, prefix: "Meet with")
    }

    // TODO: create local event instead?
    private func openGoogleCalendarEventCreationPrompt(contact: Contact, start: Date, end: Date, prefix: String) {
        var urlString = "com.google.calendar://?action=create"

        var title = (prefix + " ").addingPercentEncoding(withAllowedCharacters: .alphanumerics)!
        title += contact.displayName.addingPercentEncoding(withAllowedCharacters: .alphanumerics)!
        urlString += "&title=\(title)"

        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        dateFormatter.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
        let startString = dateFormatter.string(from: start)
        let endString = dateFormatter.string(from: end)
        let dateString = "\(startString)/\(endString)"
        urlString += "&dates=\(dateString)"

        urlString += "&add=" + contact.aliasEmail

        // Other options:
        // urlString += "&description="
        // urlString += "&location="
        // urlString += "&isallday="

        let url = URL(string: urlString)!
        UIApplication.shared.open(url)
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
