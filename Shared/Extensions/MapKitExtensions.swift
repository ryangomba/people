import MapKit

extension MKCoordinateSpan: Equatable {
    public static func == (lhs: MKCoordinateSpan, rhs: MKCoordinateSpan) -> Bool {
        return lhs.latitudeDelta == rhs.latitudeDelta && lhs.longitudeDelta == rhs.longitudeDelta
    }
}

extension MKCoordinateRegion: Equatable {
    public static func == (lhs: MKCoordinateRegion, rhs: MKCoordinateRegion) -> Bool {
        return lhs.center == rhs.center && lhs.span == rhs.span
    }
}

extension MKCoordinateRegion {
    public func contains(_ coordinate: CLLocationCoordinate2D) -> Bool {
        let latitudeDelta = span.latitudeDelta > 0 ? span.latitudeDelta : 90
        let longitudeDelta = span.longitudeDelta > 0 ? span.longitudeDelta : 180
        return (
            cos((center.latitude - coordinate.latitude) * CGFloat.pi / 180) > cos(latitudeDelta / 2 * CGFloat.pi / 180) &&
            cos((center.longitude - coordinate.longitude) * CGFloat.pi / 180) > cos(longitudeDelta / 2 * CGFloat.pi / 180.0)
        )
    }
}

extension [MKLocalSearchCompletion] {
    public func locatableResults() -> [MKLocalSearchCompletion] {
        return self.filter { result in
            // Filter out results that won't have a placemark
            // TODO: this is hacky and prone to breakage
            return !result.subtitle.hasPrefix("Search Nearby")
        }
    }
    public func addressableResults() -> [MKLocalSearchCompletion] {
        return locatableResults().filter { result in
            // Filter out results that won't have an address
            if result.subtitle.isEmpty {
                return false
            }
            return true
        }
    }
}
