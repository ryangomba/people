import UIKit
import ReSwift

struct ActionViewControllerState: Equatable {
    var contacts: [Contact] = []
    var calendarEvents: [CalendarEvent] = []

    init(newState: AppState) {
        let affinityContacts = newState.contacts.filter({ contact in
            contact.affinity != .undefined && contact.affinity != .keep // TODO: show keep with a toggle
        })
        contacts = affinityContacts.filter({ contact in
            // TOOD: move this logic elsewhere
            let days = contact.affinity.info.days
            let lastEvent = newState.calendarEvents.filter({ calendarEvent in
                // Look ahead the same number of days
                calendarEvent.startDate < Date().addingTimeInterval(60 * 60 * 24 * TimeInterval(days))
            }).first { calendarEvent in
                calendarEvent.attendeeEmails.contains { emailAddress in
                    contact.emailAddresses.contains(emailAddress)
                }
            }
            if let lastEvent = lastEvent {
                return Date().timeIntervalSince(lastEvent.endDate) > 60 * 60 * 24 * TimeInterval(days)
            } else {
                return true
            }
        })
        calendarEvents = newState.calendarEvents.filter({ calendarEvent in
            return (
                calendarEvent.endDate > Date() && // Only show current & future events
                calendarEvent.startDate < Date().addingTimeInterval(60 * 60 * 24 * 14) // Look ahead 2 weeks
            )
        }).filter({ calendarEvent in
            affinityContacts.filter { contact in
                contact.emailAddresses.contains { emailAddress in
                    calendarEvent.attendeeEmails.contains(emailAddress)
                }
            }.count > 0
        }).reversed()
    }
}

private enum Section: Int {
    case due, calendarEvents, count
}

class ActionViewController: UITableViewController, StoreSubscriber {
    private var currentState = ActionViewControllerState(newState: app.store.state)

    init() {
        super.init(style: .grouped)

        navigationItem.title = "Reach out"

        tableView.register(ContactTableViewCell.self, forCellReuseIdentifier: ContactTableViewCell.reuseIdentifier)
        tableView.register(CalendarEventTableViewCell.self, forCellReuseIdentifier: CalendarEventTableViewCell.reuseIdentifier)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .customBackground
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        app.store.subscribe(self) { subscription in
            return subscription.select(ActionViewControllerState.init)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        app.store.unsubscribe(self)
    }

    func newState(state: ActionViewControllerState) {
        let prevState = currentState
        currentState = state

        tableView.reloadData()

        // TODO: move
        if currentState.contacts.count != prevState.contacts.count {
            let nc = UNUserNotificationCenter.current()
            nc.requestAuthorization(options: .badge) { ok, error in
                if ok {
                    nc.setBadgeCount(self.currentState.contacts.count)
                }
            }
        }
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return Section.count.rawValue
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case Section.due.rawValue:
            return currentState.contacts.count
        case Section.calendarEvents.rawValue:
            return currentState.calendarEvents.count
        default:
            fatalError("Invalid section: \(section)")
        }
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case Section.due.rawValue:
            return nil
        case Section.calendarEvents.rawValue:
            return "Coming up"
        default:
            fatalError("Invalid section: \(section)")
        }
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.section {
        case Section.due.rawValue:
            return ContactTableViewCell.preferredHeight
        case Section.calendarEvents.rawValue:
            return CalendarEventTableViewCell.preferredHeight
        default:
            fatalError("Invalid section: \(indexPath.section)")
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case Section.due.rawValue:
            let contact = currentState.contacts[indexPath.row]
            let cell = tableView.dequeueReusableCell(withIdentifier: ContactTableViewCell.reuseIdentifier, for: indexPath) as! ContactTableViewCell
            cell.contactLocation = ContactLocation(contact: contact, postalAddress: nil)
            cell.subtitleType = .lastSeen
            return cell
        case Section.calendarEvents.rawValue:
            let cell = tableView.dequeueReusableCell(withIdentifier: CalendarEventTableViewCell.reuseIdentifier, for: indexPath) as! CalendarEventTableViewCell
            cell.calendarEvent = currentState.calendarEvents[indexPath.row]
            return cell
        default:
            fatalError("Invalid section: \(indexPath.section)")
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.section {
        case Section.due.rawValue:
            let contact = currentState.contacts[indexPath.row]
            let contactLocation = ContactLocation(contact: contact, postalAddress: nil) // TODO: change
            let vc = ContactDetailViewController(contactLocation: contactLocation)
            vc.hidesBottomBarWhenPushed = true;
            self.navigationController?.pushViewController(vc, animated: true)
        case Section.calendarEvents.rawValue:
            return // noop
        default:
            fatalError("Invalid section: \(indexPath.section)")
        }
    }

}
