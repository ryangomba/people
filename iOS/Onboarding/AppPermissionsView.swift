import UIKit

class AppPermissionsView: UIView {
    private var label = UILabel()
    private var button = UIButton(type: .system)
    private let currentButtonAction: UIAction? = nil

    var completed = false {
        didSet {
            button.isEnabled = !completed
        }
    }

    public func configure(text: String, buttonTitle: String, buttonAction: UIAction) {
        let attrString = NSMutableAttributedString(string: text)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        paragraphStyle.lineSpacing = 4
        attrString.addAttribute(.paragraphStyle, value:paragraphStyle, range:NSMakeRange(0, attrString.length))
        label.attributedText = attrString
        label.numberOfLines = .max
        addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: topAnchor),
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Padding.large),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Padding.large),
        ])

        var buttonConfig = UIButton.Configuration.borderedProminent()
        buttonConfig.buttonSize = .large
        buttonConfig.title = buttonTitle
        button.configuration = buttonConfig
        if let currentButtonAction = currentButtonAction {
            button.removeAction(currentButtonAction, for: .touchUpInside)
        }
        button.addAction(buttonAction, for: .touchUpInside)
        addSubview(button)
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            button.centerXAnchor.constraint(equalTo: centerXAnchor),
            button.topAnchor.constraint(equalTo: label.bottomAnchor, constant: Padding.large)
        ])
    }

}
