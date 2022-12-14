import UIKit
import MapKit
import ReSwift

private enum Section: Int {
    case searchResults, personLocations, count
}

enum MapZoomScale: Int {
    case local = 1
    case regional = 2
}

struct MapContactListViewControllerState {
    var searchQuery: String?
    var clusterTitle: String?
    var personLocations: [PersonLocation]
    var mapZoomScale: MapZoomScale = .regional

    init(newState: AppState) {
        let regionSpan = newState.mapRegion.span
        switch regionSpan.latitudeDelta {
        case 0..<0.33:
            mapZoomScale = .local
        default:
            mapZoomScale = .regional
        }

        let query = newState.mapSearchQuery
        if (newState.mapIsSearching) {
            searchQuery = query
        }

        let focusedCoordinate = focusedCoordinateForMapRegion(newState.mapRegion)
        let clusterSelected = newState.mapSelection?.fromCluster ?? false
        if clusterSelected {
            let coordinate = newState.mapSelection!.coordinate
            personLocations = []
            var postalAddresses: [PostalAddress] = []
            newState.persons.forEach({ person in
                // Be sure to only select the first matching address in the case of duplicates
                person.contact.homeAddresses.forEach { postalAddress in
                    if postalAddress.coordinate == coordinate {
                        postalAddresses.append(postalAddress)
                        personLocations.append(PersonLocation(person: person, postalAddress: postalAddress))
                    }
                }
            })
            clusterTitle = postalAddresses.sameLocationSharedDescription
        } else if newState.mapIsSearching {
            let query = query.lowercased()
            personLocations = newState.persons.search(query: query).map({ person in
                return person.nearestHomeLocation(to: focusedCoordinate)
            }).map({ result in
                return result.personLocation
            })
        } else {
            var adjustedRegion = newState.mapRegion
            if adjustedRegion.span.longitudeDelta == 0 {
                adjustedRegion.span.longitudeDelta = adjustedRegion.span.latitudeDelta * 0.66 // TODO: this is super hacky
            }
            personLocations = newState.persons.filter({ person in
                newState.mapSelectedAffinities.contains(person.contact.affinity)
            }).map({ person in
                return person.nearestHomeLocation(to: focusedCoordinate)
            }).filter({ result in
                if let coordinate = result.personLocation.postalAddress?.coordinate {
                    return adjustedRegion.contains(coordinate)
                } else {
                    return false
                }
            }).sorted(by: { r1, r2 in
                // Prioritize affinity over distance from center
                let a1 = r1.personLocation.person.contact.affinity.rawValue
                let a2 = r2.personLocation.person.contact.affinity.rawValue
                if (a1 != a2) {
                    return a1 < a2
                }
                return r1.distance < r2.distance
            }).map({ result in
                return result.personLocation
            })
        }
    }
}

class MapContactListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, MKLocalSearchCompleterDelegate, StoreSubscriber {
    private var currentState = MapContactListViewControllerState(newState: app.store.state)
    private let headerView = MapContactListHeader()
    private let tableView = UITableView()
    private let completer = MKLocalSearchCompleter()
    private let footerView = SimpleFooterView()

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

        tableView.tableFooterView = footerView;

        tableView.backgroundColor = .clear
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(LocationSearchResultTableViewCell.self, forCellReuseIdentifier: LocationSearchResultTableViewCell.reuseIdentifier)
        tableView.register(PersonTableViewCell.self, forCellReuseIdentifier: PersonTableViewCell.reuseIdentifier)
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

        updateFooter()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        app.store.subscribe(self) { subscription in
            return subscription.select(MapContactListViewControllerState.init)
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
            if currentState.searchQuery == nil || currentState.searchQuery!.isEmpty {
                return []
            }
            return completer.results.locatableResults()
        }
    }

    func newState(state: MapContactListViewControllerState) {
        let prevState = currentState
        currentState = state

        if state.searchQuery != prevState.searchQuery {
            if let searchQuery = state.searchQuery {
                completer.queryFragment = searchQuery;
            } else {
                completer.queryFragment = ""
            }
        }
        if state.personLocations != prevState.personLocations || state.mapZoomScale != prevState.mapZoomScale {
            tableView.reloadData()
        }
        if state.clusterTitle != prevState.clusterTitle {
            headerView.clusterTitle = state.clusterTitle
        }

        updateFooter();
    }

    func updateFooter() {
        if (currentState.searchQuery != nil) {
            footerView.text = "No results";
        } else {
            footerView.text = "Nobody nearby";
        }
        let hasResults = currentState.personLocations.count + filteredLocationResults.count > 0;
        let isSearching = !completer.queryFragment.isEmpty && completer.isSearching;
        footerView.isHidden = hasResults || isSearching;
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
        updateFooter();
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        updateFooter();
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return Section.count.rawValue
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case Section.searchResults.rawValue:
            return min(filteredLocationResults.count, 1)
        case Section.personLocations.rawValue:
            return currentState.personLocations.count
        default:
            fatalError("Invalid section: \(section)")
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.section {
        case Section.searchResults.rawValue:
            return LocationSearchResultTableViewCell.preferredHeight
        case Section.personLocations.rawValue:
            return PersonTableViewCell.preferredHeight
        default:
            fatalError("Invalid section: \(indexPath.section)")
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case Section.searchResults.rawValue:
            let cell = tableView.dequeueReusableCell(withIdentifier: LocationSearchResultTableViewCell.reuseIdentifier, for: indexPath) as! LocationSearchResultTableViewCell
            let result = filteredLocationResults[indexPath.row]
            cell.title = result.title
            cell.subtitle = result.subtitle
            return cell
        case Section.personLocations.rawValue:
            let cell = tableView.dequeueReusableCell(withIdentifier: PersonTableViewCell.reuseIdentifier, for: indexPath) as! PersonTableViewCell
            cell.personLocation = currentState.personLocations[indexPath.row]
            switch currentState.mapZoomScale {
            case .local:
                cell.subtitleType = .addressLocal
            default:
                cell.subtitleType = .addressRegional
            }
            return cell
        default:
            fatalError("Invalid section: \(indexPath.section)")
        }
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        switch indexPath.section {
        case Section.searchResults.rawValue:
            return nil
        case Section.personLocations.rawValue:
            let personLocation = currentState.personLocations[indexPath.row]
            return UISwipeActionsConfiguration(actions: [
                UIContextualAction(style: .destructive, title: "Delete", handler: { (action, view, onCompletion) in
                    self.onConfirmDeleteContact(personLocation.person.contact, didDelete: onCompletion)
                })
            ])
        default:
            fatalError("Invalid section: \(indexPath.section)")
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.section {
        case Section.searchResults.rawValue:
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
        case Section.personLocations.rawValue:
            let personLocation = currentState.personLocations[indexPath.row]
            app.store.dispatch(MapPersonLocationSelected(location: personLocation))
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
