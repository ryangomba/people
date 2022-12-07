import ReSwift
import Contacts
import MapKit

// Data

struct LocationAccessChanged: Action {
    let status: LocationAuthStatus
}

struct CalendarAccessChanged: Action {
    let status: CalendarAuthStatus
}

struct ContactsAccessChanged: Action {
    let status: ContactsAuthStatus
}

struct ContactsChanged: Action {
    let newContacts: [Contact]
}

struct CalendarChanged: Action {
    let newCalendarEvents: [CalendarEvent]
}

struct GeocoderQueueCountChanged: Action {
    let newCount: Int
}

// Map

struct MapRegionChanged: Action {
    let region: MKCoordinateRegion
}

struct FocusUserLocation: Action {
    let coordinate: CLLocationCoordinate2D
}

struct FocusRegionalLocation: Action {
    let coordinate: CLLocationCoordinate2D
}

struct MapAnnotationSelected: Action {
    let coordinate: CLLocationCoordinate2D
    let contactLocation: ContactLocation?
    let isCluster: Bool
}

// Contacts list

struct ContactListDetentChanged: Action {
    let detentIdentifier: UISheetPresentationController.Detent.Identifier
}

struct ContactAffinityThresholdChanged: Action {
    let selectedAffinities: [ContactAffinity]
}

struct StartSearching: Action {}
struct StopSearching: Action {}
struct SearchQueryChanged: Action {
    let searchQuery: String
}

struct ContactLocationSelected: Action {
    let location: ContactLocation
}

struct ContactDetailsDismissed: Action {}

struct LocationDetailsDismissed: Action {}

// Selected contact

struct ContactLocationSelectedForEdit: Action {
    let location: ContactLocation?
}

struct ContactDetailsDetentChanged: Action {
    let detentIdentifier: UISheetPresentationController.Detent.Identifier
}

struct ContactLocationEdited: Action {
    let location: ContactLocation
}

struct ContactPhotoChanged: Action {
    let contact: Contact
}
