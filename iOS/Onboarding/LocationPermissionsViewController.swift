import UIKit
import ReSwift

struct LocationPermissionsViewControllerState: Equatable {
    var locationAuthStatus: LocationAuthStatus

    init(newState: AppState) {
        locationAuthStatus = newState.locationAuthStatus
    }
}

class LocationPermissionsViewController: UIViewController, StoreSubscriber {
    public var currentState: LocationPermissionsViewControllerState?
    private var permissionsView = AppPermissionsView()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .customBackground        

        permissionsView.configure(
            text: "Please allow access to your location to automatically center the map",
            buttonTitle: "Allow access to location",
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
            return subscription.select(LocationPermissionsViewControllerState.init)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        app.store.unsubscribe(self)
    }

    func newState(state: LocationPermissionsViewControllerState) {
        currentState = state
    }

    private func onButtonTapped() {
        if currentState?.locationAuthStatus == .notDetermined {
            app.locationAuthManager.requestAuthorization()
        } else {
            UIApplication.openAppSettings()
        }
    }

}
