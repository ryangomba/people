import CoreLocation

enum LocationAuthStatus: Int {
    case notDetermined = 1
    case authorized = 2
    case denied = 3
}

class LocationAuthManager: NSObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    public var authorizationStatus = authStatusFromCLAuthorizationStatus(CLLocationManager().authorizationStatus)

    public func listenForChanges() {
        updateAuthorizationStatus()
        locationManager.delegate = self
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        updateAuthorizationStatus()
    }

    public func requestAuthorization() {
        locationManager.requestWhenInUseAuthorization()
    }

    private static func authStatusFromCLAuthorizationStatus(_ status: CLAuthorizationStatus) -> LocationAuthStatus {
        switch status {
        case .notDetermined:
            return .notDetermined
        case .authorizedWhenInUse, .authorizedAlways:
            return .authorized
        case .denied, .restricted:
            return .denied
        default:
            // Assume authorized if we don't recognize the status
            return .authorized
        }
    }

    private func updateAuthorizationStatus() {
        let newAuthorizationStatus = Self.authStatusFromCLAuthorizationStatus(locationManager.authorizationStatus)
        if newAuthorizationStatus != authorizationStatus {
            authorizationStatus = newAuthorizationStatus
            app.store.dispatch(LocationAccessChanged(status: newAuthorizationStatus))
        }
    }

}
