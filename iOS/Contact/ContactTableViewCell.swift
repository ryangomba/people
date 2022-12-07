import UIKit

enum ContactTableViewCellSubtitleType: Int {
    case addressLocal = 1
    case addressRegional = 2
    case lastSeen = 3
    case none = 4
}

class ContactTableViewCell: UITableViewCell {
    static let reuseIdentifier = "contactCell"
    static let preferredHeight: CGFloat = Sizing.defaultListItemHeight

    private let avatarView = ContactAvatarView()
    private let nameLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let actionButton = UIButton()
    private var subtitleConstraints: [NSLayoutConstraint] = []

    var subtitleType: ContactTableViewCellSubtitleType = .none {
        didSet {
            updateSubtitleLabel()
        }
    }

    var contactLocation: ContactLocation? {
        didSet {
            if let contactLocation = contactLocation {
                let contact = contactLocation.contact
                avatarView.contacts = [contact]
                nameLabel.text = contact.displayName
                let affinity = contact.affinity
                func setAffinity(_ affinity: ContactAffinity) {
                    app.contactRepository.updateContactAffinity(contact: contact, affinity: affinity)
                }
                var contactActions: [UIAction] = []
                if let phoneNumber = contact.primaryPhoneNumber {
                    let regex = try! NSRegularExpression(pattern: "[^\\d]", options: [.caseInsensitive])
                    let encodedPhoneNumber = regex.stringByReplacingMatches(in: phoneNumber, options: [], range: NSRange(phoneNumber.startIndex..<phoneNumber.endIndex, in: phoneNumber), withTemplate: "")
                    contactActions = [
                        UIAction(title: "Message", image: UIImage(systemName: "message.fill"), handler: { (_) in
                            UIApplication.shared.open(URL(string: "sms://\(encodedPhoneNumber)")!)
                        }),
                        UIAction(title: "Call", image: UIImage(systemName: "phone.fill"), handler: { (_) in
                            UIApplication.shared.open(URL(string: "tel://\(encodedPhoneNumber)")!)
                        }),
                        UIAction(title: "Facetime", image: UIImage(systemName: "waveform"), handler: { (_) in
                            UIApplication.shared.open(URL(string: "facetime-audio://\(encodedPhoneNumber)")!)
                        }),
                    ]
                }
                let actionMenu = UIMenu(children: contactActions + [
                    UIMenu(title: "\(affinity.info.title)", image: UIImage(systemName: affinity.info.selectedIconName), children: ContactAffinity.all().map({ affinityInfo in
                        let selected = affinityInfo.affinity == affinity
                        return UIAction(title: affinityInfo.title, image: UIImage(systemName: selected ? affinityInfo.selectedIconName : affinityInfo.iconName), state: selected ? .on : .off, handler: { (_) in
                            setAffinity(affinityInfo.affinity)
                        })
                    })),
                ])
                actionButton.menu = actionMenu
            } else {
                avatarView.contacts = []
                nameLabel.text = ""
            }
            updateSubtitleLabel()
        }
    }

    func updateSubtitleLabel() {
        if let contactLocation = contactLocation {
            switch subtitleType {
            case .addressLocal:
                if let postalAddress = contactLocation.postalAddress {
                    subtitleLabel.text = postalAddress.value.formattedStreet ?? postalAddress.value.formattedCityState
                } else {
                    subtitleLabel.text = "No location"
                }
            case .addressRegional:
                if let postalAddress = contactLocation.postalAddress {
                    subtitleLabel.text = postalAddress.value.formattedCityState
                } else {
                    subtitleLabel.text = "No location"
                }
            case .lastSeen:
                // TODO: do this upstream, and de-dupe logic
                let days = contactLocation.contact.affinity.info.days
                let lastEvent = app.store.state.calendarEvents.filter({ calendarEvent in
                    // Look ahead the same number of days
                    calendarEvent.startDate < Date().addingTimeInterval(60 * 60 * 24 * TimeInterval(days))
                }).first { calendarEvent in
                    calendarEvent.attendeeEmails.contains { emailAddress in
                        contactLocation.contact.emailAddresses.contains(emailAddress)
                    }
                }
                if let lastEvent = lastEvent {
                    subtitleLabel.text = lastEvent.endDate.daysSinceString()
                } else {
                    subtitleLabel.text = "No event"
                }
            default:
                subtitleLabel.text = ""
            }
        } else {
            subtitleLabel.text = ""
        }
        NSLayoutConstraint.deactivate(subtitleConstraints)
        if (subtitleLabel.text ?? "").isEmpty {
            subtitleConstraints = [nameLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)]
        } else {
            subtitleConstraints = [nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: Padding.tight)]
        }
        NSLayoutConstraint.activate(subtitleConstraints)
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear

        contentView.addSubview(avatarView)
        avatarView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            avatarView.widthAnchor.constraint(equalToConstant: ContactAvatarView.normalSize),
            avatarView.heightAnchor.constraint(equalToConstant: ContactAvatarView.normalSize),
            avatarView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Padding.normal),
            avatarView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
        ])

        actionButton.setImage(.init(systemName: "ellipsis.circle"), for: .normal)
        actionButton.showsMenuAsPrimaryAction = true
        actionButton.sizeToFit()
        contentView.addSubview(actionButton)
        actionButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            actionButton.widthAnchor.constraint(equalToConstant: actionButton.frame.width + 2 * Padding.normal),
            actionButton.heightAnchor.constraint(equalToConstant: contentView.frame.height),
            actionButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            actionButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
        ])

        nameLabel.font = .systemFont(ofSize: FontSize.normal, weight: .semibold)
        contentView.addSubview(nameLabel)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            nameLabel.leadingAnchor.constraint(equalTo: avatarView.trailingAnchor, constant: Padding.tight),
            nameLabel.trailingAnchor.constraint(equalTo: actionButton.trailingAnchor, constant: -Padding.normal),
        ])

        subtitleLabel.textColor = .gray
        subtitleLabel.font = .systemFont(ofSize: FontSize.small)
        contentView.addSubview(subtitleLabel)
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            subtitleLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: Padding.text),
            subtitleLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

// TODO: move
extension Calendar {
    func numberOfDaysBetween(_ from: Date, and to: Date) -> Int {
        let fromDate = startOfDay(for: from) // <1>
        let toDate = startOfDay(for: to) // <2>
        let numberOfDays = dateComponents([.day], from: fromDate, to: toDate) // <3>
        return numberOfDays.day!
    }
}
extension Date {
    func daysSinceString() -> String {
        let days = Calendar.current.numberOfDaysBetween(self, and: Date())
        if days == -1 {
            return "yesterday"
        } else if days == 0 {
            return "today"
        } else if days == 1 {
            return "tomorrow"
        } else if days < 30 {
            return "\(days) days ago"
        } else if days < 0 {
            return "in \(days) days"
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
