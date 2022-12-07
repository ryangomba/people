import Foundation

private struct ContactSearchResult {
    let contact: Contact
    let score: Int
}

extension [Contact] {
    func search(query rawQuery: String) -> Self {
        let query = rawQuery.lowercased()
        return map { contact in
            let searchString = contact.searchString
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
            return ContactSearchResult(contact: contact, score: score)
        }.filter({ searchResult in
            return searchResult.score > 0
        }).sorted(by: { r1, r2 in
            if r1.score != r2.score {
                return r1.score > r2.score
            }
            return r1.contact < r2.contact
        }).map({ result in
            return result.contact
        })
    }
}
