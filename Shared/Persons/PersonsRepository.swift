import Foundation
import CoreLocation

struct Person: Identifiable, Equatable, Comparable {
    static func < (lhs: Person, rhs: Person) -> Bool {
        let a1 = lhs.affinity;
        let a2 = rhs.affinity;
        if (a1 != a2) {
            return a1.rawValue < a2.rawValue
        }
        return lhs.contact < rhs.contact
    }
    let contact: Contact
    let affinity: Affinity
    var id: String {
        get {
            return contact.id
        }
    }
}

private func personFromContact(_ contact: Contact) -> Person {
    let affinity = affinityStore.get(contact.id)
    return Person(
        contact: contact,
        affinity: affinity
    )
}

func personsFromContacts(_ contacts: [Contact]) -> [Person] {
    if contacts.isEmpty {
        return []
    }
    return contacts.map { contact in
        return personFromContact(contact)
    }
}

// PersonLocation

struct PersonLocation: Identifiable, Equatable {
    let person: Person
    let postalAddress: PostalAddress?
    var id: String {
        get {
            var id = person.id + "-"
            if let postalAddress = postalAddress {
                id += postalAddress.id
            } else {
                id += "null"
            }
            return id
        }
    }
}

struct PersonLocationResult {
    let personLocation: PersonLocation
    let distance: CLLocationDistance
}

extension Person {
    func nearestHomeLocation(to target: CLLocationCoordinate2D) -> PersonLocationResult {
        var nearestPostalAddress: PostalAddress?
        var nearestDistance: CLLocationDistance = .infinity
        contact.homeAddresses.forEach { postalAddress in
            if let coordinate = postalAddress.coordinate {
                let distance = CLLocation.distance(from: coordinate, to: target)
                if distance < nearestDistance {
                    nearestPostalAddress = postalAddress
                    nearestDistance = distance
                }
            }
        }
        return PersonLocationResult(
            personLocation: PersonLocation(person: self, postalAddress: nearestPostalAddress),
            distance: nearestDistance
        )
    }
}
