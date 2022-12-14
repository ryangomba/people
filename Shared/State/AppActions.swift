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

struct NotificationsAccessChanged: Action {
    let status: NotificationsAuthStatus
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

// List

struct ListSearchQueryChanged: Action {
    let searchQuery: String
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
    let personLocation: PersonLocation?
    let isCluster: Bool
}

// Map contacts list

struct MapContactListDetentChanged: Action {
    let detentIdentifier: UISheetPresentationController.Detent.Identifier
}

struct MapContactAffinityThresholdChanged: Action {
    let selectedAffinities: [ContactAffinity]
}

struct MapStartSearching: Action {}
struct MapStopSearching: Action {}
struct MapSearchQueryChanged: Action {
    let searchQuery: String
}

struct MapPersonLocationSelected: Action {
    let location: PersonLocation
}

struct MapContactDetailsDismissed: Action {}

struct MapLocationDetailsDismissed: Action {}

// Map selected contact

struct MapPersonLocationSelectedForEdit: Action {
    let location: PersonLocation?
}

struct MapContactDetailsDetentChanged: Action {
    let detentIdentifier: UISheetPresentationController.Detent.Identifier
}

struct PersonLocationEdited: Action {
    let location: PersonLocation
}

struct ContactPhotoChanged: Action {
    let contact: Contact
}

// Affinity

struct PersonAffinityChanged: Action {
    let person: Person
    let affinity: ContactAffinity
}
