import UIKit

extension UITableView {
    public func scrollToTop(animated: Bool = false) {
        scrollRectToVisible(.init(x: 0, y: 0, width: 1, height: 1), animated: animated)
    }
}
