import UIKit
import CoreLocation

class Window: UIWindow {
//    let tabBar = UITabBar()

//    override init(frame: CGRect) {
//        super.init(frame: frame)
//
//        tabBar.backgroundColor = .white
//        tabBar.frame.size.height = 100;
//        tabBar.frame.size.width = frame.width;
//        tabBar.frame.origin.y = frame.height - tabBar.frame.height;
////        tabBarframe: .init(x: 0, y: view.frame.height - 100, width: view.frame.width, height: 100))
//        tabBar.backgroundColor = .red
//        addSubview(tabBar)
////        tabBar.translatesAutoresizingMaskIntoConstraints = false
////        NSLayoutConstraint.activate([
////            tabBar.leadingAnchor.constraint(equalTo: window.leadingAnchor),
//////            tabBar.trailingAnchor.constraint(equalTo: window.trailingAnchor),
//////            tabBar.bottomAnchor.constraint(equalTo: view.bottomAnchor),
////        ])
//    }
//
//    required init?(coder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let tabBar = subviews.first { view in
            return type(of: view) == UITabBar.self
        }
        if let tabBar = tabBar {
            addSubview(tabBar)
        }
    }
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        window = Window(frame: UIScreen.main.bounds)
        let rootVC = RootViewController()
        window!.rootViewController = rootVC
        window!.makeKeyAndVisible()
        return true
    }

}
