import MapKit

struct MapSpanDelta {
    static let normal: CGFloat = 0.5
    static let focused: CGFloat = 0.1
    static let superFocused: CGFloat = 0.025
}

func focusedCoordinateToMapCenter(_ coordinate: CLLocationCoordinate2D, for mapSpan: MKCoordinateSpan) -> CLLocationCoordinate2D {
    return CLLocationCoordinate2D(
        latitude: coordinate.latitude - mapSpan.latitudeDelta / 6,
        longitude: coordinate.longitude
    )
}

func focusedCoordinateForMapRegion(_ region: MKCoordinateRegion) -> CLLocationCoordinate2D {
    return CLLocationCoordinate2D(
        latitude: region.center.latitude + region.span.latitudeDelta / 6,
        longitude: region.center.longitude
    )
}
