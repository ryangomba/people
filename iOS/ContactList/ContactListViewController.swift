import UIKit
import ReSwift

struct ContactListViewControllerState {
    var contacts: [Contact]

    init(newState: AppState) {
        contacts = newState.contacts.search(query: newState.listSearchQuery)
    }
}

class ContactListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, StoreSubscriber, UISearchResultsUpdating {
    private var currentState = ContactListViewControllerState(newState: app.store.state)
    private let tableView = UITableView()
    private let footerView = SimpleFooterView()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .customBackground

        navigationItem.title = "People"

        let search = UISearchController(searchResultsController: nil)
        search.searchResultsUpdater = self
        search.obscuresBackgroundDuringPresentation = false
        search.searchBar.placeholder = "Search"
        navigationItem.searchController = search
        navigationItem.hidesSearchBarWhenScrolling = false

        tableView.tableFooterView = footerView;

        tableView.backgroundColor = .clear
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(LocationSearchResultTableViewCell.self, forCellReuseIdentifier: LocationSearchResultTableViewCell.reuseIdentifier)
        tableView.register(ContactTableViewCell.self, forCellReuseIdentifier: ContactTableViewCell.reuseIdentifier)
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.scrollIndicatorInsets = .init(top: 0, left: 0, bottom: Padding.normal, right: 0)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        updateFooter()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        app.store.subscribe(self) { subscription in
            return subscription.select(ContactListViewControllerState.init)
        }

        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillHideNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        app.store.unsubscribe(self)

        let notificationCenter = NotificationCenter.default
        notificationCenter.removeObserver(self)
    }

    func newState(state: ContactListViewControllerState) {
        let prevState = currentState
        currentState = state

        if state.contacts != prevState.contacts {
            tableView.scrollToTop(animated: false)
            tableView.reloadData()
            updateFooter();
        }
    }

    func updateFooter() {
        footerView.text = "No results";
        let hasResults = currentState.contacts.count > 0;
        footerView.isHidden = hasResults;
    }

    func updateSearchResults(for searchController: UISearchController) {
        guard let text = searchController.searchBar.text else { return }
        app.store.dispatch(ListSearchQueryChanged(searchQuery: text))
    }

    @objc
    func adjustForKeyboard(notification: Notification) {
        guard let keyboardValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else {
            return
        }

        let keyboardScreenEndFrame = keyboardValue.cgRectValue
        let keyboardViewEndFrame = view.convert(keyboardScreenEndFrame, from: view.window)

        var edgeInsets = UIEdgeInsets.zero
        if notification.name == UIResponder.keyboardWillHideNotification {
            edgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: view.safeAreaInsets.bottom, right: 0)
        } else {
            edgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: keyboardViewEndFrame.height - view.safeAreaInsets.bottom, right: 0)
        }
        tableView.contentInset = edgeInsets
        tableView.scrollIndicatorInsets = edgeInsets
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
            return ContactTableViewCell.preferredHeight
        default:
            fatalError("Invalid section: \(indexPath.section)")
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: ContactTableViewCell.reuseIdentifier, for: indexPath) as! ContactTableViewCell
            let contact = currentState.contacts[indexPath.row];
            let contactLocation = ContactLocation(contact: contact, postalAddress: nil) // TODO: different type of cell?
            cell.contactLocation = contactLocation
            return cell
        default:
            fatalError("Invalid section: \(indexPath.section)")
        }
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        switch indexPath.section {
        case 0:
            let contact = currentState.contacts[indexPath.row]
            return UISwipeActionsConfiguration(actions: [
                UIContextualAction(style: .destructive, title: "Delete", handler: { (action, view, onCompletion) in
                    self.onConfirmDeleteContact(contact, didDelete: onCompletion)
                })
            ])
        default:
            fatalError("Invalid section: \(indexPath.section)")
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.section {
        case 0:
            let contact = currentState.contacts[indexPath.row]
            let contactLocation = ContactLocation(contact: contact, postalAddress: nil) // TODO: change
            let vc = ContactDetailViewController(contactLocation: contactLocation)
            vc.hidesBottomBarWhenPushed = true;
            self.navigationController?.pushViewController(vc, animated: true)
        default:
            fatalError("Invalid section: \(indexPath.section)")
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }

    private func onConfirmDeleteContact(_ contact: Contact, didDelete: @escaping (Bool) -> Void) {
        let alert = UIAlertController(
            title: "Delete contact?",
            message: "Are you sure you want to delete this contact?",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { _ in
            let contactRepository = app.contactRepository
            contactRepository.delete(contact)
            didDelete(true)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
            didDelete(false)
        }))
        self.present(alert, animated: true)
    }

}
