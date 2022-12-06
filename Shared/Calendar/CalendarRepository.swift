import Foundation

enum CalendarAuthStatus: Int {
    case notDetermined = 1
    case authorized = 2
    case denied = 3
}

class CalendarRepository: ObservableObject {
    public var authorizationStatus = getAuthorizationStatus()
//    private let store = CNContactStore()
    @Published var calendarEvents: [CalendarEvent] = []

    init() {
//        NotificationCenter.default.addObserver(self, selector: #selector(onForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
//        NotificationCenter.default.addObserver(self, selector: #selector(onContactStoreDidChange), name: .CNContactStoreDidChange, object: nil)
    }

    deinit {
//        NotificationCenter.default.removeObserver(self)
    }

    @objc
    func onForeground() {
        updateAuthorizationStatus()
    }

//    @objc
//    func onCalendarStoreDidChange(notification: NSNotification) {
//        if notification.userInfo?["CNNotificationOriginationExternally"] != nil {
//            print("System contacts did change")
//            self.sync()
//        }
//    }

    private static func getAuthorizationStatus() -> CalendarAuthStatus {
//        switch CNContactStore.authorizationStatus(for: .contacts) {
//        case .authorized:
//            return .authorized
//        case .denied, .restricted:
//            return .denied
//        case .notDetermined:
//            return .notDetermined
//        default:
//            // Assume authorized if we don't recognize the status
//            return .authorized
//        }
        return .notDetermined
    }

    private func updateAuthorizationStatus() {
//        let newAuthorizationStatus = Self.getAuthorizationStatus()
//        if newAuthorizationStatus != authorizationStatus {
//            authorizationStatus = newAuthorizationStatus
//            app.store.dispatch(ContactsAccessChanged(status: newAuthorizationStatus))
//            if newAuthorizationStatus == .authorized {
//                sync()
//            }
//        }
    }

    public func requestAuthorization() {
        assert(Thread.isMainThread)

//        store.requestAccess(for: .contacts) { ok, error in
//            DispatchQueue.main.async {
//                self.updateAuthorizationStatus()
//            }
//        }
    }

    public func sync() {
        assert(Thread.isMainThread)

        if authorizationStatus != .authorized {
            return
        }
        Task.init {
            let newCalendarEvents = await fetchSystemCalendarEvents()
            DispatchQueue.main.async {
                self.setCalendarEvents(newCalendarEvents)
            }
        }
    }

    // Fetching from system calendar

    private func fetchSystemCalendarEvents() async -> [CalendarEvent] {
//        var deviceContacts: [CNContact] = []
//        do {
//            let keysToFetch = [
//                CNContactGivenNameKey,
//                CNContactFamilyNameKey,
//                CNContactOrganizationNameKey,
//                CNContactNicknameKey,
//                CNContactThumbnailImageDataKey,
//                CNContactPostalAddressesKey
//            ] as [CNKeyDescriptor]
//            let request = CNContactFetchRequest(keysToFetch: keysToFetch)
//            try store.enumerateContacts(with: request) {
//                (contact, stop) in
//                deviceContacts.append(contact)
//            }
//        } catch {
//            print("Failed to fetch contact, error: \(error)")
//        }
//        let regex = try! NSRegularExpression(pattern: "\\_\\$\\!\\<(.+)\\>\\!\\$\\_", options: [])
//        func cleanedLabel(_ label: String?) -> String? {
//            if let label = label {
//                if (!label.isEmpty) {
//                    return regex.stringByReplacingMatches(in: label, options: [], range: NSRange(label.startIndex..<label.endIndex, in: label), withTemplate: "$1")
//                }
//            }
//            return label
//        }
//        return deviceContacts.enumerated().filter({ (_, deviceContact) in
//            return !(deviceContact.givenName + deviceContact.familyName).isEmpty
//        }).map({ (index, deviceContact) in
//            return Contact(
//                id: deviceContact.identifier,
//                givenName: deviceContact.givenName,
//                familyName: deviceContact.familyName,
//                companyName: deviceContact.organizationName,
//                nickname: deviceContact.nickname,
//                thumbnailImageData: deviceContact.thumbnailImageData,
//                postalAddresses: deviceContact.postalAddresses.map({ postalAddress in
//                    let value = PostalAddressValue(
//                        street: postalAddress.value.street,
//                        subLocality: postalAddress.value.subLocality,
//                        city: postalAddress.value.city,
//                        state: postalAddress.value.state,
//                        postalCode: postalAddress.value.postalCode,
//                        country: postalAddress.value.country
//                    )
//                    let coordinate = geocoder.getCachedGeocodedPostalAddress(value)?.coordinate
//                    return PostalAddress(
//                        label: cleanedLabel(postalAddress.label),
//                        value: value,
//                        coordinate: coordinate
//                    )
//                }),
//                affinity: affinityStore.get(deviceContact.identifier)
//            )
//        })
        return []
    }

//    private func updateCalendarEvents(_ newCalendarEvents: [CalendarEvent]) {
//        setContacts(contacts.map { contact in
//            if let newContact = newContacts.first(where: { c in
//                c.id == contact.id
//            }) {
//                return newContact
//            }
//            return contact
//        })
//    }

    private func setCalendarEvents(_ newCalendarEvents: [CalendarEvent]) {
//        let sortedContacts = newContacts.sorted()
//        if contacts == sortedContacts {
//            return
//        }
//        contacts = sortedContacts
//        app.store.dispatch(ContactsChanged(newContacts: contacts))
    }

    // Fetching

    public func getCalendarEvent(_ id: String) -> CalendarEvent {
        assert(Thread.isMainThread)

        return calendarEvents.first { c in c.id == id }!
    }

}
