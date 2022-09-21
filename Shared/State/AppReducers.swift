import ReSwift
import MapKit

func appReducer(action: Action, state: AppState?) -> AppState {
    guard var state = state else {
        fatalError("Expected existing state")
    }

    func zoomToCoordinate(coordinate: CLLocationCoordinate2D) {
        let newSpan = MKCoordinateSpan(
            latitudeDelta: min(state.mapRegion.span.latitudeDelta, MapSpanDelta.focused),
            longitudeDelta: 0
        )
        state.mapRegion.span = newSpan
        state.mapRegion.center = focusedCoordinateToMapCenter(coordinate, for: newSpan)
    }

    print("Action: \(type(of: action))")

    switch action {

    case let action as LocationAccessChanged:
        state.locationAuthStatus = action.status

    case let action as ContactsAccessChanged:
        state.contactsAuthStatus = action.status

    case let action as ContactsChanged:
        state.contacts = action.newContacts
        // Make sure we update the selected contact
        // because information about it might have changed
        // TODO: this is inelegant
        if let selectedContactLocation = state.selection?.contactLocation {
            if let updatedContact = action.newContacts.first(where: { $0.id == selectedContactLocation.contact.id }) {
                state.selection?.contactLocation = ContactLocation(
                    contact: updatedContact,
                    postalAddress: selectedContactLocation.postalAddress
                )
            }
        }

    case let action as MapRegionChanged:
        state.mapRegion = action.region

    case let action as FocusUserLocation:
        zoomToCoordinate(coordinate: action.coordinate)

    case let action as FocusRegionalLocation:
        state.mapRegion = MKCoordinateRegion(
            center: action.coordinate,
            span: MKCoordinateSpan(
                latitudeDelta: MapSpanDelta.normal,
                longitudeDelta: 0
            )
        )
        state.searchQuery = ""
        state.isSearching = false
        state.contactListDetentIdentifier = .small

    case let action as MapAnnotationSelected:
        zoomToCoordinate(coordinate: action.coordinate)
        state.selection = ContactSelection(
            coordinate: action.coordinate,
            contactLocation: action.contactLocation,
            fromCluster: action.isCluster
        )
        if action.isCluster && state.contactListDetentIdentifier == .collapsed {
            state.contactListDetentIdentifier = .small
        }

    case let action as ContactLocationSelected:
        state.searchQuery = ""
        state.isSearching = false
        if state.contactListDetentIdentifier == .large {
            state.contactListDetentIdentifier = .small
        }
        if state.contactDetailsDetentIdentifier == .large {
            state.contactDetailsDetentIdentifier = .normal
        }
        let coordinate = action.location.postalAddress?.coordinate
        if let coordinate = coordinate {
            zoomToCoordinate(coordinate: coordinate)
        }
        state.selection = ContactSelection(
            coordinate: coordinate,
            contactLocation: action.location,
            fromCluster: state.selection?.fromCluster ?? false
        )

    case _ as ContactDetailsDismissed:
        if state.selection?.fromCluster ?? false {
            state.selection?.contactLocation = nil
        } else {
            state.selection = nil
        }

    case _ as LocationDetailsDismissed:
        state.selection = nil

    case _ as StartSearching:
        state.isSearching = true
        state.contactListDetentIdentifier = .large

    case _ as StopSearching:
        state.searchQuery = ""
        state.isSearching = false
        state.contactListDetentIdentifier = .small

    case let action as SearchQueryChanged:
        state.searchQuery = action.searchQuery

    case let action as ContactListDetentChanged:
        state.contactListDetentIdentifier = action.detentIdentifier
        state.searchQuery = ""
        state.isSearching = false

    case let action as ContactDetailsDetentChanged:
        state.contactDetailsDetentIdentifier = action.detentIdentifier

    case let action as ContactLocationSelectedForEdit:
        state.contactLocationForEdit = action.location

    case let action as ContactLocationEdited:
        state.contactLocationForEdit = nil
        let coordinate = action.location.postalAddress?.coordinate
        state.selection = ContactSelection(
            coordinate: coordinate,
            contactLocation: action.location,
            fromCluster: false
        )
        if let coordinate = coordinate {
            zoomToCoordinate(coordinate: coordinate)
        }

    case let action as ContactPhotoChanged:
        if action.contact.id == state.selection?.contactLocation?.contact.id {
            if state.contactDetailsDetentIdentifier == .large {
                state.contactDetailsDetentIdentifier = .normal
            }
        }

    default:
        break
    }

    return state
}
