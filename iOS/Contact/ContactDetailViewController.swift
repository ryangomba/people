import UIKit
import ReSwift

class ContactDetailViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    private let headerView = ContactDetailHeader()
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)

    init(contactLocation: ContactLocation) {
        self.contactLocation = contactLocation
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let blurEffect = UIBlurEffect(style: .systemThickMaterial)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = self.view.frame
        view.insertSubview(blurEffectView, at: 0)

        view.addSubview(headerView)
        headerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])

        tableView.backgroundColor = .clear
        tableView.automaticallyAdjustsScrollIndicatorInsets = false
        tableView.dataSource = self
        tableView.delegate = self
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        configureForContactLocation()
    }

    var contactLocation: ContactLocation {
        didSet {
            configureForContactLocation()
            tableView.reloadData()
        }
    }

    var postalAddresses: [PostalAddress] {
        get {
            return contactLocation.contact.postalAddresses
        }
    }

    private func configureForContactLocation() {
        headerView.titleLabel.text = contactLocation.contact.displayName
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return nil
        case 1:
            return "Suggested photos"
        default:
            fatalError("Invalid section: \(section)")
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return postalAddresses.count + 1 // for add location cell
        case 1:
            return 1
        default:
            fatalError("Invalid section: \(section)")
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.section {
        case 0:
            if indexPath.row < postalAddresses.count {
                let postalAddress = postalAddresses[indexPath.row]
                return ContactLocationTableViewCell.preferredHeightForAddress(postalAddress: postalAddress)
            }
            return Sizing.defaultListItemHeight
        case 1:
            return ContactProfilePhotoTableViewCell.preferredHeight
        default:
            fatalError("Invalid section: \(indexPath.section)")
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            if indexPath.row < postalAddresses.count {
                let postalAddress = postalAddresses[indexPath.row]
                let cell = ContactLocationTableViewCell(contact: contactLocation.contact, postalAddress: postalAddress)
                cell.viewController = self
                return cell
            } else {
                let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
                var config = cell.defaultContentConfiguration()
                config.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 0, leading: Padding.normal, bottom: 0, trailing: Padding.normal)
                config.textProperties.color = .tintColor
                config.text = "Add location"
                cell.contentConfiguration = config
                return cell
            }
        case 1:
            return ContactProfilePhotoTableViewCell(contact: contactLocation.contact) // TODO: reuse
        default:
            fatalError("Invalid section: \(indexPath.section)")
        }
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        switch indexPath.section {
        case 0:
            if indexPath.row < postalAddresses.count {
                let postalAddress = postalAddresses[indexPath.row]
                return UISwipeActionsConfiguration(actions: [
                    UIContextualAction(style: .destructive, title: "Delete", handler: { (action, view, onCompletion) in
                        self.onConfirmDeleteAddress(postalAddress, didDelete: onCompletion)
                    })
                ])
            } else {
                return nil
            }
        default:
            return nil
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch indexPath.section {
        case 0:
            if indexPath.row < contactLocation.contact.postalAddresses.count {
                let postalAddress = postalAddresses[indexPath.row]
                let contactLocation = ContactLocation(contact: contactLocation.contact, postalAddress: postalAddress)
                app.store.dispatch(ContactLocationSelected(location: contactLocation))
            } else {
                let newContactLocation = ContactLocation(contact: contactLocation.contact, postalAddress: nil)
                app.store.dispatch(ContactLocationSelectedForEdit(location: newContactLocation))
            }
        case 1:
            let vc = ProfilePhotosViewController(contact: contactLocation.contact)
            present(vc, animated: true)
        default:
            return // noop
        }
    }

    private func onConfirmDeleteAddress(_ postalAddress: PostalAddress, didDelete: @escaping (Bool) -> Void) {
        let alert = UIAlertController(
            title: "Delete address?",
            message: "Are you sure you want to delete this address?",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { _ in
            let contactRepository = app.contactRepository
            contactRepository.deletePostalAddress(postalAddress, forContact: self.contactLocation.contact)
            didDelete(true)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
            didDelete(false)
        }))
        self.present(alert, animated: true)
    }

}
