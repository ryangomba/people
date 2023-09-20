import UIKit

class NetworkImageView: UIImageView {

    public var url: String? {
        didSet {
            loadImage()
        }
    }

    private func loadImage() {
        if let urlString = url {
            let request = URLRequest(url: URL(string: urlString)!, cachePolicy: .returnCacheDataElseLoad)
            if let cachedResponse = URLCache.shared.cachedResponse(for: request) {
                setImageData(cachedResponse.data, forURLString: urlString)
            } else {
                image = nil
                Task { [weak self] in
                    if let (data, _) = try? await URLSession.shared.data(for: request) {
                        DispatchQueue.main.async {
                            self?.setImageData(data, forURLString: urlString)
                        }
                    } else {
                        print("Error loading image")
                    }
                }
            }
        } else {
            image = nil
        }
    }

    private func setImageData(_ imageData: Data?, forURLString urlString: String) {
        if urlString != url {
            return
        }
        if let imageData = imageData {
            image = UIImage(data: imageData)!
        } else {
            image = nil
        }
    }

}
