import ReSwift

class App {
    let locationAuthManager = LocationAuthManager()
    let contactRepository = ContactRepository()

    let store: Store<AppState>

    init() {
        store = Store<AppState>(
            reducer: appReducer,
            state: AppState(
                locationAuthStatus: locationAuthManager.authorizationStatus,
                contactsAuthStatus: contactRepository.authorizationStatus
            )
        )
        locationAuthManager.listenForChanges()
        contactRepository.sync()
    }
}

let app = App()
