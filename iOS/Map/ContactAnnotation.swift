import MapKit

class ContactAnnotation: NSObject, MKAnnotation {
    let contactLocation: ContactLocation
    var coordinate: CLLocationCoordinate2D {
        return contactLocation.postalAddress!.coordinate!
    }
    init(_ contactLocation: ContactLocation) {
        self.contactLocation = contactLocation
    }
}

class ContactClusterAnnotation: NSObject, MKAnnotation {
    var coordinate: CLLocationCoordinate2D
    let contactLocations: [ContactLocation]
    init(coordinate: CLLocationCoordinate2D, contactLocations: [ContactLocation]) {
        self.coordinate = coordinate
        self.contactLocations = contactLocations
    }
}
