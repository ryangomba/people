import MapKit

extension MKCoordinateSpan: @retroactive Equatable {
    public static func == (lhs: MKCoordinateSpan, rhs: MKCoordinateSpan) -> Bool {
        return lhs.latitudeDelta == rhs.latitudeDelta && lhs.longitudeDelta == rhs.longitudeDelta
    }
}

extension MKCoordinateRegion: @retroactive Equatable {
    public static func == (lhs: MKCoordinateRegion, rhs: MKCoordinateRegion) -> Bool {
        return lhs.center == rhs.center && lhs.span == rhs.span
    }
}

extension MKCoordinateRegion {
    public func contains(_ coordinate: CLLocationCoordinate2D) -> Bool {
        return (
            cos((center.latitude - coordinate.latitude) * CGFloat.pi / 180) > cos(span.latitudeDelta / 2 * CGFloat.pi / 180.0) &&
            cos((center.longitude - coordinate.longitude) * CGFloat.pi / 180) > cos(span.longitudeDelta / 2 * CGFloat.pi / 180.0)
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
