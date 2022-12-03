import ReSwift
import SwiftUI
import MapKit

struct MapContactSelection: Equatable {
    var coordinate: CLLocationCoordinate2D?
    var personLocation: PersonLocation?
    var fromCluster: Bool
}

struct AppState {
    // Auth statuses
    var locationAuthStatus: LocationAuthStatus
    var contactsAuthStatus: ContactsAuthStatus
    var calendarAuthStatus: CalendarAuthStatus
    var notificationsAuthStatus: NotificationsAuthStatus

    // Data
    var contacts: [Contact] = []
    var calendarEvents: [CalendarEvent] = []
    var persons: [Person] = []
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
    var mapSelectedAffinities: [Affinity] = Affinity.allCases
    var mapContactDetailsDetentIdentifier: UISheetPresentationController.Detent.Identifier = .normal
    var mapPersonLocationForEdit: PersonLocation?
}
