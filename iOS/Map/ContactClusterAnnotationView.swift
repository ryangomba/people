import MapKit
import ReSwift

struct ContactClusterAnnotationViewState: Equatable {
    var isSelected: Bool
    var selectedContactLocation: ContactLocation?

    init(coordinate: CLLocationCoordinate2D, newState: AppState) {
        isSelected = newState.selection?.coordinate == coordinate
        if isSelected {
            selectedContactLocation = newState.selection?.contactLocation
        }
    }
}

final class ContactClusterAnnotationView: MKAnnotationView, StoreSubscriber {
    public static let reuseIdentifier = "contactCluster"
    private var currentState: ContactClusterAnnotationViewState?
    private let avatarView = ContactAvatarView(shadowed: true)

    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)

        frame = CGRect(x: 0, y: 0, width: ContactAvatarView.shadowedSize, height: ContactAvatarView.shadowedSize)

        let tap = UITapGestureRecognizer()
        tap.addTarget(self, action: #selector(onAvatarViewTapped))
        avatarView.addGestureRecognizer(tap)

        addSubview(avatarView)
        avatarView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            avatarView.centerXAnchor.constraint(equalTo: centerXAnchor),
            avatarView.centerYAnchor.constraint(equalTo: centerYAnchor),
            avatarView.widthAnchor.constraint(equalToConstant: ContactAvatarView.shadowedSize),
            avatarView.heightAnchor.constraint(equalToConstant: ContactAvatarView.shadowedSize),
        ])
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func fixedAnnotationCoordinate(_ annotation: MKClusterAnnotation) -> CLLocationCoordinate2D {
        // Internal type conversion can cause the coordinate to
        // not match any of the member annotations!
        // TODO: manage our own clustering
        let multiplier: CGFloat = 1000000000
        return CLLocationCoordinate2D(
            latitude: (annotation.coordinate.latitude * multiplier).rounded() / multiplier,
            longitude: (annotation.coordinate.longitude * multiplier).rounded() / multiplier
        )
    }

    override var annotation: MKAnnotation? {
        didSet {
            updateSelection(animated: false)
            app.store.unsubscribe(self)
            if let annotation = annotation as? MKClusterAnnotation {
                app.store.subscribe(self) { subscription in
                    return subscription.select { newState in
                        return ContactClusterAnnotationViewState(coordinate: self.fixedAnnotationCoordinate(annotation), newState: newState)
                    }
                }
            }
        }
    }

    private var contactAnnotations: [ContactAnnotation] {
        if annotation != nil {
            guard let annotation = annotation as? MKClusterAnnotation else {
                fatalError("Using cluster view with wrong annotation type")
            }
            guard let memberAnnotations = annotation.memberAnnotations as? [ContactAnnotation] else {
                fatalError("Expected contact annotations as members")
            }
            return memberAnnotations.sorted {
                $0.contactLocation.contact < $1.contactLocation.contact
            }
        }
        return []
    }

    deinit {
        app.store.unsubscribe(self)
    }

    func newState(state: ContactClusterAnnotationViewState) {
        let prevState = currentState
        currentState = state

        if currentState != prevState {
            // TODO: why would we ever get a matching state? But it happens?
            updateSelection(animated: prevState != nil)
        }
    }

    private func updateSelection(animated: Bool) {
        let isSelected = currentState?.isSelected ?? false
        let selectedContactLocation = currentState?.selectedContactLocation

        if let selectedContactLocation = selectedContactLocation {
            avatarView.contacts = [selectedContactLocation.contact]
        } else {
            avatarView.contacts = contactAnnotations.map({ $0.contactLocation.contact })
        }

        func applyChanges() {
            zPriority = isSelected ? .defaultSelected : .defaultUnselected
            let avatarViewScale: CGFloat = isSelected ? 1.5 : 1
            avatarView.transform = .init(scaleX: avatarViewScale, y: avatarViewScale)
        }

        if animated {
            UIView.animate(withDuration: AnimationDuration.slow, delay: 0, usingSpringWithDamping: 0.66, initialSpringVelocity: 0) {
                applyChanges()
            }
        } else {
            applyChanges()
        }
    }

    @objc
    private func onAvatarViewTapped() {
        if let annotation = annotation as? MKClusterAnnotation {
            app.store.dispatch(MapAnnotationSelected(
                coordinate: fixedAnnotationCoordinate(annotation),
                contactLocation: nil,
                isCluster: true
            ))
        }
    }

}
