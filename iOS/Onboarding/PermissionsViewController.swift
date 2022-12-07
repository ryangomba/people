import UIKit
import ReSwift

struct PermissionsViewControllerState: Equatable {
    var contactsAuthStatus: ContactsAuthStatus
    var locationAuthStatus: LocationAuthStatus

    init(newState: AppState) {
        contactsAuthStatus = newState.contactsAuthStatus
        locationAuthStatus = newState.locationAuthStatus
    }
}

class PermissionsViewController: UIViewController, StoreSubscriber {
    public var currentState: PermissionsViewControllerState?
    private var contactsPermissionsView = AppPermissionsView()
    private var locationPermissionsView = AppPermissionsView()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .customBackground

        contactsPermissionsView.configure(
            text: "Please allow access to your Contacts so you can see them on a map",
            buttonTitle: "Allow access to Contacts",
            buttonAction: UIAction() { _ in self.onContactsButtonTapped() }
        )
        view.addSubview(contactsPermissionsView)
        contactsPermissionsView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            contactsPermissionsView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            contactsPermissionsView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            contactsPermissionsView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contactsPermissionsView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])

        locationPermissionsView.configure(
            text: "Please allow access to your location to automatically center the map",
            buttonTitle: "Allow access to location",
            buttonAction: UIAction() { _ in self.onLocationButtonTapped() }
        )
        view.addSubview(locationPermissionsView)
        locationPermissionsView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            locationPermissionsView.topAnchor.constraint(equalTo: contactsPermissionsView.bottomAnchor),
            locationPermissionsView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            locationPermissionsView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            locationPermissionsView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        app.store.subscribe(self) { subscription in
            return subscription.select(PermissionsViewControllerState.init)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        app.store.unsubscribe(self)
    }

    func newState(state: PermissionsViewControllerState) {
        currentState = state
    }

    private func onContactsButtonTapped() {
        if currentState?.contactsAuthStatus == .notDetermined {
            app.contactRepository.requestAuthorization()
        } else {
            UIApplication.openAppSettings()
        }
    }

    private func onLocationButtonTapped() {
        if currentState?.locationAuthStatus == .notDetermined {
            app.locationAuthManager.requestAuthorization()
        } else {
            UIApplication.openAppSettings()
        }
    }

}
