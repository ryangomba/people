import UIKit
import ReSwift

struct ActionViewControllerState: Equatable {
    var contacts: [Contact] = []

    init(newState: AppState) {
        //
    }
}

class ActionViewController: UIViewController, StoreSubscriber {
    private var currentState: ActionViewControllerState?

    init() {
        super.init(nibName: nil, bundle: nil)

        navigationItem.title = "Act"
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white
    }

    func newState(state: ActionViewControllerState) {
        let prevState = currentState
        currentState = state

        if state.contacts != prevState?.contacts {
            //
        }
    }
}
