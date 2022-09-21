import UIKit
import ReSwift

struct ContactPhotosViewControllerState {
    var contacts: [Contact]

    init(newState: AppState) {
        contacts = newState.contacts.filter({ contact in
            var hasPostalAddress = false
            contact.postalAddresses.forEach { postalAddress in
                if postalAddress.coordinate != nil {
                    hasPostalAddress = true
                }
            }
            return hasPostalAddress
        })
    }
}

class ContactPhotosViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, StoreSubscriber {
    private var currentState = ContactPhotosViewControllerState(newState: app.store.state)
    private let tableView = UITableView()

    override func viewDidLoad() {
        super.viewDidLoad()

        let blurEffect = UIBlurEffect(style: .systemThickMaterial)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = self.view.frame
        view.insertSubview(blurEffectView, at: 0)

        tableView.backgroundColor = .clear
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(ContactProfilePhotoTableViewCell.self, forCellReuseIdentifier: ContactProfilePhotoTableViewCell.reuseIdentifier)
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.scrollIndicatorInsets = .init(top: 0, left: 0, bottom: Padding.normal, right: 0)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        app.store.subscribe(self) { subscription in
            return subscription.select(ContactPhotosViewControllerState.init)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        app.store.unsubscribe(self)
    }

    func newState(state: ContactPhotosViewControllerState) {
        let prevState = currentState
        currentState = state

        if state.contacts != prevState.contacts {
            tableView.reloadData()
        }
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return currentState.contacts.count
        default:
            fatalError("Invalid section: \(section)")
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.section {
        case 0:
            return ContactProfilePhotoTableViewCell.preferredHeight
        default:
            fatalError("Invalid section: \(indexPath.section)")
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: ContactProfilePhotoTableViewCell.reuseIdentifier, for: indexPath) as! ContactProfilePhotoTableViewCell
            cell.contact = currentState.contacts[indexPath.row]
            return cell
        default:
            fatalError("Invalid section: \(indexPath.section)")
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch indexPath.section {
        case 0:
            break
        default:
            fatalError("Invalid section: \(indexPath.section)")
        }
    }

}
