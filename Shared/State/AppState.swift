import ReSwift
import SwiftUI
import MapKit

struct MapContactSelection: Equatable {
    var coordinate: CLLocationCoordinate2D?
    var contactLocation: ContactLocation?
    var fromCluster: Bool
}

struct AppState {
    // Auth statuses
    var locationAuthStatus: LocationAuthStatus
    var contactsAuthStatus: ContactsAuthStatus
    var calendarAuthStatus: CalendarAuthStatus

    // Data
    var contacts: [Contact] = []
    var calendarEvents: [CalendarEvent] = []
    var geocoderQueueCount: Int = 0

    // List
    var listIsSearching = false
    var listSearchQuery = ""

    // Map
    var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(),
        span: MKCoordinateSpan(latitudeDelta: MapSpanDelta.normal, longitudeDelta: 0)
    )
    var mapSelection: MapContactSelection?
    var mapContactListDetentIdentifier: UISheetPresentationController.Detent.Identifier = .small
    var mapIsSearching = false
    var mapSearchQuery = ""
    var mapSelectedAffinities: [ContactAffinity] = ContactAffinity.allCases
    var mapContactDetailsDetentIdentifier: UISheetPresentationController.Detent.Identifier = .normal
    var mapContactLocationForEdit: ContactLocation?
}
