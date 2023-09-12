import UIKit
import ReSwift

struct OnboardingViewControllerState: Equatable {
    var accessGranted: Bool

    init(newState: AppState) {
        accessGranted = (
            newState.contactsAuthStatus == .authorized &&
            newState.locationAuthStatus == .authorized &&
            newState.notificationsAuthStatus == .authorized
        )
    }
}

class OnboardingViewController: UINavigationController, StoreSubscriber {
    private var currentState = OnboardingViewControllerState(newState: app.store.state)

    private let permissionVC = PermissionsViewController()
    private let contactIngestionVC = ContactIngestionViewController()
    private var didShowPermissions = false

    override func viewDidLoad() {
        super.viewDidLoad()

        permissionVC.navigationItem.hidesBackButton = true
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
        currentState = state

        updateViewControllers()
    }

    private func updateViewControllers() {
        var vcs: [UIViewController] = []
        if !currentState.accessGranted || didShowPermissions {
            didShowPermissions = true
            vcs.append(permissionVC)
        }
        if currentState.accessGranted {
            vcs.append(contactIngestionVC)
        }
        setViewControllers(vcs, animated: true)
    }

}
