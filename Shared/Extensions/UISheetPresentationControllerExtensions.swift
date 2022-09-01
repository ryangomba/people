import UIKit

extension UISheetPresentationController.Detent.Identifier {
    public static let collapsed = UISheetPresentationController.Detent.Identifier("collapsed")
    public static let normal = UISheetPresentationController.Detent.Identifier("normal")
    public static let small = UISheetPresentationController.Detent.Identifier("small")
}

extension UISheetPresentationController.Detent {
    public static let collapsed = UISheetPresentationController.Detent.custom(identifier: .collapsed) { context in
        return 54
    }
    public static let normal = UISheetPresentationController.Detent.custom(identifier: .normal) { context in
        return (context.maximumDetentValue * 0.4).rounded()
    }
    public static let small = UISheetPresentationController.Detent.custom(identifier: .small) { context in
        return (context.maximumDetentValue * 0.3).rounded()
    }
}
