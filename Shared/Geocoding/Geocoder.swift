import CoreLocation
import Contacts

struct GeocodeResult: Codable {
    let latitude: Double
    let longitude: Double
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

class Geocoder {
    private let queue = DispatchQueue(label: "geocoder", qos: .background)
    private let geocoder = CLGeocoder()
    private let cacheManager = PersistentCache<GeocodeResult>(name: "geocodeCache_v2")
    private var lastGeocode = Date.distantPast

    private func keyForPostalAddress(_ postalAddress: PostalAddressValue) -> String {
        return postalAddress.id
    }

    func cacheGeocodedPostalAddress(_ postalAddress: PostalAddressValue, coordinate: CLLocationCoordinate2D) {
        let key = keyForPostalAddress(postalAddress)
        queue.async {
            self.cacheManager.update(key, result: GeocodeResult(latitude: coordinate.latitude, longitude: coordinate.longitude))
        }
    }

    func getCachedGeocodedPostalAddress(_ postalAddress: PostalAddressValue) -> GeocodeResult? {
        let key = keyForPostalAddress(postalAddress)
        return queue.sync {
            return cacheManager.get(key)
        }.result
    }

    func geocodePostalAddress(_ postalAddress: PostalAddressValue) async -> GeocodeResult? {
        let key = keyForPostalAddress(postalAddress)
        let lookup = queue.sync {
            return cacheManager.get(key)
        }
        if lookup.cached {
            return lookup.result
        }
        let timeoutSeconds = queue.sync {
            let now = Date()
            var timeoutSeconds: Double = 0
            let secondsSinceLastGeocode = now.timeIntervalSince(lastGeocode)
            if secondsSinceLastGeocode < 1 { // rate limit 1 geocode per second
                timeoutSeconds = 1 - secondsSinceLastGeocode
            }
            lastGeocode = now.addingTimeInterval(timeoutSeconds)
            return timeoutSeconds
        }
        if timeoutSeconds > 0 {
            try! await Task.sleep(nanoseconds: UInt64(timeoutSeconds) * 1000000000)
        }
        do {
            print("Geocoding address")
            let placemarks = try await geocoder.geocodePostalAddress(postalAddress.cnValue)
            if let placemark = placemarks.first {
                let coordinate = placemark.location?.coordinate
                if let coordinate = coordinate {
                    let result = GeocodeResult(latitude: coordinate.latitude, longitude: coordinate.longitude)
                    queue.sync {
                        cacheManager.update(key, result: result)
                    }
                    return result
                }
            }
        } catch {
            var reason = "unknown"
            let network = (error as? CLError)?.code == .network
            let noResult = (error as? CLError)?.code == .geocodeFoundNoResult
            if (network) {
                reason = "rate limit"
            } else if (noResult) {
                reason = "no result"
                queue.sync {
                    cacheManager.update(key, result: nil)
                }
            }
            print("Failed to geocode \(postalAddress), error: \(error), reason: \(reason)")
        }
        return nil
    }

}
