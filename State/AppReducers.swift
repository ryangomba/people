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
        state.persons = personsFromContacts(state.contacts)
        // Make sure we update the selected contact
        // because information about it might have changed
        // TODO: this is inelegant
        if let selectedPersonLocation = state.mapSelection?.personLocation {
            if let updatedPerson = state.persons.first(where: { $0.id == selectedPersonLocation.person.id }) {
                state.mapSelection?.personLocation = PersonLocation(
                    person: updatedPerson,
                    postalAddress: selectedPersonLocation.postalAddress
                )
            }
        }

    case let action as GeocoderQueueCountChanged:
        state.geocoderQueueCount = action.newCount

    case let action as ListSearchQueryChanged:
        state.listSearchQuery = action.searchQuery

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
        state.mapSearchQuery = ""
        state.mapIsSearching = false
        state.mapContactListDetentIdentifier = .small

    case let action as MapAnnotationSelected:
        zoomToCoordinate(coordinate: action.coordinate)
        state.mapSelection = MapContactSelection(
            coordinate: action.coordinate,
            personLocation: action.personLocation,
            fromCluster: action.isCluster
        )
        if action.isCluster && state.mapContactListDetentIdentifier == .collapsed {
            state.mapContactListDetentIdentifier = .small
        }

    case let action as MapPersonLocationSelected:
        state.mapSearchQuery = ""
        state.mapIsSearching = false
        if state.mapContactListDetentIdentifier == .large {
            state.mapContactListDetentIdentifier = .small
        }
        if state.mapContactDetailsDetentIdentifier == .large {
            state.mapContactDetailsDetentIdentifier = .normal
        }
        let coordinate = action.location.postalAddress?.coordinate
        if let coordinate = coordinate {
            zoomToCoordinate(coordinate: coordinate)
        }
        state.mapSelection = MapContactSelection(
            coordinate: coordinate,
            personLocation: action.location,
            fromCluster: state.mapSelection?.fromCluster ?? false
        )

    case _ as MapContactDetailsDismissed:
        if state.mapSelection?.fromCluster ?? false {
            state.mapSelection?.personLocation = nil
        } else {
            state.mapSelection = nil
        }

    case _ as MapLocationDetailsDismissed:
        state.mapSelection = nil

    case _ as MapStartSearching:
        state.mapIsSearching = true
        state.mapContactListDetentIdentifier = .large

    case _ as MapStopSearching:
        state.mapSearchQuery = ""
        state.mapIsSearching = false
        state.mapContactListDetentIdentifier = .small

    case let action as MapSearchQueryChanged:
        state.mapSearchQuery = action.searchQuery

    case let action as MapContactListDetentChanged:
        state.mapContactListDetentIdentifier = action.detentIdentifier
        state.mapSearchQuery = ""
        state.mapIsSearching = false

    case let action as MapAffinityThresholdChanged:
        state.mapSelectedAffinities = action.selectedAffinities

    case let action as MapContactDetailsDetentChanged:
        state.mapContactDetailsDetentIdentifier = action.detentIdentifier

    case let action as MapPersonLocationSelectedForEdit:
        state.mapPersonLocationForEdit = action.location

    case let action as PersonLocationEdited:
        state.mapPersonLocationForEdit = nil
        let coordinate = action.location.postalAddress?.coordinate
        state.mapSelection = MapContactSelection(
            coordinate: coordinate,
            personLocation: action.location,
            fromCluster: false
        )
        if let coordinate = coordinate {
            zoomToCoordinate(coordinate: coordinate)
        }

    case let action as ContactPhotoChanged:
        if action.contact.id == state.mapSelection?.personLocation?.person.contact.id {
            if state.mapContactDetailsDetentIdentifier == .large {
                state.mapContactDetailsDetentIdentifier = .normal
            }
        }

    case let action as PersonAffinityChanged:
        affinityStore.update(action.person.id, affinity: action.affinity)
        state.persons = personsFromContacts(state.contacts)

    default:
        break
    }

    return state
}
