import UIKit
import MapKit
import ReSwift

enum MapZoomScale: Int {
    case local = 1
    case regional = 2
}

struct ContactSearchResult {
    let contact: Contact
    let score: Int
}

struct ContactListViewControllerState {
    var searchQuery: String
    var clusterTitle: String?
    var contactLocations: [ContactLocation]
    var mapZoomScale: MapZoomScale = .regional

    init(newState: AppState) {
        let regionSpan = newState.mapRegion.span
        switch regionSpan.latitudeDelta {
        case 0..<0.33:
            mapZoomScale = .local
        default:
            mapZoomScale = .regional
        }

        let query = newState.searchQuery
        searchQuery = query

        let focusedCoordinate = focusedCoordinateForMapRegion(newState.mapRegion)
        let clusterSelected = newState.selection?.fromCluster ?? false
        if clusterSelected {
            let coordinate = newState.selection!.coordinate
            contactLocations = []
            var postalAddresses: [PostalAddress] = []
            newState.contacts.forEach({ contact in
                contact.postalAddresses.forEach { postalAddress in
                    if postalAddress.coordinate == coordinate {
                        postalAddresses.append(postalAddress)
                        contactLocations.append(ContactLocation(contact: contact, postalAddress: postalAddress))
                    }
                }
            })
            clusterTitle = postalAddresses.sameLocationSharedDescription
        } else if newState.isSearching {
            let query = query.lowercased()
            contactLocations = newState.contacts.map { contact in
                let searchString = contact.searchString
                var score = 0
                if query.isEmpty {
                    score = 1 // just needs to be non-zero
                } else if let index = searchString.range(of: query)?.lowerBound {
                    if index == searchString.startIndex {
                        score = 100
                    } else {
                        let prevIndex = searchString.index(index, offsetBy: -1)
                        let prevChar = searchString[prevIndex]
                        if prevChar == Character(" ") {
                            score = 10
                        } else {
                            score = 1
                        }
                    }
                }
                return ContactSearchResult(contact: contact, score: score)
            }.filter({ searchResult in
                return searchResult.score > 0
            }).sorted(by: { r1, r2 in
                if r1.score > r2.score {
                    return true
                }
                return r1.contact.displayName < r2.contact.displayName // TODO: sort by best natural match
            }).map({ searchResult in
                return searchResult.contact.nearestLocation(to: focusedCoordinate)
            }).map({ result in
                return result.contactLocation
            })
        } else {
            var adjustedRegion = newState.mapRegion
            if adjustedRegion.span.longitudeDelta == 0 {
                adjustedRegion.span.longitudeDelta = adjustedRegion.span.latitudeDelta * 0.66 // TODO: this is super hacky
            }
            contactLocations = newState.contacts.map({ contact in
                return contact.nearestLocation(to: focusedCoordinate)
            }).filter({ result in
                if let coordinate = result.contactLocation.postalAddress?.coordinate {
                    return adjustedRegion.contains(coordinate)
                } else {
                    return false
                }
            }).sorted(by: { r1, r2 in
                return r1.distance < r2.distance
            }).map({ result in
                return result.contactLocation
            })
        }
    }
}

class ContactListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, MKLocalSearchCompleterDelegate, StoreSubscriber {
    private var currentState = ContactListViewControllerState(newState: app.store.state)
    private let headerView = ContactListHeader()
    private let tableView = UITableView()
    private let completer = MKLocalSearchCompleter()

    override func viewDidLoad() {
        super.viewDidLoad()

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

        tableView.backgroundColor = .clear
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(LocationSearchResultTableViewCell.self, forCellReuseIdentifier: LocationSearchResultTableViewCell.reuseIdentifier)
        tableView.register(ContactTableViewCell.self, forCellReuseIdentifier: ContactTableViewCell.reuseIdentifier)
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.scrollIndicatorInsets = .init(top: 0, left: 0, bottom: Padding.normal, right: 0)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        completer.delegate = self
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

        completer.cancel()
        app.store.unsubscribe(self)

        let notificationCenter = NotificationCenter.default
        notificationCenter.removeObserver(self)
    }

    private var filteredLocationResults: [MKLocalSearchCompletion] {
        get {
            if currentState.searchQuery.isEmpty {
                return []
            }
            return completer.results.locatableResults()
        }
    }

    func newState(state: ContactListViewControllerState) {
        let prevState = currentState
        currentState = state

        if state.searchQuery != prevState.searchQuery {
            completer.queryFragment = state.searchQuery
        }
        if state.contactLocations != prevState.contactLocations || state.mapZoomScale != prevState.mapZoomScale {
            tableView.reloadData()
        }
        if state.clusterTitle != prevState.clusterTitle {
            headerView.clusterTitle = state.clusterTitle
        }
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

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        tableView.reloadSections([0], with: .none)
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        //
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return min(filteredLocationResults.count, 1)
        case 1:
            return currentState.contactLocations.count
        default:
            fatalError("Invalid section: \(section)")
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.section {
        case 0:
            return LocationSearchResultTableViewCell.preferredHeight
        case 1:
            return ContactTableViewCell.preferredHeight
        default:
            fatalError("Invalid section: \(indexPath.section)")
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: LocationSearchResultTableViewCell.reuseIdentifier, for: indexPath) as! LocationSearchResultTableViewCell
            let result = filteredLocationResults[indexPath.row]
            cell.title = result.title
            cell.subtitle = result.subtitle
            return cell
        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: ContactTableViewCell.reuseIdentifier, for: indexPath) as! ContactTableViewCell
            cell.contactLocation = currentState.contactLocations[indexPath.row]
            cell.locationScale = currentState.mapZoomScale
            return cell
        default:
            fatalError("Invalid section: \(indexPath.section)")
        }
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        switch indexPath.section {
        case 0:
            return nil
        case 1:
            let contactLocation = currentState.contactLocations[indexPath.row]
            return UISwipeActionsConfiguration(actions: [
                UIContextualAction(style: .destructive, title: "Delete", handler: { (action, view, onCompletion) in
                    self.onConfirmDeleteContact(contactLocation.contact, didDelete: onCompletion)
                })
            ])
        default:
            fatalError("Invalid section: \(indexPath.section)")
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.section {
        case 0:
            let result = filteredLocationResults[indexPath.row]
            let searchRequest = MKLocalSearch.Request(completion: result)
            let search = MKLocalSearch(request: searchRequest)
            search.start { (response, error) in
                if error != nil {
                    self.presentMessageAlert(title: "Error", message: "Couldn't fetch result")
                    return
                }
                if let mapItem = response?.mapItems.first {
                    let coordinate = mapItem.placemark.coordinate
                    app.store.dispatch(FocusRegionalLocation(coordinate: coordinate))
                } else {
                    self.presentMessageAlert(title: "Error", message: "Unexpected result")
                }
            }
            break
        case 1:
            let contactLocation = currentState.contactLocations[indexPath.row]
            app.store.dispatch(ContactLocationSelected(location: contactLocation))
            tableView.scrollToTop(animated: false)
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
