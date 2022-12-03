import Foundation

private struct PersonSearchResult {
    let person: Person
    let score: Int
}

extension Person {
    var searchString: String {
        var components: [String] = []
        if !contact.nickname.isEmpty {
            components.append(contact.nickname)
        }
        if !contact.givenName.isEmpty {
            components.append(contact.givenName)
        }
        if !contact.familyName.isEmpty {
            components.append(contact.familyName)
        }
        return components.joined(separator: " ").lowercased()
    }
}

extension [Person] {
    func search(query rawQuery: String) -> Self {
        let query = rawQuery.lowercased()
        return map { person in
            let searchString = person.searchString
            var score = 0
            if query.isEmpty {
                score = 1 // just needs to be non-zero
            } else if let index = searchString.range(of: query)?.lowerBound {
                if index == searchString.startIndex {
                    score = 100
                } else {
                    let prevIndex = searchString.index(index, offsetBy: -1)
                    let prevChar = searchString[prevIndex]
                    if prevChar == Character(" ") {
                        score = 10
                    } else {
                        score = 1
                    }
                }
            }
            return PersonSearchResult(person: person, score: score)
        }.filter({ searchResult in
            return searchResult.score > 0
        }).sorted(by: { r1, r2 in
            if r1.score != r2.score {
                return r1.score > r2.score
            }
            return r1.person < r2.person
        }).map({ result in
            return result.person
        })
    }
}
