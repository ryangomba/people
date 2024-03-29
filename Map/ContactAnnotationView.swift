import MapKit
import ReSwift

struct ContactAnnotationViewState: Equatable {
    var isSelected: Bool

    init(personLocation: PersonLocation, newState: AppState) {
        isSelected = newState.mapSelection?.personLocation == personLocation
    }
}

class ContactAnnotationView: MKAnnotationView, StoreSubscriber {
    static let reuseIdentifier = "contactAnnotation"

    private var currentState: ContactAnnotationViewState?
    private let avatarView = PersonAvatarView(shadowed: true)

    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)

        frame = CGRect(x: 0, y: 0, width: PersonAvatarView.shadowedSize, height: PersonAvatarView.shadowedSize)

        let tap = UITapGestureRecognizer()
        tap.addTarget(self, action: #selector(onTap))
        self.addGestureRecognizer(tap)

        addSubview(avatarView)
        avatarView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            avatarView.centerXAnchor.constraint(equalTo: centerXAnchor),
            avatarView.centerYAnchor.constraint(equalTo: centerYAnchor),
            avatarView.widthAnchor.constraint(equalToConstant: PersonAvatarView.shadowedSize),
            avatarView.heightAnchor.constraint(equalToConstant: PersonAvatarView.shadowedSize),
        ])
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    private func onTap() {
        if let contactAnnotation = annotation as? ContactAnnotation {
            app.store.dispatch(MapAnnotationSelected(
                coordinate: contactAnnotation.coordinate,
                personLocation: contactAnnotation.personLocation,
                isCluster: false
            ))
        }
    }

    override var annotation: MKAnnotation? {
        didSet {
            updateSelection(animated: false)
            app.store.unsubscribe(self)
            if let contactAnnotation = annotation as? ContactAnnotation {
                app.store.subscribe(self) { subscription in
                    return subscription.select { newState in
                        let personLocation = contactAnnotation.personLocation
                        return ContactAnnotationViewState(personLocation: personLocation, newState: newState)
                    }
                }
            }
        }
    }

    deinit {
        app.store.unsubscribe(self)
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        avatarView.persons = []
    }

    override func prepareForDisplay() {
        super.prepareForDisplay()

        if let annotation = annotation as? ContactAnnotation {
            avatarView.persons = [annotation.personLocation.person]
        }
    }

    func newState(state: ContactAnnotationViewState) {
        let prevState = currentState
        currentState = state

        if currentState != prevState {
            // TODO: why would we ever get a matching state? But it happens?
            updateSelection(animated: prevState != nil)
        }
    }

    func updateSelection(animated: Bool) {
        let isSelected = currentState?.isSelected ?? false

        func applyChanges() {
            let avatarViewScale = isSelected ? 1.5 : 1
            transform = .init(scaleX: avatarViewScale, y: avatarViewScale)
            zPriority = isSelected ? .defaultSelected : .defaultUnselected
        }

        if animated {
            UIView.animate(withDuration: AnimationDuration.slow, delay: 0, usingSpringWithDamping: 0.66, initialSpringVelocity: 0) {
                applyChanges()
            }
        } else {
            applyChanges()
        }
    }

}
