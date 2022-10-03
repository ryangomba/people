import UIKit
import ReSwift

struct ContactIngestionViewControllerState: Equatable {
    var geocoderQueueCount: Int

    init(newState: AppState) {
        geocoderQueueCount = newState.geocoderQueueCount
    }
}

class ContactIngestionViewController: UIViewController, StoreSubscriber {
    private var currentState: ContactIngestionViewControllerState?
    private var titleLabel: UILabel = UILabel()
    private var subtitleLabel: UILabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .customBackground

        titleLabel.text = "Locating contacts"
        titleLabel.font = .systemFont(ofSize: FontSize.bigTitle, weight: .bold)
        view.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])

        view.addSubview(subtitleLabel)
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            subtitleLabel.centerXAnchor.constraint(equalTo: titleLabel.centerXAnchor),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: Padding.normal),
        ])

        updateLabels()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        app.store.subscribe(self) { subscription in
            return subscription.select(ContactIngestionViewControllerState.init)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        app.store.unsubscribe(self)
    }

    func newState(state: ContactIngestionViewControllerState) {
        currentState = state
        updateLabels()
    }

    private func updateLabels() {
        let count = currentState?.geocoderQueueCount ?? 0
        if count > 0 {
            subtitleLabel.text = "\(count) remaining"
        } else {
            subtitleLabel.text = "Finished"
        }
    }

}
