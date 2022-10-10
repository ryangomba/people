import Foundation
import CoreLocation
import Contacts
import UIKit
import CoreSpotlight

enum ContactsAuthStatus: Int {
    case notDetermined = 1
    case authorized = 2
    case denied = 3
}

class ContactRepository: ObservableObject {
    public var authorizationStatus = getAuthorizationStatus()
    private let store = CNContactStore()
    private let geocoder = Geocoder()
    @Published var contacts: [Contact] = []
    @Published var searchText = ""

    init() {
        NotificationCenter.default.addObserver(self, selector: #selector(onForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onContactStoreDidChange), name: .CNContactStoreDidChange, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc
    func onForeground() {
        updateAuthorizationStatus()
    }

    @objc
    func onContactStoreDidChange(notification: NSNotification) {
        if notification.userInfo?["CNNotificationOriginationExternally"] != nil {
            print("System contacts did change")
            self.sync()
        }
    }

    private static func getAuthorizationStatus() -> ContactsAuthStatus {
        switch CNContactStore.authorizationStatus(for: .contacts) {
        case .authorized:
            return .authorized
        case .denied, .restricted:
            return .denied
        case .notDetermined:
            return .notDetermined
        default:
            // Assume authorized if we don't recognize the status
            return .authorized
        }
    }

    private func updateAuthorizationStatus() {
        let newAuthorizationStatus = Self.getAuthorizationStatus()
        if newAuthorizationStatus != authorizationStatus {
            authorizationStatus = newAuthorizationStatus
            app.store.dispatch(ContactsAccessChanged(status: newAuthorizationStatus))
            if newAuthorizationStatus == .authorized {
                sync()
            }
        }
    }

    public func requestAuthorization() {
        assert(Thread.isMainThread)

        store.requestAccess(for: .contacts) { ok, error in
            DispatchQueue.main.async {
                self.updateAuthorizationStatus()
            }
        }
    }

    public func sync() {
        assert(Thread.isMainThread)

        if authorizationStatus != .authorized {
            return
        }
        Task.init {
            let newContacts = await fetchSystemContacts()
            DispatchQueue.main.async {
                self.setContacts(newContacts)
                self.locateContacts(self.contacts)
                Task.init {
                    await self.registerContactsWithSpotlight(self.contacts)
                }
            }
        }
    }

    // Fetching from system contacts

    private func fetchSystemContacts() async -> [Contact] {
        var deviceContacts: [CNContact] = []
        do {
            let keysToFetch = [
                CNContactGivenNameKey,
                CNContactFamilyNameKey,
                CNContactOrganizationNameKey,
                CNContactNicknameKey,
                CNContactThumbnailImageDataKey,
                CNContactPostalAddressesKey
            ] as [CNKeyDescriptor]
            let request = CNContactFetchRequest(keysToFetch: keysToFetch)
            try store.enumerateContacts(with: request) {
                (contact, stop) in
                deviceContacts.append(contact)
            }
        } catch {
            print("Failed to fetch contact, error: \(error)")
        }
        let regex = try! NSRegularExpression(pattern: "\\_\\$\\!\\<(.+)\\>\\!\\$\\_", options: [])
        func cleanedLabel(_ label: String?) -> String? {
            if let label = label {
                if (!label.isEmpty) {
                    return regex.stringByReplacingMatches(in: label, options: [], range: NSRange(label.startIndex..<label.endIndex, in: label), withTemplate: "$1")
                }
            }
            return label
        }
        return deviceContacts.enumerated().filter({ (_, deviceContact) in
            return !(deviceContact.givenName + deviceContact.familyName).isEmpty
        }).map({ (index, deviceContact) in
            return Contact(
                id: deviceContact.identifier,
                givenName: deviceContact.givenName,
                familyName: deviceContact.familyName,
                companyName: deviceContact.organizationName,
                nickname: deviceContact.nickname,
                thumbnailImageData: deviceContact.thumbnailImageData,
                postalAddresses: deviceContact.postalAddresses.map({ postalAddress in
                    let value = PostalAddressValue(
                        street: postalAddress.value.street,
                        subLocality: postalAddress.value.subLocality,
                        city: postalAddress.value.city,
                        state: postalAddress.value.state,
                        postalCode: postalAddress.value.postalCode,
                        country: postalAddress.value.country
                    )
                    let coordinate = geocoder.getCachedGeocodedPostalAddress(value)?.coordinate
                    return PostalAddress(
                        label: cleanedLabel(postalAddress.label),
                        value: value,
                        coordinate: coordinate
                    )
                })
            )
        })
    }

    private func updateContacts(_ newContacts: [Contact]) {
        setContacts(contacts.map { contact in
            if let newContact = newContacts.first(where: { c in
                c.id == contact.id
            }) {
                return newContact
            }
            return contact
        })
    }

    private func setContacts(_ newContacts: [Contact]) {
        let sortedContacts = newContacts.sorted()
        if contacts == sortedContacts {
            return
        }
        contacts = sortedContacts
        app.store.dispatch(ContactsChanged(newContacts: contacts))
    }

    // Fetching

    public func getContact(_ id: String) -> Contact {
        assert(Thread.isMainThread)

        return contacts.first { c in c.id == id }!
    }

    // Editing

    public func addPostalAddress(contact: Contact, postalAddress: PostalAddress) -> Contact {
        assert(Thread.isMainThread)

        // Cache the geocoded result for this address, if exists
        // This prevents us from making a redundant geocoder request
        if let coordinate = postalAddress.coordinate {
            geocoder.cacheGeocodedPostalAddress(postalAddress.value, coordinate: coordinate)
        }

        // Update our local and system stores
        let postalAddresses = contact.postalAddresses + [postalAddress]
        return updateContactWithPostalAddresses(contact: contact, postalAddresses: postalAddresses, saveToSystem: true)
    }

    public func updatePostalAddress(contact: Contact, old: PostalAddress, new: PostalAddress) -> Contact {
        assert(Thread.isMainThread)

        // Cache the geocoded result for this address, if exists
        // This prevents us from making a redundant geocoder request
        if let coordinate = new.coordinate {
            geocoder.cacheGeocodedPostalAddress(new.value, coordinate: coordinate)
        }

        // Update our local and system stores
        let postalAddresses = updatePostalAddressesWithAddress(postalAddresses: contact.postalAddresses, old: old, new: new)
        return updateContactWithPostalAddresses(contact: contact, postalAddresses: postalAddresses, saveToSystem: true)
    }

    private func updatePostalAddressesWithAddress(postalAddresses: [PostalAddress], old: PostalAddress, new: PostalAddress) -> [PostalAddress] {
        guard let oldIndex = postalAddresses.firstIndex(where: { $0.id == old.id }) else {
            fatalError("Could not find postal address to update")
        }
        var newPostalAdresses = postalAddresses
        newPostalAdresses.remove(at: oldIndex)
        newPostalAdresses.insert(new, at: oldIndex)
        return newPostalAdresses
    }

    public func deletePostalAddress(_ postalAddressToDelete: PostalAddress, forContact contact: Contact) -> Contact {
        assert(Thread.isMainThread)

        let postalAddresses = contact.postalAddresses.filter { postalAddress in
            return postalAddress.id != postalAddressToDelete.id
        }
        return updateContactWithPostalAddresses(contact: contact, postalAddresses: postalAddresses, saveToSystem: true)
    }

    private func updateContactWithPostalAddresses(contact: Contact, postalAddresses: [PostalAddress], saveToSystem: Bool) -> Contact {
        print("Updating contact postal addresses")

        var newContact = contact
        newContact.postalAddresses = postalAddresses

        // Update the contact in our own local store
        updateContacts([newContact])

        // Sync this update with the system
        if saveToSystem {
            let keysToFetch = [CNContactPostalAddressesKey] as [CNKeyDescriptor]
            let systemContact = try! store.unifiedContact(withIdentifier: contact.id, keysToFetch: keysToFetch)
            let req = CNSaveRequest()
            let mutableContact = systemContact.mutableCopy() as! CNMutableContact
            mutableContact.postalAddresses = postalAddresses.map({ p in p.cnValue })
            req.update(mutableContact)
            try! store.execute(req)
        }

        return newContact
    }

    public func updateContactPhoto(contact: Contact, imageData: Data) {
        print("Updating contact photo")
        assert(Thread.isMainThread)

        var newContact = contact
        newContact.thumbnailImageData = imageData // TODO: check that this isn't massive

        // Update the contact in our own local store
        updateContacts([newContact])

        // Sync this update with the system
        let keysToFetch = [CNContactImageDataKey] as [CNKeyDescriptor]
        let systemContact = try! store.unifiedContact(withIdentifier: contact.id, keysToFetch: keysToFetch)
        let req = CNSaveRequest()
        let mutableContact = systemContact.mutableCopy() as! CNMutableContact
        mutableContact.imageData = imageData
        req.update(mutableContact)
        try! store.execute(req)
    }

    private func locateContacts(_ contacts: [Contact]) {
        for contact in contacts {
            for postalAddress in contact.postalAddresses {
                Task {
                    await locateContactPostalAddress(contact, postalAddress: postalAddress)
                }
            }
        }
    }

    private func locateContactPostalAddress(_ contact: Contact, postalAddress: PostalAddress) async {
        if postalAddress.coordinate != nil {
            return // coordinate already exists, no need to locate
        }
        if let result = await geocoder.geocodePostalAddress(postalAddress.value) {
            if postalAddress.coordinate == result.coordinate {
                return // no change to coordinate, ignore
            }
            DispatchQueue.main.async {
                // Save the updated coordinate in our local store
                var newPostalAddress = postalAddress
                newPostalAddress.coordinate = result.coordinate
                let newContact = self.getContact(contact.id) // contact could be out of date
                let postalAddresses = self.updatePostalAddressesWithAddress(postalAddresses: newContact.postalAddresses, old: postalAddress, new: newPostalAddress)
                _ = self.updateContactWithPostalAddresses(contact: newContact, postalAddresses: postalAddresses, saveToSystem: false)
            }
        }
    }

    // Deleting

    public func delete(_ contactToDelete: Contact) {
        print("Deleting contact")
        assert(Thread.isMainThread)

        // Delete the contact in our own local store
        setContacts(contacts.filter { contact in
            contact.id != contactToDelete.id
        })

        // Sync this deletion with the system
        let contact = try! store.unifiedContact(withIdentifier: contactToDelete.id, keysToFetch: [])
        let req = CNSaveRequest()
        let mutableContact = contact.mutableCopy() as! CNMutableContact
        req.delete(mutableContact)
        try! store.execute(req)
    }

    // Spotlight

    private func registerContactsWithSpotlight(_ contacts: [Contact]) async {
        let searchIndex = CSSearchableIndex.default();
        try! await searchIndex.deleteAllSearchableItems()

        var items: [CSSearchableItem] = []
        for contact in contacts {
            let attributeSet = CSSearchableItemAttributeSet(contentType: .contact)
            attributeSet.displayName = contact.displayName
            attributeSet.thumbnailData = contact.thumbnailImageData

            let item = CSSearchableItem(
                uniqueIdentifier: contact.id,
                domainIdentifier: "com.ryangomba.people.contacts",
                attributeSet: attributeSet
            )
            items.append(item)
        }

        try! await searchIndex.indexSearchableItems(items)
    }

}
