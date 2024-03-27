import UIKit
import CoreLocation
import ReSwift

struct BigScreenRootViewControllerState: Equatable {
    var accessGranted: Bool
    var geocoderQueueCount: Int
    var mapSelectedContact: MapContactSelection?
    var mapSelectedPersonLocationForEdit: PersonLocation?

    init(newState: AppState) {
        accessGranted = (
            newState.contactsAuthStatus == .authorized &&
            newState.locationAuthStatus == .authorized
        )
        geocoderQueueCount = newState.geocoderQueueCount
        mapSelectedContact = newState.mapSelection
        mapSelectedPersonLocationForEdit = newState.mapPersonLocationForEdit
    }
}

class BigScreenRootViewController: UISplitViewController, StoreSubscriber, UISheetPresentationControllerDelegate, UISplitViewControllerDelegate {
    private var currentState: BigScreenRootViewControllerState?
    private let mapVC = MapViewController()
    private let contactListVC = MapContactListViewController()
    private var contactDetailVC: ContactDetailViewController?
    private var personLocationEditVC: LocationEditViewController?
    private var onboardingVC: OnboardingViewController?

    init() {
        super.init(style: .doubleColumn)

        primaryBackgroundStyle = .sidebar
        preferredDisplayMode = .oneBesideSecondary
        displayModeButtonVisibility = .never

        setViewController(contactListVC, for: .primary)
        setViewController(mapVC, for: .secondary)

        self.delegate = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        presentOrDismissOnboarding()

        app.store.subscribe(self) { subscription in
            return subscription.select(BigScreenRootViewControllerState.init)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        app.store.unsubscribe(self)
    }

    func newState(state: BigScreenRootViewControllerState) {
        let prevState = currentState
        currentState = state

        if state.mapSelectedContact != prevState?.mapSelectedContact {
            if let mapSelectedPersonLocation = state.mapSelectedContact?.personLocation {
                presentContactDetails(mapSelectedPersonLocation)
            } else {
                dismissContactDetails()
            }
        }
        if state.mapSelectedPersonLocationForEdit != prevState?.mapSelectedPersonLocationForEdit {
            if let location = state.mapSelectedPersonLocationForEdit {
                presentPersonLocationForEdit(personLocation: location)
            } else {
                dismissPersonLocationForEdit()
            }
        }
        presentOrDismissOnboarding()
    }

    private func presentOrDismissOnboarding() {
        var needsOnboarding = false
        if let currentState = currentState {
            needsOnboarding = (
                !currentState.accessGranted ||
                currentState.geocoderQueueCount > 3 ||
                (currentState.geocoderQueueCount > 0 && onboardingVC != nil)
            )
        }
        if needsOnboarding {
            presentOnboarding()
        } else {
            dismissOnboarding()
        }
    }

    private func presentOnboarding() {
        if self.onboardingVC != nil {
            return
        }

        let onboardingVC = OnboardingViewController()
        onboardingVC.modalPresentationStyle = .overFullScreen
        self.onboardingVC = onboardingVC

        let keyWindow = UIApplication.shared.connectedScenes
            .flatMap { ($0 as? UIWindowScene)?.windows ?? [] }
            .first { $0.isKeyWindow }
        guard let keyWindow = keyWindow else {
            fatalError("No key window")
        }

        guard var topVC = keyWindow.rootViewController else {
            fatalError("No top view controller")
        }
        while let presentedViewController = topVC.presentedViewController {
            topVC = presentedViewController
        }
        topVC.present(onboardingVC, animated: false)
    }

    private func dismissOnboarding() {
        if let onboardingVC = onboardingVC {
            onboardingVC.dismiss(animated: true)
            self.onboardingVC = nil
        }
    }

    private func presentContactDetails(_ personLocation: PersonLocation) {
        if let contactDetailVC = contactDetailVC {
            contactDetailVC.personLocation = personLocation
            return // already presented
        }
        let contactDetailVC = ContactDetailViewController(personLocation: personLocation)
        setViewController(contactDetailVC, for: .primary)
        self.contactDetailVC = contactDetailVC
    }

    private func dismissContactDetails() {
        setViewController(contactListVC, for: .primary)
        contactDetailVC = nil
    }

    private func presentPersonLocationForEdit(personLocation: PersonLocation) {
        if personLocationEditVC != nil {
            return // already presented
        }
        guard let contactDetailVC = contactDetailVC else {
            fatalError("No contact details presented; cannot edit location")
        }
        let personLocationEditVC = LocationEditViewController(personLocation: personLocation)
        personLocationEditVC.isModalInPresentation = true // prevent dismissal
        if let sheet = personLocationEditVC.sheetPresentationController {
            sheet.delegate = self
        }
        contactDetailVC.present(personLocationEditVC, animated: true)
        self.personLocationEditVC = personLocationEditVC
    }

    private func dismissPersonLocationForEdit() {
        personLocationEditVC?.dismiss(animated: true)
        personLocationEditVC = nil
    }

}
