import UIKit

class ContactDetailHeader: UIView {
    public var titleLabel = UILabel()
    private let dismissButton = UIButton(type: .system)

    init() {
        super.init(frame: .zero)

        setContentHuggingPriority(.defaultHigh, for: .vertical)

        titleLabel.font = .systemFont(ofSize: FontSize.bigTitle, weight: .bold)
        titleLabel.sizeToFit()
        addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Padding.normal),
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: Padding.normal),
        ])

        let dismissAction = UIAction { _ in app.store.dispatch(MapContactDetailsDismissed()) }
        dismissButton.addAction(dismissAction, for: .touchUpInside)
        dismissButton.setImage(.init(systemName: "xmark.circle.fill"), for: .normal)
        dismissButton.tintColor = .gray
        dismissButton.sizeToFit()
        addSubview(dismissButton)
        dismissButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            dismissButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            dismissButton.trailingAnchor.constraint(equalTo: trailingAnchor),
            dismissButton.widthAnchor.constraint(equalToConstant: dismissButton.frame.width + Padding.normal * 2),
            dismissButton.heightAnchor.constraint(equalToConstant: dismissButton.frame.height + Padding.normal * 2),
        ])
    }

    override var intrinsicContentSize: CGSize {
        get {
            let height = Padding.normal + Sizing.titleBarHeight;
            return CGSize(width: UIView.noIntrinsicMetric, height: height)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
