import UIKit
import ReSwift

private enum Section: Int {
#if AFFINITES_ENABLED
    case affinity
#endif
    case locations
#if PHOTOS_ENABLED
    case photos
#endif
    case count
}

class ContactDetailViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    private let headerView = ContactDetailHeader()
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)

    init(personLocation: PersonLocation) {
        self.personLocation = personLocation
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        var topAnchor = view.topAnchor;
        if (self.navigationController == nil) {
            #if !targetEnvironment(macCatalyst)
            tableView.backgroundColor = .clear
            let blurEffect = UIBlurEffect(style: .systemThickMaterial)
            let blurEffectView = UIVisualEffectView(effect: blurEffect)
            blurEffectView.frame = self.view.frame
            view.insertSubview(blurEffectView, at: 0)
            #endif

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

        configureForPersonLocation()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if (navigationController != nil) {
            let headerView = UIView(frame: .init(x: 0, y: 0, width: 0, height: Padding.large))
            tableView.tableHeaderView = headerView
        }
    }

    var personLocation: PersonLocation {
        didSet {
            configureForPersonLocation()
            tableView.reloadData()
        }
    }

    // Convenience
    var person: Person {
        get {
            return personLocation.person
        }
    }
    var contact: Contact {
        get {
            return personLocation.person.contact
        }
    }
    var homeAddresses: [PostalAddress] {
        get {
            return personLocation.person.contact.homeAddresses
        }
    }

    private func configureForPersonLocation() {
        let title = contact.displayName
        navigationItem.title = title
        headerView.titleLabel.text = title
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return Section.count.rawValue
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
#if AFFINITES_ENABLED
        case Section.affinity.rawValue:
            return nil
#endif
        case Section.locations.rawValue:
            return nil
#if PHOTOS_ENABLED
        case Section.photos.rawValue:
            return "Suggested photos"
#endif
        default:
            fatalError("Invalid section: \(section)")
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
#if AFFINITES_ENABLED
        case Section.affinity.rawValue:
            return 1;
#endif
        case Section.locations.rawValue:
            return homeAddresses.count + 1 // for add location cell
#if PHOTOS_ENABLED
        case Section.photos.rawValue:
            return 1
#endif
        default:
            fatalError("Invalid section: \(section)")
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.section {
#if AFFINITES_ENABLED
        case Section.affinity.rawValue:
            return Sizing.defaultListItemHeight
#endif
        case Section.locations.rawValue:
            if indexPath.row < homeAddresses.count {
                let postalAddress = homeAddresses[indexPath.row]
                return PersonLocationTableViewCell.preferredHeightForAddress(postalAddress: postalAddress)
            }
            return Sizing.defaultListItemHeight
#if PHOTOS_ENABLED
        case Section.photos.rawValue:
            return ContactProfilePhotoTableViewCell.preferredHeight
#endif
        default:
            fatalError("Invalid section: \(indexPath.section)")
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
#if AFFINITES_ENABLED
        case Section.affinity.rawValue:
            let affinityInfo = person.affinity.info
            let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
            var config = cell.defaultContentConfiguration()
            config.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 0, leading: Padding.normal, bottom: 0, trailing: Padding.normal)
            config.textProperties.color = .label
            config.imageProperties.tintColor = .label
            config.text = "\(affinityInfo.title) friend"
            config.image = .init(systemName: affinityInfo.selectedIconName)
            func setAffinity(_ affinity: Affinity) {
                app.store.dispatch(PersonAffinityChanged(person: person, affinity: affinity))
            }
            let affinityMenu = UIMenu(children: Affinity.all().map({ affinityInfo in
                let selected = affinityInfo.affinity == person.affinity
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
#endif
        case Section.locations.rawValue:
            if indexPath.row < homeAddresses.count {
                let postalAddress = homeAddresses[indexPath.row]
                let cell = PersonLocationTableViewCell(person: person, postalAddress: postalAddress)
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
#if PHOTOS_ENABLED
        case Section.photos.rawValue:
            let cell = tableView.dequeueReusableCell(withIdentifier: ContactProfilePhotoTableViewCell.reuseIdentifier, for: indexPath) as! ContactProfilePhotoTableViewCell
            cell.contact = contact
            return cell
#endif
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
                        app.store.dispatch(MapPersonLocationSelectedForEdit(location: self.personLocation))
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
#if AFFINITES_ENABLED
        case Section.affinity.rawValue:
            // TODO: change affinity
            return
#endif
        case Section.locations.rawValue:
            if indexPath.row < homeAddresses.count {
                let postalAddress = homeAddresses[indexPath.row]
                let personLocation = PersonLocation(person: person, postalAddress: postalAddress)
                app.store.dispatch(MapPersonLocationSelected(location: personLocation))
            } else {
                let newPersonLocation = PersonLocation(person: person, postalAddress: nil)
                app.store.dispatch(MapPersonLocationSelectedForEdit(location: newPersonLocation))
            }
#if PHOTOS_ENABLED
        case Section.photos.rawValue:
            let vc = ProfilePhotosViewController(contact: contact)
            present(vc, animated: true)
#endif
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
            _ = contactRepository.deletePostalAddress(postalAddress, forContact: self.contact)
            didDelete(true)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
            didDelete(false)
        }))
        self.present(alert, animated: true)
    }

}
