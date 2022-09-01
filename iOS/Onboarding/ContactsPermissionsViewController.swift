import UIKit
import ReSwift

struct ContactsPermissionsViewControllerState: Equatable {
    var contactsAuthStatus: ContactsAuthStatus

    init(newState: AppState) {
        contactsAuthStatus = newState.contactsAuthStatus
    }
}

class ContactsPermissionsViewController: UIViewController, StoreSubscriber {
    public var currentState: ContactsPermissionsViewControllerState?
    private var permissionsView = AppPermissionsView()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .customBackground

        permissionsView.configure(
            text: "Please allow access to your Contacts so you can see them on a map",
            buttonTitle: "Allow access to Contacts",
            buttonAction: UIAction() { _ in self.onButtonTapped() }
        )
        view.addSubview(permissionsView)
        permissionsView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            permissionsView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            permissionsView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            permissionsView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            permissionsView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        app.store.subscribe(self) { subscription in
            return subscription.select(ContactsPermissionsViewControllerState.init)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        app.store.unsubscribe(self)
    }

    func newState(state: ContactsPermissionsViewControllerState) {
        currentState = state
    }

    private func onButtonTapped() {
        if currentState?.contactsAuthStatus == .notDetermined {
            app.contactRepository.requestAuthorization()
        } else {
            UIApplication.openAppSettings()
        }
    }

}
