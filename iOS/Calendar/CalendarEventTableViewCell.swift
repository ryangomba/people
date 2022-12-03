import UIKit

class CalendarEventTableViewCell: UITableViewCell {
    static let reuseIdentifier = "calendarEventCell"
    static let preferredHeight: CGFloat = Sizing.defaultListItemHeight

    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let avatarView = PersonAvatarView()

    var calendarEvent: CalendarEvent? {
        didSet {
            if let calendarEvent = calendarEvent {
                titleLabel.text = calendarEvent.title
                subtitleLabel.text = calendarEvent.endDate.formatRelative().capitalizedSentence
                avatarView.persons = app.store.state.persons.filter({ person in
                    person.contact.emailAddresses.contains { emailAddress in
                        calendarEvent.attendeeEmails.contains(emailAddress)
                    }
                })
            } else {
                titleLabel.text = ""
                subtitleLabel.text = ""
                avatarView.persons = []
            }
        }
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.addSubview(avatarView)
        avatarView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            avatarView.widthAnchor.constraint(equalToConstant: PersonAvatarView.normalSize),
            avatarView.heightAnchor.constraint(equalToConstant: PersonAvatarView.normalSize),
            avatarView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Padding.normal),
            avatarView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
        ])

        titleLabel.font = .systemFont(ofSize: FontSize.normal, weight: .semibold)
        contentView.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: Padding.tight),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Padding.normal),
            titleLabel.trailingAnchor.constraint(equalTo: avatarView.leadingAnchor, constant: -Padding.tight),
        ])

        subtitleLabel.textColor = .gray
        subtitleLabel.font = .systemFont(ofSize: FontSize.small)
        contentView.addSubview(subtitleLabel)
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: Padding.text),
            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
