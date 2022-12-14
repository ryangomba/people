import UIKit

enum PersonTableViewCellSubtitleType: Int {
    case addressLocal = 1
    case addressRegional = 2
    case lastSeen = 3
    case none = 4
}

class PersonTableViewCell: UITableViewCell {
    static let reuseIdentifier = "contactCell"
    static let preferredHeight: CGFloat = Sizing.defaultListItemHeight

    private let avatarView = ContactAvatarView()
    private let nameLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let actionButton = UIButton()
    private var subtitleConstraints: [NSLayoutConstraint] = []

    var subtitleType: PersonTableViewCellSubtitleType = .none {
        didSet {
            updateSubtitleLabel()
        }
    }

    var personLocation: PersonLocation? {
        didSet {
            if let personLocation = personLocation {
                let contact = personLocation.person.contact
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
                let scheduleMenu = UIMenu(title: "Schedule", image: UIImage(systemName: "calendar.badge.plus"), children: [
                    UIAction(title: "We talked", image: UIImage(systemName: "phone.fill"), handler: { (_) in
                        app.calendarRepository.createCalendarEventForRecentCall(contact: contact)
                    }),
                    UIAction(title: "We texted", image: UIImage(systemName: "text.bubble.fill"), handler: { (_) in
                        app.calendarRepository.createCalendarEventForRecentTexting(contact: contact)
                    }),
                    UIAction(title: "Schedule call", image: UIImage(systemName: "phone.fill.badge.plus"), handler: { (_) in
                        app.calendarRepository.createCalendarEventForUpcomingCall(contact: contact)
                    }),
                    UIAction(title: "Schedule meetup", image: UIImage(systemName: "person.2.fill"), handler: { (_) in
                        app.calendarRepository.createCalendarEventForUpcomingMeetup(contact: contact)
                    }),
                ])
                let actionMenu = UIMenu(children: contactActions + [scheduleMenu] + [
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
        if let personLocation = personLocation {
            switch subtitleType {
            case .addressLocal:
                if let postalAddress = personLocation.postalAddress {
                    subtitleLabel.text = postalAddress.value.formattedStreet ?? postalAddress.value.formattedCityState
                } else {
                    subtitleLabel.text = "No location"
                }
            case .addressRegional:
                if let postalAddress = personLocation.postalAddress {
                    subtitleLabel.text = postalAddress.value.formattedCityState
                } else {
                    subtitleLabel.text = "No location"
                }
            case .lastSeen:
                if let latestEvent = personLocation.person.latestEvent {
                    subtitleLabel.text = latestEvent.endDate.formatRelative()
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

//        Other possibilities:
//        arrow.up.forward.app
//        ellipsis.rectangle
//        chevron.up.square
//        arrow.up.right.square
//        ellipsis.circle
        actionButton.setImage(.init(systemName: "arrow.up.right.square"), for: .normal)
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
