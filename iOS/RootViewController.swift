import UIKit
import CoreLocation
import ReSwift

struct RootViewControllerState: Equatable {
    var contactsAccessGranted: Bool
    var locationAccessGranted: Bool
    var geocoderQueueCount: Int
    var contentListDetentIdentifer: UISheetPresentationController.Detent.Identifier
    var contentDetailsDetentIdentifer: UISheetPresentationController.Detent.Identifier
    var selectedContact: ContactSelection?
    var selectedContactLocationForEdit: ContactLocation?

    init(newState: AppState) {
        contactsAccessGranted = newState.contactsAuthStatus == .authorized
        locationAccessGranted = newState.locationAuthStatus == .authorized
        geocoderQueueCount = newState.geocoderQueueCount
        contentListDetentIdentifer = newState.contactListDetentIdentifier
        contentDetailsDetentIdentifer = newState.contactDetailsDetentIdentifier
        selectedContact = newState.selection
        selectedContactLocationForEdit = newState.contactLocationForEdit
    }
}

class RootViewController: UITabBarController, StoreSubscriber, UISheetPresentationControllerDelegate, UITabBarControllerDelegate {
    private var currentState: RootViewControllerState?
    private let mapVC = MapViewController()
    private let contactListVC = MapContactListViewController()
    private var contactDetailVC: ContactDetailViewController?
    private var contactLocationEditVC: LocationEditViewController?
    private var onboardingVC: OnboardingViewController?

    init() {
        super.init(nibName: nil, bundle: nil)

        let listVC = UINavigationController(rootViewController: ContactListViewController())
        listVC.navigationBar.prefersLargeTitles = true
        listVC.tabBarItem = UITabBarItem(title: "List", image: .init(systemName: "list.bullet"), tag: 0)
        mapVC.tabBarItem = UITabBarItem(title: "Map", image: .init(systemName: "map"), tag: 1)
        self.viewControllers = [listVC, mapVC]
        self.selectedViewController = mapVC
        self.tabBar.backgroundColor = .white

        self.delegate = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        // TODO: this is so, so hacky
        view.window!.addSubview(self.tabBar)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

//        mapVC.willMove(toParent: self)
//        view.addSubview(mapVC.view)
//        addChild(mapVC)
//        mapVC.didMove(toParent: self)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        presentContactsList()
        presentOrDismissOnboarding()

        app.store.subscribe(self) { subscription in
            return subscription.select(RootViewControllerState.init)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        app.store.unsubscribe(self)
    }

    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        if (viewController == mapVC) {
            presentContactsList()
        } else {
            contactListVC.view.isHidden = true;
            contactListVC.dismiss(animated: false) {
                self.contactListVC.view.isHidden = false;
            }
        }
    }

    func newState(state: RootViewControllerState) {
        let prevState = currentState
        currentState = state

        if state.contentListDetentIdentifer != prevState?.contentListDetentIdentifer {
            contactListVC.sheetPresentationController?.animateChanges {
                contactListVC.sheetPresentationController?.selectedDetentIdentifier = state.contentListDetentIdentifer
            }
        }
        if state.contentDetailsDetentIdentifer != prevState?.contentDetailsDetentIdentifer {
            contactDetailVC?.sheetPresentationController?.animateChanges {
                contactDetailVC?.sheetPresentationController?.selectedDetentIdentifier = state.contentDetailsDetentIdentifer
            }
        }
        if state.selectedContact != prevState?.selectedContact {
            if let selectedContactLocation = state.selectedContact?.contactLocation {
                presentContactDetails(selectedContactLocation)
            } else {
                dismissContactDetails()
            }
        }
        if state.selectedContactLocationForEdit != prevState?.selectedContactLocationForEdit {
            if let location = state.selectedContactLocationForEdit {
                presentContactLocationForEdit(contactLocation: location)
            } else {
                dismissContactLocationForEdit()
            }
        }
        presentOrDismissOnboarding()
    }

    func sheetPresentationControllerDidChangeSelectedDetentIdentifier(_ sheetPresentationController: UISheetPresentationController) {
        if sheetPresentationController == contactListVC.sheetPresentationController {
            app.store.dispatch(ContactListDetentChanged(detentIdentifier: sheetPresentationController.selectedDetentIdentifier!))
        } else if sheetPresentationController == contactDetailVC?.sheetPresentationController {
            app.store.dispatch(ContactDetailsDetentChanged(detentIdentifier: sheetPresentationController.selectedDetentIdentifier!))
        }
    }

    private func presentOrDismissOnboarding() {
        var needsOnboarding = false
        if let currentState = currentState {
            needsOnboarding = !currentState.contactsAccessGranted || !currentState.locationAccessGranted || currentState.geocoderQueueCount > 3 || (currentState.geocoderQueueCount > 0 && onboardingVC != nil)
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
        onboardingVC.modalPresentationStyle = .fullScreen
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

    private func presentContactsList() {
        contactListVC.isModalInPresentation = true // prevent dismissal
        if let sheet = contactListVC.sheetPresentationController {
            sheet.detents = [.collapsed, .small, .large()]
            sheet.selectedDetentIdentifier = app.store.state.contactListDetentIdentifier
            sheet.largestUndimmedDetentIdentifier = .small
            sheet.prefersGrabberVisible = true
            sheet.delegate = self
        }
        mapVC.present(contactListVC, animated: false)
    }

    private func presentContactDetails(_ contactLocation: ContactLocation) {
        if let contactDetailVC = contactDetailVC {
            contactDetailVC.contactLocation = contactLocation
            return // already presented
        }
        let contactDetailVC = ContactDetailViewController(contactLocation: contactLocation)
        contactDetailVC.isModalInPresentation = true // prevent dismissal
        if let sheet = contactDetailVC.sheetPresentationController {
            sheet.detents = [.collapsed, .normal, .large()]
            sheet.selectedDetentIdentifier = .normal
            sheet.largestUndimmedDetentIdentifier = .normal
            sheet.prefersGrabberVisible = true
            sheet.delegate = self
        }
        contactListVC.present(contactDetailVC, animated: true)
        self.contactDetailVC = contactDetailVC
    }

    private func dismissContactDetails() {
        contactDetailVC?.dismiss(animated: true)
        contactDetailVC = nil
    }

    private func presentContactLocationForEdit(contactLocation: ContactLocation) {
        if contactLocationEditVC != nil {
            return // already presented
        }
        guard let contactDetailVC = contactDetailVC else {
            fatalError("No contact details presented; cannot edit location")
        }
        let contactLocationEditVC = LocationEditViewController(contactLocation: contactLocation)
        contactLocationEditVC.isModalInPresentation = true // prevent dismissal
        if let sheet = contactLocationEditVC.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.delegate = self
        }
        contactDetailVC.present(contactLocationEditVC, animated: true)
        self.contactLocationEditVC = contactLocationEditVC
    }

    private func dismissContactLocationForEdit() {
        contactLocationEditVC?.dismiss(animated: true)
        contactLocationEditVC = nil
    }

}
