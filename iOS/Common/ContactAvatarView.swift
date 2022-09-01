import UIKit

class ContactAvatarView: UIView {
    private static let avatarSize: CGFloat = 44
    private static let borderSize: CGFloat = 2
    private static let shadowSize: CGFloat = 2
    static let normalSize: CGFloat = avatarSize
    static let shadowedSize: CGFloat = avatarSize + borderSize * 2 + shadowSize * 2

    private let shadowed: Bool
    private let imageView = UIImageView()

    var contacts: [Contact] = [] {
        didSet {
            if contacts.isEmpty {
                imageView.image = nil
            } else if contacts != oldValue {
                imageView.image = drawImage()
            }
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
        var contactRects: [CGRect] = []
        switch contacts.count {
        case 0, 1:
            contactRects = [contentRect]
        case 2:
            contactRects = [
                CGRectMake(contentRect.origin.x, contentRect.origin.y, contentRect.width / 2, contentRect.height),
                CGRectMake(contentRect.origin.x + contentRect.width / 2, contentRect.origin.y, contentRect.width / 2, contentRect.height),
            ]
        case 3:
            contactRects = [
                CGRectMake(contentRect.origin.x, contentRect.origin.y, contentRect.width / 2, contentRect.height / 2),
                CGRectMake(contentRect.origin.x, contentRect.origin.y + contentRect.height / 2, contentRect.width / 2, contentRect.height / 2),
                CGRectMake(contentRect.origin.x + contentRect.width / 2, contentRect.origin.y, contentRect.width / 2, contentRect.height),
            ]
        default:
            contactRects = [
                CGRectMake(contentRect.origin.x, contentRect.origin.y, contentRect.width / 2, contentRect.height / 2),
                CGRectMake(contentRect.origin.x, contentRect.origin.y + contentRect.height / 2, contentRect.width / 2, contentRect.height / 2),
                CGRectMake(contentRect.origin.x + contentRect.width / 2, contentRect.origin.y, contentRect.width / 2, contentRect.height / 2),
                CGRectMake(contentRect.origin.x + contentRect.width / 2, contentRect.origin.y + contentRect.height / 2, contentRect.width / 2, contentRect.height / 2),
            ]
        }
        for (i, contact) in contacts.prefix(4).enumerated() {
            context.saveGState()
            let contactRect = contactRects[i]

            if contacts.count > 1 {
                context.saveGState()
                borderColor.setStroke()
                context.setLineWidth(screenScale)
                context.stroke(contactRect)
                context.restoreGState()
            }

            if let data = contact.thumbnailImageData {
                let contactImage = UIImage(data: data)!
                let imageRect = fillRectForRect(contactRect, contentSize: contactImage.size)
                context.clip(to: contactRect)
                contactImage.draw(in: imageRect)
            } else {
                // TODO: draw initials
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.alignment = .center
                let fontSize = contactRect.width * 0.5
                var font = UIFont.systemFont(ofSize: fontSize, weight: .bold)
                if let descriptor = font.fontDescriptor.withDesign(.rounded) {
                    font = UIFont(descriptor: descriptor, size: fontSize)
                }
                let attrs = [
                    NSAttributedString.Key.font: font,
                    NSAttributedString.Key.paragraphStyle: paragraphStyle,
                    NSAttributedString.Key.foregroundColor: UIColor.white
                ]
                let string = contact.initials
                let vInset = (contactRect.height - font.lineHeight) / 2
                string.draw(
                    with: CGRectInset(contactRect, 0, vInset),
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
