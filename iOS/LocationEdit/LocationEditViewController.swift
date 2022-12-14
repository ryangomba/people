import UIKit
import MapKit

class LocationEditViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, MKLocalSearchCompleterDelegate {
    private let personLocation: PersonLocation
    private let headerView = LocationEditHeader()
    private let tableView = UITableView()
    private let footerView = SimpleFooterView()
    private let completer = MKLocalSearchCompleter()
    private var query = "" {
        didSet {
            headerView.searchQuery = query
            if query.isEmpty {
                tableView.reloadData()
            } else {
                completer.queryFragment = query
            }
            updateFooterVisibility();
        }
    }

    init(personLocation: PersonLocation) {
        self.personLocation = personLocation
        super.init(nibName: nil, bundle: nil)

        completer.delegate = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .customBackground

        let textChangedAction = UIAction() { _ in
            self.query = self.headerView.searchQuery
        }
        headerView.searchBox.textField.addAction(textChangedAction, for: .editingChanged)
        view.addSubview(headerView)
        headerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])

        tableView.tableFooterView = footerView

        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(LocationSearchResultTableViewCell.self, forCellReuseIdentifier: LocationSearchResultTableViewCell.reuseIdentifier)
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        updateFooterVisibility();
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillHideNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        headerView.searchBox.focus()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        completer.cancel()
    }

    private var filteredResults: [MKLocalSearchCompletion] {
        get {
            if query.isEmpty {
                return []
            }
            return completer.results.addressableResults()
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
        tableView.reloadData()
        updateFooterVisibility();
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        // TODO: show error in UI
        updateFooterVisibility();
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredResults.count
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return LocationSearchResultTableViewCell.preferredHeight
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: LocationSearchResultTableViewCell.reuseIdentifier, for: indexPath) as! LocationSearchResultTableViewCell
        let result = filteredResults[indexPath.row]
        cell.title = result.title
        cell.subtitle = result.subtitle
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let result = filteredResults[indexPath.row]
        let searchRequest = MKLocalSearch.Request(completion: result)
        let search = MKLocalSearch(request: searchRequest)
        search.start { (response, error) in
            if error != nil {
                self.presentMessageAlert(title: "Error", message: "Couldn't fetch result")
                return
            }
            if let mapItem = response?.mapItems.first {
                if let postalAddress = mapItem.placemark.postalAddress {
                    let coordinate = mapItem.placemark.coordinate
                    let address = PostalAddress(
                        label: PostalAddress.homeLabel,
                        value: PostalAddressValue(
                            street: postalAddress.street,
                            subLocality: postalAddress.subLocality,
                            city: postalAddress.city,
                            state: postalAddress.state,
                            postalCode: postalAddress.postalCode,
                            country: postalAddress.country
                        ),
                        coordinate: coordinate
                    )
                    self.updateAddress(postalAddress: address)
                    return
                }
            }
            self.presentMessageAlert(title: "Error", message: "Unexpected result")
        }
    }

    private func updateAddress(postalAddress rawPostalAddress: PostalAddress) {
        // If we don't have a street address, save subLocality
        // as the street address; this plays better with services
        // like Google Contacts that don't support subLocality.
        // TODO: move this logic out of the view controller.
        var postalAddress = rawPostalAddress;
        if (postalAddress.value.street.isEmpty && !postalAddress.value.subLocality.isEmpty) {
            postalAddress.value.street = postalAddress.value.subLocality;
            postalAddress.value.subLocality = "";
        }
        var newContact: Contact
        if let oldPostalAddress = personLocation.postalAddress {
            newContact = app.contactRepository.updatePostalAddress(contact: personLocation.person.contact, old: oldPostalAddress, new: postalAddress)
        } else {
            newContact = app.contactRepository.addPostalAddress(contact: personLocation.person.contact, postalAddress: postalAddress)
        }
        let newPerson = Person(contact: newContact, calendarEvents: personLocation.person.calendarEvents, latestEvent: personLocation.person.latestEvent)
        let newPersonLocation = PersonLocation(
            person: newPerson,
            postalAddress: postalAddress
        )
        app.store.dispatch(PersonLocationEdited(location: newPersonLocation))
    }

    func updateFooterVisibility() {
        if (query.isEmpty) {
            footerView.text = "Search for a specific address,\na neighborhood, or a city."
            footerView.isHidden = false;
        } else if (filteredResults.count == 0 && !completer.isSearching) {
            footerView.text = "No results"
            footerView.isHidden = false;
        } else {
            footerView.isHidden = true;
        }
    }

}
