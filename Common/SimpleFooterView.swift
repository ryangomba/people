import UIKit

class SimpleFooterView: UIView {
    private let label = UILabel()
    var text: String {
        get {
            if let text = label.text {
                return text;
            };
            return "";
        }
        set {
            label.text = newValue;
            sizeToFit();
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        label.numberOfLines = -1;
        label.font = .systemFont(ofSize: FontSize.normal);
        label.textColor = .secondaryLabel;
        label.textAlignment = .center;
        addSubview(label);
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Padding.normal),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Padding.normal),
            label.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func sizeToFit() {
        label.sizeToFit();
        frame.size.height = label.frame.height + Padding.superLarge;
    }

}
