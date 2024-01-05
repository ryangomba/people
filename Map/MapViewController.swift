import UIKit
import MapKit
import ReSwift

struct MapViewControllerState: Equatable {
    var region: MKCoordinateRegion
    var locatedContacts: [PersonLocation] = []

    init(newState: AppState) {
        region = newState.mapRegion
        newState.persons.filter({ person in
            if (newState.mapSelectedAffinities.contains(person.affinity)) {
                return true
            }
            if (person.id == newState.mapSelection?.personLocation?.person.id) {
                // Show selected friend on map even if it doesn’t match affinity
                return true
            }
            return false
        }).forEach { person in
            person.contact.homeAddresses.forEach { postalAddress in
                if postalAddress.coordinate != nil {
                    locatedContacts.append(PersonLocation(person: person, postalAddress: postalAddress))
                }
            }
        }
    }
}

class MapViewController: UIViewController, StoreSubscriber, MKMapViewDelegate {
    private var mapView: MKMapView = MKMapView(frame: .zero)
    private let locateUserButton = UIButton(type: .roundedRect)
    private var currentState: MapViewControllerState?
    private var hasLocatedUser = false
    private var isChangingRegionProgramatically = false

    override func viewDidLoad() {
        super.viewDidLoad()

        mapView.showsUserLocation = true
        mapView.isPitchEnabled = false
        mapView.register(ContactAnnotationView.self, forAnnotationViewWithReuseIdentifier: ContactAnnotationView.reuseIdentifier)
        mapView.register(ContactClusterAnnotationView.self, forAnnotationViewWithReuseIdentifier: MKMapViewDefaultClusterAnnotationViewReuseIdentifier)
        mapView.delegate = self

        view.addSubview(mapView)
        mapView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            mapView.topAnchor.constraint(equalTo: view.topAnchor),
            mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mapView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])

        locateUserButton.addAction(UIAction { _ in self.onLocateUser() }, for: .touchUpInside)
        locateUserButton.backgroundColor = .customBackground
        locateUserButton.setImage(UIImage(systemName: "location"), for: .normal)
        locateUserButton.layer.cornerRadius = 10
        locateUserButton.layer.shadowColor = UIColor.black.cgColor
        locateUserButton.layer.shadowOpacity = 0.5
        locateUserButton.layer.shadowRadius = 20
        view.addSubview(locateUserButton)
        locateUserButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            locateUserButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: Padding.tight),
            locateUserButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -Padding.tight),
            locateUserButton.widthAnchor.constraint(equalToConstant: Sizing.tapTarget),
            locateUserButton.heightAnchor.constraint(equalToConstant: Sizing.tapTarget),
        ])
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        #if targetEnvironment(macCatalyst)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        navigationController?.setToolbarHidden(true, animated: animated)
        #endif

        app.store.subscribe(self) { subscription in
            return subscription.select(MapViewControllerState.init)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        app.store.unsubscribe(self)
    }

    func newState(state: MapViewControllerState) {
        let prevState = currentState
        currentState = state

        if state.region != prevState?.region && state.region != mapView.region {
            isChangingRegionProgramatically = true
            let distance = CLLocation.distance(from: mapView.region.center, to: state.region.center)
            let newCenterInExistingRegion = prevState?.region.contains(state.region.center) ?? false
            if !newCenterInExistingRegion && distance > 100000 { // about 62 miles
                self.mapView.setRegion(state.region, animated: false)
            } else {
                UIView.animate(withDuration: AnimationDuration.normal) {
                    self.mapView.setRegion(state.region, animated: true)
                }
            }
        }
        if state.locatedContacts != prevState?.locatedContacts {
            updateContactAnnotations(locatedContacts: state.locatedContacts)
        }
    }

    private func updateContactAnnotations(locatedContacts: [PersonLocation]) {
        let existingAnnotations = mapView.annotations.filter { annotation in
            return annotation is ContactAnnotation
        } as! [ContactAnnotation]

        let annotationsToRemove = existingAnnotations.filter { existingAnnotation in
            return !locatedContacts.contains(existingAnnotation.personLocation)
        }

        let existingPersonLocations = existingAnnotations.map { $0.personLocation }
        let annotationsToUpdate = locatedContacts.filter { personLocation in
            return !existingPersonLocations.contains(personLocation)
        }.map { personLocation in
            ContactAnnotation(personLocation)
        }

        print("Removing \(annotationsToRemove.count) annotations and updating \(annotationsToUpdate.count)")
        mapView.removeAnnotations(annotationsToRemove)
        mapView.addAnnotations(annotationsToUpdate)
    }

    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        if !hasLocatedUser {
            hasLocatedUser = true
            app.store.dispatch(MapRegionChanged(region: MKCoordinateRegion(
                center: focusedCoordinateToMapCenter(userLocation.coordinate, for: mapView.region.span),
                span: mapView.region.span
            )))
        }
    }

    func mapView(_ mapView: MKMapView, didFailToLocateUserWithError error: Error) {
        //
    }

    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        // Only dispatch action when map moves via user interaction
        if isChangingRegionProgramatically {
            isChangingRegionProgramatically = false
        } else {
            if mapView.region.center != currentState?.region.center {
                app.store.dispatch(MapRegionChanged(region: mapView.region))
            }
        }
    }

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        switch annotation {
        case let annotation as ContactAnnotation:
            let view = mapView.dequeueReusableAnnotationView(withIdentifier: ContactAnnotationView.reuseIdentifier, for: annotation)
            view.clusteringIdentifier = "\(annotation.coordinate.latitude),\(annotation.coordinate.longitude)"
            view.displayPriority = .required
            return view
        case let annotation as MKClusterAnnotation:
            let view = mapView.dequeueReusableAnnotationView(withIdentifier: MKMapViewDefaultClusterAnnotationViewReuseIdentifier, for: annotation)
            view.displayPriority = .required
            return view
        default:
            return nil
        }
    }

    func mapView(_ mapView: MKMapView, didSelect annotation: MKAnnotation) {
        // We want the source of truth state to be in our app state, not managed by the map view
        mapView.deselectAnnotation(annotation, animated: false)
    }

    private func onLocateUser() {
        let userLocation = mapView.userLocation.coordinate
        if userLocation != CLLocationCoordinate2D() {
            app.store.dispatch(FocusUserLocation(coordinate: userLocation))
        }
    }

}
