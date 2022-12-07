import UIKit

enum NotificationsAuthStatus: Int {
    case notDetermined = 1
    case authorized = 2
    case denied = 3
}

class NotificationsManager {
    public var authorizationStatus = getAuthorizationStatusSync()

    init() {
        NotificationCenter.default.addObserver(self, selector: #selector(onForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
        updateAuthorizationStatusAsync()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc
    func onForeground() {
        updateAuthorizationStatusAsync()
    }

    private static func authStatusFromUNAuthorizationStatus(_ authorizationStatus: UNAuthorizationStatus) -> NotificationsAuthStatus {
        switch authorizationStatus {
        case .authorized:
            return .authorized
        case .denied:
            return .denied
        case .notDetermined:
            return .notDetermined
        default:
            // Assume authorized if we don't recognize the status
            return .authorized
        }
    }

    private static func getAuthorizationStatusSync() -> NotificationsAuthStatus {
        let semaphore = DispatchSemaphore(value: 0)
        var newAuthorizationStatus: NotificationsAuthStatus = .notDetermined
        UNUserNotificationCenter.current().getNotificationSettings(completionHandler: { settings in
            newAuthorizationStatus = Self.authStatusFromUNAuthorizationStatus(settings.authorizationStatus)
            semaphore.signal()
        })
        semaphore.wait()
        return newAuthorizationStatus
    }

    private func updateAuthorizationStatusAsync() {
        UNUserNotificationCenter.current().getNotificationSettings(completionHandler: { settings in
            let newAuthorizationStatus = Self.authStatusFromUNAuthorizationStatus(settings.authorizationStatus)
            if newAuthorizationStatus != self.authorizationStatus {
                self.authorizationStatus = newAuthorizationStatus
                app.store.dispatch(NotificationsAccessChanged(status: newAuthorizationStatus))
                if newAuthorizationStatus == .authorized {
                    // TODO: update badge here?
                }
            }
        })
    }

    public func requestAuthorization() {
        requestAuthorization { ok, error in
            // noop
        }
    }

    private func requestAuthorization(completionHandler: @escaping (Bool, Error?) -> Void) {
        assert(Thread.isMainThread)

        UNUserNotificationCenter.current().requestAuthorization(options: .badge, completionHandler: completionHandler)
    }

    public func updateBadgeCount(badgeCount: Int) {
        assert(Thread.isMainThread)

        requestAuthorization { ok, error in
            if ok {
                UNUserNotificationCenter.current().setBadgeCount(badgeCount)
            }
        }
    }

}
