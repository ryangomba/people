import UIKit

class SearchBox: UIView {
    private let searchIconView = UIImageView()
    let textField = UITextField()

    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = .secondarySystemFill
        layer.cornerRadius = Sizing.cornerRadius

        searchIconView.image = UIImage(systemName: "magnifyingglass")
        searchIconView.tintColor = .placeholderText
        searchIconView.sizeToFit()
        addSubview(searchIconView)
        searchIconView.translatesAutoresizingMaskIntoConstraints = false
        searchIconView.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        NSLayoutConstraint.activate([
            searchIconView.centerYAnchor.constraint(equalTo: centerYAnchor),
            searchIconView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Padding.tight),
        ])

        textField.placeholder = "Search"
        textField.clearButtonMode = .whileEditing
        textField.autocorrectionType = .no
        addSubview(textField)
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.setContentHuggingPriority(.defaultHigh, for: .vertical)
        NSLayoutConstraint.activate([
            textField.topAnchor.constraint(equalTo: topAnchor),
            textField.bottomAnchor.constraint(equalTo: bottomAnchor),
            textField.leadingAnchor.constraint(equalTo: searchIconView.trailingAnchor, constant: Padding.superTight),
            textField.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Padding.superTight),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func focus() {
        textField.becomeFirstResponder()
    }

    public func blur() {
        textField.resignFirstResponder()
    }

}
