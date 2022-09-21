import Foundation

struct GoogleImageResult {
    let url: String
    let mimeType: String
    let size: CGSize
    let thumbnailURL: String
    let thumbnailSize: CGSize
}

private struct GoogleSearchResponseItemImage: Decodable {
    let contextLink: String
    let width: Int
    let height: Int
    let byteSize: Int
    let thumbnailLink: String
    let thumbnailHeight: Int
    let thumbnailWidth: Int
}

private struct GoogleSearchResponseItem: Decodable {
    let kind: String
    let title: String
    let htmlTitle: String
    let link: String
    let displayLink: String
    let snippet: String
    let htmlSnippet: String
    let mime: String
    let fileFormat: String
    let image: GoogleSearchResponseItemImage
}

private struct GoogleSearchResponse: Decodable {
    // kind
    // url
    // queries
    // context
    // searchInformation
    let items: [GoogleSearchResponseItem]
}

private func getSecret(_ key: String) -> String {
    let env = ProcessInfo.processInfo.environment
    if let envValue = env[key] {
        if !envValue.isEmpty {
            return envValue
        }
    }
    let info = Bundle.main.infoDictionary
    if let infoValue = info?[key] as? String {
        if !infoValue.isEmpty {
            return infoValue
        }
    }
    fatalError("Could not find secret for key: \(key)")
}

class GoogleImageSearcher {
    public static func search(_ query: String) async -> [GoogleImageResult] {
        var urlString = "https://customsearch.googleapis.com/customsearch/v1"
        urlString += "?key=\(getSecret("GOOGLE_SEARCH_KEY"))"
        urlString += "&cx=\(getSecret("GOOGLE_SEARCH_CX"))"
        urlString += "&searchType=image"
        // TODO: multiselect doesn't work
        // urlString += "&imgType=face,photo"
        urlString += "&q=" + query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        let url = URL(string: urlString)!
        var request = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad)
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else {
                print("Error while fetching data: \(response).")
                return []
            }
            let decodedResponse = try JSONDecoder().decode(GoogleSearchResponse.self, from: data)
            return decodedResponse.items.map { item in
                return GoogleImageResult(
                    url: item.link,
                    mimeType: item.mime,
                    size: CGSize(width: item.image.width, height: item.image.height),
                    thumbnailURL: item.image.thumbnailLink,
                    thumbnailSize: CGSize(width: item.image.thumbnailWidth, height: item.image.thumbnailHeight)
                )
            }
        } catch {
            print("Unexpected error: \(error).")
            return []
        }
    }
}
