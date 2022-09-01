import UIKit

struct Sizing {
    static func hairline() -> CGFloat {
        return 1 / UIScreen.main.scale;
    }
    static let tapTarget: CGFloat = 44
    static let cornerRadius: CGFloat = 10
    static let titleBarHeight: CGFloat = 36
    static let defaultListItemHeight: CGFloat = 64
}
        
struct Padding {
    static let text: CGFloat = 2
    static let superTight: CGFloat = 8
    static let tight: CGFloat = 12
    static let normal: CGFloat = 20
    static let large: CGFloat = 32
    static let superLarge: CGFloat = 64
}

struct FontSize {
    static let small: CGFloat = 15
    static let normal: CGFloat = 17
    static let title: CGFloat = 19
    static let bigTitle: CGFloat = 22
}

struct AnimationDuration {
    static let quick: CGFloat = 0.25
    static let normal: CGFloat = 0.33
    static let slow: CGFloat = 0.66
}
