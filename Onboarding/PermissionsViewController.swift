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

        let permissionViewHeight: CGFloat = 160 // TODO: better?

        contactsPermissionsView.configure(
            text: "Allow access to your Contacts\nso you can see them on a map",
            buttonTitle: "Allow access to Contacts",
            buttonAction: UIAction() { _ in
                if self.currentState?.contactsAuthStatus == .notDetermined {
                    app.contactRepository.requestAuthorization()
                } else {
                    UIApplication.openAppSettings()
                }
            }
        )
        view.addSubview(contactsPermissionsView)
        contactsPermissionsView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            contactsPermissionsView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: Padding.normal),
            contactsPermissionsView.heightAnchor.constraint(equalToConstant: permissionViewHeight),
            contactsPermissionsView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contactsPermissionsView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])

        locationPermissionsView.configure(
            text: "Allow access to your location\nto automatically center the map",
            buttonTitle: "Allow access to location",
            buttonAction: UIAction() { _ in
                if self.currentState?.locationAuthStatus == .notDetermined {
                    app.locationAuthManager.requestAuthorization()
                } else {
                    UIApplication.openAppSettings()
                }
            }
        )
        view.addSubview(locationPermissionsView)
        locationPermissionsView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            locationPermissionsView.topAnchor.constraint(equalTo: contactsPermissionsView.bottomAnchor),
            locationPermissionsView.heightAnchor.constraint(equalToConstant: permissionViewHeight),
            locationPermissionsView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            locationPermissionsView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])

        updateAuthorizationStatuses()
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

        updateAuthorizationStatuses()
    }

    func updateAuthorizationStatuses() {
        if currentState?.contactsAuthStatus == .authorized {
            contactsPermissionsView.completed = true
        }
        if currentState?.locationAuthStatus == .authorized {
            locationPermissionsView.completed = true
        }
    }

}
