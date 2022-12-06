import UIKit

class ContactTableViewCell: UITableViewCell {
    static let reuseIdentifier = "contactCell"
    static let preferredHeight: CGFloat = Sizing.defaultListItemHeight

    private let avatarView = ContactAvatarView()
    private let nameLabel = UILabel()
    private let addressLabel = UILabel()
    private let actionButton = UIButton()

    var locationScale: MapZoomScale = .regional {
        didSet {
            updateAddressLabel()
        }
    }

    var contactLocation: ContactLocation? {
        didSet {
            if let contactLocation = contactLocation {
                avatarView.contacts = [contactLocation.contact]
                nameLabel.text = contactLocation.contact.displayName
                let affinity = contactLocation.contact.info.affinity
                func setAffinity(_ affinity: ContactAffinity) {
                    app.contactRepository.updateContactAffinity(contact: contactLocation.contact, affinity: affinity)
                }
                let actionMenu = UIMenu(children: /*[
                    UIAction(title: "Test", image: UIImage(systemName: "circle"), handler: { (_) in
                        //
                    }),
                    UIMenu(title: "\(affinity.info.title) friend", image: UIImage(systemName: affinity.info.selectedIconName), children: */ContactAffinity.all().map({ affinityInfo in
                        let selected = affinityInfo.affinity == affinity
                        return UIAction(title: affinityInfo.title, image: UIImage(systemName: selected ? affinityInfo.selectedIconName : affinityInfo.iconName), state: selected ? .on : .off, handler: { (_) in
                            setAffinity(affinityInfo.affinity)
                        })
                    })/*),*/
                /*]*/)
                actionButton.menu = actionMenu
            } else {
                avatarView.contacts = []
                nameLabel.text = ""
            }
            updateAddressLabel()
        }
    }

    func updateAddressLabel() {
        // TODO: use closest address
        if let postalAddress = contactLocation?.postalAddress {
            switch locationScale {
            case .local:
                addressLabel.text = postalAddress.value.formattedStreet ?? postalAddress.value.formattedCityState
            default:
                addressLabel.text = postalAddress.value.formattedCityState
            }
        } else {
            addressLabel.text = "No location"
        }
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
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: Padding.tight),
            nameLabel.leadingAnchor.constraint(equalTo: avatarView.trailingAnchor, constant: Padding.tight),
            nameLabel.trailingAnchor.constraint(equalTo: actionButton.trailingAnchor, constant: -Padding.normal),
        ])

        addressLabel.textColor = .gray
        addressLabel.font = .systemFont(ofSize: FontSize.small)
        contentView.addSubview(addressLabel)
        addressLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            addressLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: Padding.text),
            addressLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            addressLabel.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
