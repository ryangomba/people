import UIKit

class ProfilePhotoCollectionViewCell: UICollectionViewCell {
    public static let reuseIdentifier = "profilePhotoCell"
    public let photoView = ProfilePhotoView(rounded: false)

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.addSubview(photoView)
        photoView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            photoView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            photoView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            photoView.topAnchor.constraint(equalTo: contentView.topAnchor),
            photoView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
