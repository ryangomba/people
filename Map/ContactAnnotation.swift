import MapKit

class ContactAnnotation: NSObject, MKAnnotation {
    let personLocation: PersonLocation
    var coordinate: CLLocationCoordinate2D {
        return personLocation.postalAddress!.coordinate!
    }
    init(_ personLocation: PersonLocation) {
        self.personLocation = personLocation
    }
}

class ContactClusterAnnotation: NSObject, MKAnnotation {
    var coordinate: CLLocationCoordinate2D
    let personLocations: [PersonLocation]
    init(coordinate: CLLocationCoordinate2D, personLocations: [PersonLocation]) {
        self.coordinate = coordinate
        self.personLocations = personLocations
    }
}
