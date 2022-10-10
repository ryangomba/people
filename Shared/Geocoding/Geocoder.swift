import CoreLocation
import Contacts

struct GeocodeResult: Codable {
    let latitude: Double
    let longitude: Double
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

class SerialGeocoder {
    private let geocoder = CLGeocoder()
    private var geocodeLock = NSLock()
    func geocodePostalAddress(_ value: CNPostalAddress) async throws -> [CLPlacemark] {
        return try await withCheckedThrowingContinuation { continuation in
            geocodePostalAddress(value) { result in
                continuation.resume(with: result)
            }
        }
    }
    private func geocodePostalAddress(_ value: CNPostalAddress, completion:  @escaping (Result<[CLPlacemark], Error>) -> Void) {
        geocodeLock.lock()
        geocoder.geocodePostalAddress(value) { placemarks, error in
            self.geocodeLock.unlock()
            if let placemarks = placemarks {
                completion(.success(placemarks))
            } else {
                completion(.failure(error!))
            }
        }
    }
}

class Geocoder {
    private let queue = DispatchQueue(label: "geocoder", qos: .background)
    private let geocoder = SerialGeocoder()
    private let cacheManager = PersistentCache<GeocodeResult>(name: "geocodeCache_v2", maxSize: 1000)
    private var lastGeocode = Date.distantPast
    private var queueCount = 0 {
        didSet {
            let newCount = queueCount
            print("Geocode queue count: \(newCount)")
            DispatchQueue.main.async {
                app.store.dispatch(GeocoderQueueCountChanged(newCount: newCount))
            }
        }
    }

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
            queueCount += 1
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
            let placemarks = try await geocoder.geocodePostalAddress(postalAddress.cnValue)
            if let placemark = placemarks.first {
                let coordinate = placemark.location?.coordinate
                if let coordinate = coordinate {
                    let result = GeocodeResult(latitude: coordinate.latitude, longitude: coordinate.longitude)
                    queue.sync {
                        cacheManager.update(key, result: result)
                        queueCount -= 1
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
        queue.sync {
            queueCount -= 1
        }
        return nil
    }

}
