import Foundation
import ReSwift

class App {
    let locationAuthManager = LocationAuthManager()
    let contactRepository = ContactRepository()

    let store: Store<AppState>

    init() {
        URLCache.shared.memoryCapacity = 10000000 // 10MB
        URLCache.shared.diskCapacity = 100000000 // 100MB
        store = Store<AppState>(
            reducer: appReducer,
            state: AppState(
                locationAuthStatus: locationAuthManager.authorizationStatus,
                contactsAuthStatus: contactRepository.authorizationStatus
            )
        )
        contactRepository.sync()
        // HACK: this call requires the singleton "app" to be defined below
        DispatchQueue.main.async {
            self.locationAuthManager.listenForChanges()
        }
    }
}

let app = App()
