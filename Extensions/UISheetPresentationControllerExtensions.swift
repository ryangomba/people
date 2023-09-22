import UIKit

extension UISheetPresentationController.Detent.Identifier {
    public static let collapsed = UISheetPresentationController.Detent.Identifier("collapsed")
    public static let normal = UISheetPresentationController.Detent.Identifier("normal")
    public static let small = UISheetPresentationController.Detent.Identifier("small")
}

extension UISheetPresentationController.Detent {
    public static let collapsed = UISheetPresentationController.Detent.custom(identifier: .collapsed) { context in
        #if AFFINITES_ENABLED
        return 128
        #else
        return 72
        #endif
    }
    public static let normal = UISheetPresentationController.Detent.custom(identifier: .normal) { context in
        return (context.maximumDetentValue * 0.4).rounded()
    }
    public static let small = UISheetPresentationController.Detent.custom(identifier: .small) { context in
        return (context.maximumDetentValue * 0.4).rounded() // TODO: same as above
    }
}
