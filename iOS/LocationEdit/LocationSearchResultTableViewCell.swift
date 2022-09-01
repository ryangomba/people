import UIKit
import MapKit

class LocationSearchResultTableViewCell: UITableViewCell {
    static let reuseIdentifier = "locatonSearchResultCell"
    static let preferredHeight: CGFloat = Sizing.defaultListItemHeight
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear

        titleLabel.font = .systemFont(ofSize: FontSize.normal, weight: .semibold)
        contentView.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: Padding.tight),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Padding.normal),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Padding.normal),
        ])

        subtitleLabel.font = .systemFont(ofSize: FontSize.small)
        subtitleLabel.textColor = .gray
        contentView.addSubview(subtitleLabel)
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: Padding.text),
            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public var title = "" {
        didSet {
            titleLabel.text = title
        }
    }

    public var subtitle = "" {
        didSet {
            subtitleLabel.text = subtitle
        }
    }

}
