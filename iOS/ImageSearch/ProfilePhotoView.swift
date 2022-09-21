import UIKit

class ProfilePhotoView: NetworkImageView {
    var rounded: Bool

    var remoteImage: GoogleImageResult? {
        didSet {
            self.url = remoteImage?.thumbnailURL
        }
    }

    init(rounded: Bool) {
        self.rounded = rounded
        super.init(frame: .zero)

        backgroundColor = .red
        contentMode = .scaleAspectFill
        layer.borderWidth = Sizing.hairline()
        layer.borderColor = UIColor.opaqueSeparator.cgColor
        clipsToBounds = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        layer.cornerRadius = rounded ? bounds.width / 2 : 0
    }

}
