import UIKit

class ContactLocationTableViewCell: UITableViewCell, UIEditMenuInteractionDelegate {
    static func preferredHeightForAddress(postalAddress: PostalAddress) -> CGFloat {
        let numLines = postalAddress.value.formattedMultiLine.split(separator: "\n").count
        return Padding.normal * 2 + 30 + CGFloat(numLines) * 22 // TODO: this is a hacky estimate
    }

    private let contact: Contact
    private let postalAddress: PostalAddress
    public weak var viewController: UIViewController?
    private let addressTypeLabel = UILabel()
    private let addressValueLabel = UILabel()
    private let editButton = UIButton(type: .system)
    private let longPressRecognizer = UILongPressGestureRecognizer()

    init(contact: Contact, postalAddress: PostalAddress) {
        self.contact = contact
        self.postalAddress = postalAddress
        super.init(style: .default, reuseIdentifier: nil)

        let editMenu = UIMenu(children: [
            UIAction(title: "Copy", image: UIImage(systemName: "doc.on.doc"), handler: { (_) in
                self.onCopyAddress()
            }),
            UIAction(title: "Edit location", image: UIImage(systemName: "location.viewfinder"), handler: { (_) in
                self.onEditAddress()
            }),
            UIAction(title: "Show in Maps", image: UIImage(systemName: "map"), handler: { (_) in
                self.onOpenAddress()
            }),
            UIAction(title: "Delete location", image: UIImage(systemName: "trash"), attributes: .destructive, handler: { (_) in
                self.onConfirmDeleteAddress()
            })
        ])
        editButton.menu = editMenu
        editButton.showsMenuAsPrimaryAction = true
        editButton.setImage(.init(systemName: "chevron.up.circle"), for: .normal)
        editButton.sizeToFit()
        contentView.addSubview(editButton)
        editButton.translatesAutoresizingMaskIntoConstraints = false
        editButton.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        NSLayoutConstraint.activate([
            editButton.topAnchor.constraint(equalTo: contentView.topAnchor),
            editButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            editButton.widthAnchor.constraint(equalToConstant: editButton.frame.width + Padding.normal * 2),
            editButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
        ])

        addressTypeLabel.text = postalAddress.formattedLabel ?? PostalAddress.homeLabel
        addressTypeLabel.textColor = .gray
        addressTypeLabel.font = .systemFont(ofSize: FontSize.small)
        contentView.addSubview(addressTypeLabel)
        addressTypeLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            addressTypeLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: Padding.normal),
            addressTypeLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Padding.normal),
            addressTypeLabel.trailingAnchor.constraint(equalTo: editButton.leadingAnchor),
        ])

        let attrString = NSMutableAttributedString(string: postalAddress.value.formattedMultiLine)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = Padding.text
        attrString.addAttribute(.paragraphStyle, value:paragraphStyle, range:NSMakeRange(0, attrString.length))
        addressValueLabel.attributedText = attrString
        addressValueLabel.numberOfLines = .max
        contentView.addSubview(addressValueLabel)
        addressValueLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            addressValueLabel.topAnchor.constraint(equalTo: addressTypeLabel.bottomAnchor, constant: Padding.superTight),
            addressValueLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Padding.normal),
            addressValueLabel.trailingAnchor.constraint(equalTo: editButton.leadingAnchor, constant: -Padding.normal),
        ])

        longPressRecognizer.addTarget(self, action: #selector(onLongPress))
        addGestureRecognizer(longPressRecognizer)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var contactLocation: ContactLocation {
        return ContactLocation(contact: contact, postalAddress: postalAddress)
    }

    @objc
    func onLongPress(_ gestureRecognizer: UIGestureRecognizer) {
        switch gestureRecognizer.state {
        case .began:
            let editMenuInteraction = UIEditMenuInteraction(delegate: self)
            contentView.addInteraction(editMenuInteraction)
            let location = CGPoint(x: contentView.center.x, y: 0)
            let configuration = UIEditMenuConfiguration(identifier: nil, sourcePoint: location)
            editMenuInteraction.presentEditMenu(with: configuration)
        default:
            break
        }
    }

    func editMenuInteraction(_ interaction: UIEditMenuInteraction, menuFor configuration: UIEditMenuConfiguration, suggestedActions: [UIMenuElement]) -> UIMenu? {
        return UIMenu(title: "", children: [
            UIAction(title: "Copy") { action in
                self.onCopyAddress()
            },
        ])
    }

    private func onCopyAddress() {
        UIPasteboard.general.string = postalAddress.value.formattedSingleLine
    }

    private func onOpenAddress() {
        let query = postalAddress.value.queryString
        let stringURL = "comgooglemaps://?q=\(query)"
        if let url = URL(string: stringURL) {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            } else {
                let stringURL = "maps://?q=\(query)"
                if let url = URL(string: stringURL) {
                    UIApplication.shared.open(url)
                }
            }
        }
    }

    private func onEditAddress() {
        app.store.dispatch(MapContactLocationSelectedForEdit(location: contactLocation))
    }

    private func onConfirmDeleteAddress() {
        let alert = UIAlertController(
            title: "Delete address?",
            message: "Are you sure you want to delete this address?",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { _ in
            self.deleteAddress()
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        self.viewController?.present(alert, animated: true)
    }

    private func deleteAddress() {
        let contactRepository = app.contactRepository
        _ = contactRepository.deletePostalAddress(postalAddress, forContact: contact)
    }

}
