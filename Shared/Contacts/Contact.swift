import Foundation
import Contacts
import CoreLocation
import MapKit

struct Contact: Identifiable, Equatable, Comparable {
    static func < (lhs: Contact, rhs: Contact) -> Bool {
        let a1 = lhs.info.affinity;
        let a2 = rhs.info.affinity;
        if (a1 != a2) {
            return a1.rawValue < a2.rawValue
        }
        if (!lhs.nickname.isEmpty && rhs.nickname.isEmpty) {
            return true // nicknamed contacts are probably closer friends?
        }
        return lhs.displayName < rhs.displayName
    }
    var id: String
    var givenName: String
    var familyName: String
    var companyName: String
    var nickname: String
    var thumbnailImageData: Data?
    var postalAddresses: [PostalAddress]
    var info: ContactInfo
    var displayName: String {
        if !nickname.isEmpty {
            return nickname
        }
        return fullName
    }
    var fullName: String {
        if givenName.isEmpty && familyName.isEmpty {
            fatalError("Expected name for contact")
        }
        if familyName.isEmpty {
            return givenName
        }
        return "\(givenName) \(familyName)"
    }
    var initials: String {
        var initials = ""
        if !nickname.isEmpty {
            initials += nickname.prefix(1)
            return initials
        }
        if !givenName.isEmpty {
            initials += givenName.prefix(1)
        }
        if !familyName.isEmpty {
            initials += familyName.prefix(1)
        }
        if initials.isEmpty {
            initials += companyName.prefix(1)
        }
        return initials
    }
    var searchString: String {
        var components: [String] = []
        if !nickname.isEmpty {
            components.append(nickname)
        }
        if !givenName.isEmpty {
            components.append(givenName)
        }
        if !familyName.isEmpty {
            components.append(familyName)
        }
        return components.joined(separator: " ").lowercased()
    }
    var homeAddresses: [PostalAddress] {
        return postalAddresses.excludingWork().removingDuplicateIDs()
    }
}

struct ContactLocation: Identifiable, Equatable {
    let contact: Contact
    let postalAddress: PostalAddress?
    var id: String {
        get {
            var id = contact.id + "-"
            if let postalAddress = postalAddress {
                id += postalAddress.id
            } else {
                id += "null"
            }
            return id
        }
    }
}

struct ContactLocationResult {
    let contactLocation: ContactLocation
    let distance: CLLocationDistance
}

extension Contact {
    func nearestHomeLocation(to target: CLLocationCoordinate2D) -> ContactLocationResult {
        var nearestPostalAddress: PostalAddress?
        var nearestDistance: CLLocationDistance = .infinity
        homeAddresses.forEach { postalAddress in
            if let coordinate = postalAddress.coordinate {
                let distance = CLLocation.distance(from: coordinate, to: target)
                if distance < nearestDistance {
                    nearestPostalAddress = postalAddress
                    nearestDistance = distance
                }
            }
        }
        return ContactLocationResult(
            contactLocation: ContactLocation(contact: self, postalAddress: nearestPostalAddress),
            distance: nearestDistance
        )
    }
}

extension [Contact] {
    func sorted() -> Self {
        return self.sorted(by: { $0 < $1 })
    }
}
