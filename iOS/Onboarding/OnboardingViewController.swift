import UIKit
import ReSwift

struct OnboardingViewControllerState: Equatable {
    var contactsAccessGranted: Bool
    var locationAccessGranted: Bool

    init(newState: AppState) {
        contactsAccessGranted = newState.contactsAuthStatus == .authorized
        locationAccessGranted = newState.locationAuthStatus == .authorized
    }
}

class OnboardingViewController: UINavigationController, StoreSubscriber {
    private var currentState = OnboardingViewControllerState(newState: app.store.state)

    private let contactsPermissionVC = ContactsPermissionsViewController()
    private let locationPermissionVC = LocationPermissionsViewController()
    private let contactIngestionVC = ContactIngestionViewController()

    override func viewDidLoad() {
        super.viewDidLoad()

        locationPermissionVC.navigationItem.hidesBackButton = true
        contactIngestionVC.navigationItem.hidesBackButton = true

        updateViewControllers()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        app.store.subscribe(self) { subscription in
            return subscription.select(OnboardingViewControllerState.init)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        app.store.unsubscribe(self)
    }

    func newState(state: OnboardingViewControllerState) {
        let prevState = currentState
        currentState = state

        updateViewControllers()
    }

    private func updateViewControllers() {
        var vcs: [UIViewController] = [
            contactsPermissionVC,
        ]
        if currentState.contactsAccessGranted {
            vcs.append(locationPermissionVC)
            if currentState.locationAccessGranted {
                vcs.append(contactIngestionVC)
            }
        }
        setViewControllers(vcs, animated: true)
    }

}
