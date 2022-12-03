import UIKit

class ContactProfilePhotoTableViewCell: UITableViewCell {
    private static let imageViewSize = PersonAvatarView.shadowedSize
    static let reuseIdentifier = "contactProfilePhotoCell"
    static let preferredHeight: CGFloat = imageViewSize + Padding.normal * 2
    let imageViews: [ProfilePhotoView]

    var contact: Contact? {
        didSet {
            Task {
                if let contact = contact {
                    await updateGoogleImages(contact: contact)
                }
            }
        }
    }

    deinit {
        // TODO:
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        var imageViews: [ProfilePhotoView] = []
        for _ in 0..<4 {
            imageViews.append(ProfilePhotoView(rounded: true))
        }
        self.imageViews = imageViews
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        for (i, imageView) in imageViews.enumerated() {
            contentView.addSubview(imageView)
            imageView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -Padding.normal),
                imageView.widthAnchor.constraint(equalToConstant: Self.imageViewSize),
                imageView.heightAnchor.constraint(equalToConstant: Self.imageViewSize),
                imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Padding.normal + CGFloat(i) * (Self.imageViewSize + Padding.tight))
            ])
            let tap = UITapGestureRecognizer(target: self, action: #selector(onImageViewTapped))
            imageView.addGestureRecognizer(tap)
            imageView.isUserInteractionEnabled = true
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        // TODO:
    }

    private func updateGoogleImages(contact contactToSearch: Contact) async {
        let results = await GoogleImageSearcher.search(contactToSearch.fullName)
        if contact?.id == contactToSearch.id {
            for (i, imageView) in imageViews.enumerated() {
                if results.count > i {
                    imageView.remoteImage = results[i]
                } else {
                    imageView.remoteImage = nil
                }
            }
        }
    }

    @objc
    func onImageViewTapped(_ tap: UITapGestureRecognizer) {
        guard let photoView = tap.view as? ProfilePhotoView else {
            return
        }
        if let contact = contact, let image = photoView.image {
            let data = image.jpegData(compressionQuality: 0.95)!
            app.contactRepository.updateContactPhoto(contact: contact, imageData: data)
            app.store.dispatch(ContactPhotoChanged(contact: contact))

            // TODO: use URL when possible, but sometimes we'll get errors fetching or the wrong MIME type back (e.g. HTML instead of an image)
            // TODO: show loading indicator
//            Task {
//                let url = URL(string: image.thumbnailURL)!
//                let request = URLRequest(url: url)
//                do {
//                    let (data, response) = try await URLSession.shared.data(for: request)
//                    guard (response as? HTTPURLResponse)?.statusCode == 200 else {
//                        print("Error while fetching image: \(response).")
//                        return
//                    }
//                    app.contactRepository.updateContactPhoto(contact: contact, imageData: data)
//                } catch {
//                    print("Unexpected error: \(error).")
//                }
//            }
        }
    }

}
