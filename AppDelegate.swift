import UIKit
import CoreLocation

class Window: UIWindow {
    override func layoutSubviews() {
        super.layoutSubviews()
#if AFFINITES_ENABLED
        let tabBar = subviews.first { view in
            return type(of: view) == UITabBar.self
        }
        if let tabBar = tabBar {
            addSubview(tabBar)
        }
#endif
    }
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        window = Window(frame: UIScreen.main.bounds)

        #if targetEnvironment(macCatalyst)
        let splitVC = UISplitViewController(style: .doubleColumn)
        splitVC.primaryBackgroundStyle = .sidebar
        splitVC.preferredDisplayMode = .oneBesideSecondary
        splitVC.displayModeButtonVisibility = .never
        let contactListVC = MapContactListViewController()
        splitVC.setViewController(contactListVC, for: .primary)
        let mapVC = MapViewController()
        splitVC.setViewController(mapVC, for: .secondary)
        window!.rootViewController = splitVC
        window?.windowScene?.titlebar?.titleVisibility = .hidden
        window?.windowScene?.titlebar?.toolbar = nil
        #else
        let rootVC = RootViewController()
        window!.rootViewController = rootVC
        #endif

        window!.makeKeyAndVisible()
        return true
    }

}
