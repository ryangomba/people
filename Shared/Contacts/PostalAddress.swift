import CoreLocation
import Contacts

struct PostalAddressValue: Equatable {
    var street: String = ""
    var subLocality: String = ""
    var city: String = ""
    var state: String = ""
    var postalCode: String = ""
    var country: String = ""
}

extension PostalAddressValue {
    var cnValue: CNPostalAddress {
        let postalAddress = CNMutablePostalAddress()
        postalAddress.street = street
        postalAddress.subLocality = subLocality
        postalAddress.city = city
        postalAddress.state = state
        postalAddress.postalCode = postalCode
        postalAddress.country = country
        return postalAddress
    }
    var id: String {
        // This needs to be stable, e.g. for the geocoder
        return [
            street,
            subLocality,
            city,
            state,
            postalCode,
            country
        ].filter { component in
            !component.isEmpty
        }.joined(separator: ", ")
    }
    var formattedStreet: String? {
        if !street.isEmpty {
            return street.replacingOccurrences(of: "\n", with: " ")
        } else if !subLocality.isEmpty {
            return subLocality
        }
        return nil
    }
    var formattedSingleLine: String {
        return formattedMultiLine
            .replacingOccurrences(of: "\n", with: ", ")
    }
    var formattedMultiLine: String {
        var components: [String] = []
        if let street = formattedStreet {
            components.append(street)
        }
        if let cityState = _formattedCityState(includePostalCode: true) {
            components.append(cityState)
        }
        if !country.isEmpty {
            components.append(country)
        }
        return components.joined(separator: "\n")
    }
    func _formattedCityState(includePostalCode: Bool) -> String? {
        var str = city
        if !state.isEmpty {
            if !str.isEmpty {
                str += ", "
            }
            str += state
        }
        if includePostalCode && !postalCode.isEmpty {
            if !str.isEmpty {
                str += " "
            }
            str += postalCode
        }
        return str.isEmpty ? nil : str
    }
    var formattedCityState: String? {
        return _formattedCityState(includePostalCode: false)
    }
    var queryString: String {
        return formattedMultiLine
            .replacingOccurrences(of: "\n", with: ",+")
            .replacingOccurrences(of: " ", with: "+")
    }
}

struct PostalAddress: Identifiable, Equatable {
    var label: String?
    var value: PostalAddressValue = PostalAddressValue()
    var coordinate: CLLocationCoordinate2D?
    var id: String {
        return "\(label ?? ""):\(CNPostalAddressFormatter.string(from: value.cnValue, style: .mailingAddress))"
    }
}

extension PostalAddress {
    static let homeLabel = "Home"
    var formattedLabel: String? {
        if let label = label {
            return label.prefix(1).uppercased() + label.lowercased().dropFirst()
        }
        return nil
    }
}

extension PostalAddress {
    var cnValue: CNLabeledValue<CNPostalAddress> {
        return CNLabeledValue(label: label, value: value.cnValue)
    }
}

extension [PostalAddress] {
    public var sameLocationSharedDescription: String {
        let values = self.map { $0.value }
        if let firstValue = values.first {
            if values.allSatisfy({ !$0.street.isEmpty }) {
                return firstValue.street
            }
            var subLocalitiesAllEqual = false
            var matchingSubLocality = ""
            let subLocalities = values.map({ $0.subLocality })
            for subLocality in subLocalities {
                if matchingSubLocality == "" || subLocality == matchingSubLocality {
                    matchingSubLocality = subLocality
                    subLocalitiesAllEqual = true
                } else {
                    subLocalitiesAllEqual = false
                }
            }
            if subLocalitiesAllEqual && matchingSubLocality != "" {
                return matchingSubLocality
            }
            if !firstValue.city.isEmpty {
                return firstValue.formattedCityState ?? firstValue.city
            }
        }
        return "Location"
    }
}
