import UIKit

class PersonAvatarView: UIView {
    private static let avatarSize: CGFloat = 44
    private static let borderSize: CGFloat = 2
    private static let shadowSize: CGFloat = 2
    static let normalSize: CGFloat = avatarSize
    static let shadowedSize: CGFloat = avatarSize + borderSize * 2 + shadowSize * 2

    private let shadowed: Bool
    private let imageView = UIImageView()
    private let affinityImageView = UIImageView()

    var persons: [Person] = [] {
        didSet {
            if persons.isEmpty {
                imageView.image = nil
                affinityImageView.image = nil
            } else if persons != oldValue {
                imageView.image = drawImage()
                if (persons.count == 1) {
                    let person = persons.first!
                    if let iconName = person.affinity.info.smallIconName {
                        affinityImageView.image = .init(systemName: iconName)
                        affinityImageView.backgroundColor = .white
                        affinityImageView.tintColor = person.affinity.info.iconTintColor
                    } else {
                        affinityImageView.image = nil
                    }
                } else {
                    affinityImageView.image = nil
                }
            }
            affinityImageView.isHidden = affinityImageView.image == nil
        }
    }

    init(shadowed: Bool = false) {
        self.shadowed = shadowed
        super.init(frame: .zero)

        addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])

        if (!shadowed) {
            // HACK: make the option to show the affinity a top-level property
            affinityImageView.layer.cornerRadius = 8
            addSubview(affinityImageView)
            affinityImageView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                affinityImageView.widthAnchor.constraint(equalToConstant: 16),
                affinityImageView.heightAnchor.constraint(equalToConstant: 16),
                affinityImageView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: shadowed ? -1 : 2),
                affinityImageView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: shadowed ? -1 : 2),
            ])
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let path = UIBezierPath(roundedRect: bounds, cornerRadius: bounds.width / 2)
        if !path.contains(point) {
            return nil // ignore corners
        }
        return super.hitTest(point, with: event)
    }

    private func drawImage() -> UIImage {
        let screenScale = UIScreen.main.scale // TODO: actual?
        let fullSize = (shadowed ? Self.shadowedSize : Self.normalSize) * screenScale
        let borderColor = UIColor.white
        let borderWidth = shadowed ? Self.borderSize * screenScale : 0
        let shadowSize = shadowed ? Self.shadowSize * screenScale : 0

        let drawRect = CGRectMake(0, 0, fullSize, fullSize)
        UIGraphicsBeginImageContextWithOptions(drawRect.size, false, 0)

        let contentInset = shadowSize + borderWidth / 2
        let contentRect = CGRectInset(drawRect, contentInset, contentInset)
        let contentCornerRadius = contentRect.size.width / 2
        let contentPath = UIBezierPath(roundedRect: contentRect, cornerRadius: contentCornerRadius)

        let context = UIGraphicsGetCurrentContext()!
        context.setAllowsAntialiasing(true)
        context.setShouldAntialias(true)

        // Set fill and shadow
        context.saveGState()
        context.setFillColor(UIColor.blue.cgColor)
        if shadowed {
            context.setShadow(
                offset: .zero,
                blur: shadowSize,
                color: UIColor.black.cgColor
            )
        }
        contentPath.fill()
        context.restoreGState()

        // Draw image(s)
        context.saveGState()
        contentPath.addClip()
        func fillRectForRect(_ rect: CGRect, contentSize: CGSize) -> CGRect {
            let rectAspectRatio = rect.size.width / rect.size.height
            let contentAspectRatio = contentSize.width / contentSize.height
            if rectAspectRatio >= contentAspectRatio {
                let height = rect.width / contentAspectRatio
                let outset = (height - rect.height) / 2
                return CGRectInset(rect, 0, -outset)
            }
            let width = rect.height * contentAspectRatio
            let outset = (width - rect.width) / 2
            return CGRectInset(rect, -outset, 0)
        }
        var personRects: [CGRect] = []
        switch persons.count {
        case 0, 1:
            personRects = [contentRect]
        case 2:
            personRects = [
                CGRectMake(contentRect.origin.x, contentRect.origin.y, contentRect.width / 2, contentRect.height),
                CGRectMake(contentRect.origin.x + contentRect.width / 2, contentRect.origin.y, contentRect.width / 2, contentRect.height),
            ]
        case 3:
            personRects = [
                CGRectMake(contentRect.origin.x, contentRect.origin.y, contentRect.width / 2, contentRect.height / 2),
                CGRectMake(contentRect.origin.x, contentRect.origin.y + contentRect.height / 2, contentRect.width / 2, contentRect.height / 2),
                CGRectMake(contentRect.origin.x + contentRect.width / 2, contentRect.origin.y, contentRect.width / 2, contentRect.height),
            ]
        default:
            personRects = [
                CGRectMake(contentRect.origin.x, contentRect.origin.y, contentRect.width / 2, contentRect.height / 2),
                CGRectMake(contentRect.origin.x, contentRect.origin.y + contentRect.height / 2, contentRect.width / 2, contentRect.height / 2),
                CGRectMake(contentRect.origin.x + contentRect.width / 2, contentRect.origin.y, contentRect.width / 2, contentRect.height / 2),
                CGRectMake(contentRect.origin.x + contentRect.width / 2, contentRect.origin.y + contentRect.height / 2, contentRect.width / 2, contentRect.height / 2),
            ]
        }
        for (i, person) in persons.prefix(4).enumerated() {
            context.saveGState()
            let personRect = personRects[i]

            if persons.count > 1 {
                context.saveGState()
                borderColor.setStroke()
                context.setLineWidth(screenScale)
                context.stroke(personRect)
                context.restoreGState()
            }

            if let data = person.contact.thumbnailImageData {
                let personImage = UIImage(data: data)!
                let imageRect = fillRectForRect(personRect, contentSize: personImage.size)
                context.clip(to: personRect)
                personImage.draw(in: imageRect)
            } else {
                // TODO: draw initials
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.alignment = .center
                let fontSize = personRect.width * 0.5
                var font = UIFont.systemFont(ofSize: fontSize, weight: .bold)
                if let descriptor = font.fontDescriptor.withDesign(.rounded) {
                    font = UIFont(descriptor: descriptor, size: fontSize)
                }
                let attrs = [
                    NSAttributedString.Key.font: font,
                    NSAttributedString.Key.paragraphStyle: paragraphStyle,
                    NSAttributedString.Key.foregroundColor: UIColor.white
                ]
                let string = person.contact.initials
                let vInset = (personRect.height - font.lineHeight) / 2
                string.draw(
                    with: CGRectInset(personRect, 0, vInset),
                    options: .usesLineFragmentOrigin,
                    attributes: attrs,
                    context: nil
                )
            }
            context.restoreGState()
        }
        context.restoreGState()

        // Stroke the path
        if shadowed {
            context.saveGState()
            borderColor.setStroke()
            contentPath.lineWidth = borderWidth
            contentPath.stroke()
            context.restoreGState()
        }

        let renderedImage = UIGraphicsGetImageFromCurrentImageContext();

        UIGraphicsEndImageContext();

        return renderedImage!
    }

}
