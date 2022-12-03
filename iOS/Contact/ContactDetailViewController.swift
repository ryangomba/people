import UIKit
import ReSwift

private enum Section: Int {
    case affinity, locations, photos, count
}

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

        var topAnchor = view.topAnchor;
        if (self.navigationController == nil) {
            tableView.backgroundColor = .clear
            let blurEffect = UIBlurEffect(style: .systemThickMaterial)
            let blurEffectView = UIVisualEffectView(effect: blurEffect)
            blurEffectView.frame = self.view.frame
            view.insertSubview(blurEffectView, at: 0)

            view.addSubview(headerView)
            headerView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
                headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            ])
            topAnchor = headerView.bottomAnchor;
        }

        tableView.automaticallyAdjustsScrollIndicatorInsets = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(ContactProfilePhotoTableViewCell.self, forCellReuseIdentifier: ContactProfilePhotoTableViewCell.reuseIdentifier)
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: topAnchor),
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

    var homeAddresses: [PostalAddress] {
        get {
            return contactLocation.contact.homeAddresses
        }
    }

    private func configureForContactLocation() {
        navigationItem.title = contactLocation.contact.displayName
        headerView.titleLabel.text = contactLocation.contact.displayName
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return Section.count.rawValue
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case Section.affinity.rawValue:
            return nil
        case Section.locations.rawValue:
            return nil
        case Section.photos.rawValue:
            return "Suggested photos"
        default:
            fatalError("Invalid section: \(section)")
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case Section.affinity.rawValue:
            return 1;
        case Section.locations.rawValue:
            return homeAddresses.count + 1 // for add location cell
        case Section.photos.rawValue:
            return 1
        default:
            fatalError("Invalid section: \(section)")
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.section {
        case Section.affinity.rawValue:
            return Sizing.defaultListItemHeight
        case Section.locations.rawValue:
            if indexPath.row < homeAddresses.count {
                let postalAddress = homeAddresses[indexPath.row]
                return ContactLocationTableViewCell.preferredHeightForAddress(postalAddress: postalAddress)
            }
            return Sizing.defaultListItemHeight
        case Section.photos.rawValue:
            return ContactProfilePhotoTableViewCell.preferredHeight
        default:
            fatalError("Invalid section: \(indexPath.section)")
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case Section.affinity.rawValue:
            let affinityInfo = contactLocation.contact.affinity.info
            let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
            var config = cell.defaultContentConfiguration()
            config.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 0, leading: Padding.normal, bottom: 0, trailing: Padding.normal)
            config.textProperties.color = .label
            config.imageProperties.tintColor = .label
            config.text = "\(affinityInfo.title) friend"
            config.image = .init(systemName: affinityInfo.selectedIconName)
            func setAffinity(_ affinity: ContactAffinity) {
                app.contactRepository.updateContactAffinity(contact: contactLocation.contact, affinity: affinity)
            }
            let affinityMenu = UIMenu(children: ContactAffinity.all().map({ affinityInfo in
                let selected = affinityInfo.affinity == contactLocation.contact.affinity
                return UIAction(title: affinityInfo.title, image: UIImage(systemName: selected ? affinityInfo.selectedIconName : affinityInfo.iconName), state: selected ? .on : .off, handler: { (_) in
                    setAffinity(affinityInfo.affinity)
                })
            }))
            let changeButton = UIButton()
            changeButton.menu = affinityMenu
            changeButton.showsMenuAsPrimaryAction = true
            changeButton.setTitle("Change", for: .normal)
            changeButton.titleLabel?.font = .systemFont(ofSize: FontSize.normal)
            changeButton.setTitleColor(.tintColor, for: .normal)
            changeButton.sizeToFit()
            cell.contentConfiguration = config
            cell.accessoryView = changeButton
            return cell
        case Section.locations.rawValue:
            if indexPath.row < homeAddresses.count {
                let postalAddress = homeAddresses[indexPath.row]
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
        case Section.photos.rawValue:
            let cell = tableView.dequeueReusableCell(withIdentifier: ContactProfilePhotoTableViewCell.reuseIdentifier, for: indexPath) as! ContactProfilePhotoTableViewCell
            cell.contact = contactLocation.contact
            return cell
        default:
            fatalError("Invalid section: \(indexPath.section)")
        }
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        switch indexPath.section {
        case Section.locations.rawValue:
            if indexPath.row < homeAddresses.count {
                let postalAddress = homeAddresses[indexPath.row]
                return UISwipeActionsConfiguration(actions: [
                    UIContextualAction(style: .destructive, title: "Delete", handler: { (action, view, onCompletion) in
                        self.onConfirmDeleteAddress(postalAddress, didDelete: onCompletion)
                    }),
                    UIContextualAction(style: .normal, title: "Edit", handler: { (action, view, onCompletion) in
                        app.store.dispatch(ContactLocationSelectedForEdit(location: self.contactLocation))
                        onCompletion(true)
                    }),
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
        case Section.affinity.rawValue:
            // TODO: change affinity
            return
        case Section.locations.rawValue:
            if indexPath.row < homeAddresses.count {
                let postalAddress = homeAddresses[indexPath.row]
                let contactLocation = ContactLocation(contact: contactLocation.contact, postalAddress: postalAddress)
                app.store.dispatch(ContactLocationSelected(location: contactLocation))
            } else {
                let newContactLocation = ContactLocation(contact: contactLocation.contact, postalAddress: nil)
                app.store.dispatch(ContactLocationSelectedForEdit(location: newContactLocation))
            }
        case Section.photos.rawValue:
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
            _ = contactRepository.deletePostalAddress(postalAddress, forContact: self.contactLocation.contact)
            didDelete(true)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
            didDelete(false)
        }))
        self.present(alert, animated: true)
    }

}
