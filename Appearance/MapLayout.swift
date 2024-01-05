import MapKit

struct MapSpanDelta {
    static let normal: CGFloat = 0.5
    static let focused: CGFloat = 0.1
    static let superFocused: CGFloat = 0.025
}

func focusedCoordinateToMapCenter(_ coordinate: CLLocationCoordinate2D, for mapSpan: MKCoordinateSpan) -> CLLocationCoordinate2D {
    var latitude = coordinate.latitude
    #if !targetEnvironment(macCatalyst)
    latitude -= mapSpan.latitudeDelta / 6
    #endif
    return CLLocationCoordinate2D(
        latitude: latitude,
        longitude: coordinate.longitude
    )
}

func focusedCoordinateForMapRegion(_ region: MKCoordinateRegion) -> CLLocationCoordinate2D {
    var latitude = region.center.latitude
    #if !targetEnvironment(macCatalyst)
    latitude += region.span.latitudeDelta / 6
    #endif
    return CLLocationCoordinate2D(
        latitude: latitude,
        longitude: region.center.longitude
    )
}
