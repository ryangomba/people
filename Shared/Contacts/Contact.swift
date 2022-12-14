import Foundation
import Contacts
import CoreLocation
import MapKit

struct Contact: Identifiable, Equatable, Comparable {
    static func < (lhs: Contact, rhs: Contact) -> Bool {
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
    var primaryPhoneNumber: String?
    var emailAddresses: [String]
    var aliasEmail: String {
        // TODO: might not exist
        return emailAddresses.first { emailAddress in
            emailAddress.hasPrefix("c") && emailAddress.hasSuffix("@ryangomba.com")
        }!
    }
    var postalAddresses: [PostalAddress]
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
    var homeAddresses: [PostalAddress] {
        return postalAddresses.excludingWork().removingDuplicateIDs()
    }
}

extension [Contact] {
    func sorted() -> Self {
        return self.sorted(by: { $0 < $1 })
    }
}
