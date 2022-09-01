import UIKit

class ContactIngestionViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .customBackground

        let label = UILabel()
        label.text = "ingesting contacts"
        label.sizeToFit()
        view.addSubview(label)
    }
}
