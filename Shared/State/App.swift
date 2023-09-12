import Foundation
import ReSwift

class App {
    let locationAuthManager = LocationAuthManager()
    let contactRepository = ContactRepository()
    let notificationsManager = NotificationsManager()

    let store: Store<AppState>

    init() {
        store = Store<AppState>(
            reducer: appReducer,
            state: AppState(
                locationAuthStatus: locationAuthManager.authorizationStatus,
                contactsAuthStatus: contactRepository.authorizationStatus,
                notificationsAuthStatus: notificationsManager.authorizationStatus
            )
        )
        locationAuthManager.listenForChanges()
        contactRepository.sync()
        URLCache.shared.memoryCapacity = 10000000 // 10MB
        URLCache.shared.diskCapacity = 100000000 // 100MB
    }
}

let app = App()
