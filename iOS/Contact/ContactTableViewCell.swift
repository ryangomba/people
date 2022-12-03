import UIKit

class ContactTableViewCell: UITableViewCell {
    static let reuseIdentifier = "contactCell"
    static let preferredHeight: CGFloat = Sizing.defaultListItemHeight

    private let avatarView = ContactAvatarView()
    private let nameLabel = UILabel()
    private let addressLabel = UILabel()

    var locationScale: MapZoomScale = .regional {
        didSet {
            updateAddressLabel()
        }
    }

    var contactLocation: ContactLocation? {
        didSet {
            if let contactLocation = contactLocation {
                avatarView.contacts = [contactLocation.contact]
            } else {
                avatarView.contacts = []
            }
            nameLabel.text = contactLocation?.contact.displayName ?? ""
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

        nameLabel.font = .systemFont(ofSize: FontSize.normal, weight: .semibold)
        contentView.addSubview(nameLabel)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: Padding.tight),
            nameLabel.leadingAnchor.constraint(equalTo: avatarView.trailingAnchor, constant: Padding.tight),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Padding.normal),
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
