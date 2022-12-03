import UIKit
import ReSwift

struct ActionViewControllerState: Equatable {
    var persons: [Person] = []
    var calendarEvents: [CalendarEvent] = []

    init(newState: AppState) {
        let affinityPersons = newState.persons.filter({ person in
            person.affinity != .undefined && person.affinity != .keep // TODO: show keep with a toggle
        })
        persons = affinityPersons.filter({ person in person.overdue > 0 }).sorted(by: { lhs, rhs in
            let a1 = lhs.affinity;
            let a2 = rhs.affinity;
            if (a1 != a2) {
                return a1.rawValue < a2.rawValue
            }
            let o1 = lhs.overdue
            let o2 = rhs.overdue
            if (o1 != o2) {
                return o1 > o2
            }
            return lhs.contact < rhs.contact
        })
        calendarEvents = newState.calendarEvents.filter({ calendarEvent in
            return (
                calendarEvent.endDate > Date() && // Only show current & future events
                calendarEvent.startDate < Date().addingTimeInterval(60 * 60 * 24 * 14) // Look ahead 2 weeks
            )
        }).filter({ calendarEvent in
            affinityPersons.filter { person in
                person.contact.emailAddresses.contains { emailAddress in
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

        tableView.register(PersonTableViewCell.self, forCellReuseIdentifier: PersonTableViewCell.reuseIdentifier)
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
        if currentState.persons.count != prevState.persons.count {
            let nc = UNUserNotificationCenter.current()
            nc.requestAuthorization(options: .badge) { ok, error in
                if ok {
                    nc.setBadgeCount(self.currentState.persons.count)
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
            return currentState.persons.count
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
            return PersonTableViewCell.preferredHeight
        case Section.calendarEvents.rawValue:
            return CalendarEventTableViewCell.preferredHeight
        default:
            fatalError("Invalid section: \(indexPath.section)")
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case Section.due.rawValue:
            let person = currentState.persons[indexPath.row]
            let cell = tableView.dequeueReusableCell(withIdentifier: PersonTableViewCell.reuseIdentifier, for: indexPath) as! PersonTableViewCell
            cell.personLocation = PersonLocation(person: person, postalAddress: nil)
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
        tableView.deselectRow(at: indexPath, animated: true)
        switch indexPath.section {
        case Section.due.rawValue:
            let person = currentState.persons[indexPath.row]
            let personLocation = PersonLocation(person: person, postalAddress: nil) // TODO: change
            let vc = ContactDetailViewController(personLocation: personLocation)
            vc.hidesBottomBarWhenPushed = true;
            self.navigationController?.pushViewController(vc, animated: true)
        case Section.calendarEvents.rawValue:
            let calendarEvent = currentState.calendarEvents[indexPath.row]
            app.calendarRepository.openCalendarEvent(calendarEvent)
        default:
            fatalError("Invalid section: \(indexPath.section)")
        }
    }

}
