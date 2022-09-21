import UIKit

class ProfilePhotosHeader: UIView {
    private let cancelButton = UIButton(type: .system)
    public let searchBox = SearchBox()

    public var searchQuery: String {
        get {
            searchBox.textField.text ?? ""
        }
        set {
            searchBox.textField.text = newValue
        }
    }

    init(dismissAction: UIAction) {
        super.init(frame: .zero)

        setContentHuggingPriority(.defaultHigh, for: .vertical)

        cancelButton.addAction(dismissAction, for: .touchUpInside)
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.sizeToFit()
        addSubview(cancelButton)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        NSLayoutConstraint.activate([
            cancelButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            cancelButton.trailingAnchor.constraint(equalTo: trailingAnchor),
            cancelButton.widthAnchor.constraint(equalToConstant: cancelButton.frame.width + Padding.normal * 2),
            cancelButton.heightAnchor.constraint(equalToConstant: cancelButton.frame.height + Padding.normal * 2),
        ])

        searchBox.textField.placeholder = "Search for a location"
        addSubview(searchBox)
        searchBox.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            searchBox.centerYAnchor.constraint(equalTo: centerYAnchor),
            searchBox.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Padding.tight),
            searchBox.trailingAnchor.constraint(equalTo: cancelButton.leadingAnchor),
            searchBox.heightAnchor.constraint(equalToConstant: Sizing.titleBarHeight),
        ])

        let hairlineView = UIView()
        hairlineView.backgroundColor = .separator
        addSubview(hairlineView)
        hairlineView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hairlineView.leadingAnchor.constraint(equalTo: leadingAnchor),
            hairlineView.trailingAnchor.constraint(equalTo: trailingAnchor),
            hairlineView.bottomAnchor.constraint(equalTo: bottomAnchor),
            hairlineView.heightAnchor.constraint(equalToConstant: Sizing.hairline()),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        get {
            let height = Sizing.titleBarHeight + Padding.tight * 2;
            return CGSize(width: UIView.noIntrinsicMetric, height: height)
        }
    }

}
