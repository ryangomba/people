import ReSwift
import SwiftUI
import MapKit

struct ContactSelection: Equatable {
    var coordinate: CLLocationCoordinate2D?
    var contactLocation: ContactLocation?
    var fromCluster: Bool
}

struct AppState {
    var locationAuthStatus: LocationAuthStatus
    var contactsAuthStatus: ContactsAuthStatus
    var contacts: [Contact] = []
    var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(),
        span: MKCoordinateSpan(latitudeDelta: MapSpanDelta.normal, longitudeDelta: 0)
    )
    var selection: ContactSelection?
    var contactListDetentIdentifier: UISheetPresentationController.Detent.Identifier = .small
    var isSearching = false
    var searchQuery = ""
    var contactDetailsDetentIdentifier: UISheetPresentationController.Detent.Identifier = .normal
    var contactLocationForEdit: ContactLocation?
}
