import UIKit
import ReSwift

struct MapContactListHeaderState: Equatable {
    var selectedAffinities: [Affinity]
    var isSearching: Bool
    var searchQuery: String

    init(newState: AppState) {
        selectedAffinities = newState.mapSelectedAffinities
        isSearching = newState.mapIsSearching
        searchQuery = newState.mapSearchQuery
    }
}

class MapContactListHeader: UIView, UITextFieldDelegate, StoreSubscriber {
    private var currentState: MapContactListHeaderState?
    private let titleButton = UIButton()
    private let searchButton = UIButton(type: .system)
    private let cancelButton = UIButton(type: .system)
    private let dismissButton = UIButton(type: .system)
    private let searchBox = SearchBox(frame: .zero)

    init() {
        super.init(frame: .zero)

        setContentHuggingPriority(.defaultHigh, for: .vertical)

        titleButton.titleLabel?.font = .systemFont(ofSize: FontSize.title, weight: .bold)
        addSubview(titleButton)
        titleButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            titleButton.centerYAnchor.constraint(equalTo: centerYAnchor, constant: 2),
            titleButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Padding.normal),
            titleButton.heightAnchor.constraint(equalToConstant: Sizing.titleBarHeight),
        ])

        let searchAction = UIAction() { _ in
            app.store.dispatch(MapStartSearching())
        }
        searchButton.addAction(searchAction, for: .touchUpInside)
        searchButton.setImage(.init(systemName: "magnifyingglass"), for: .normal)
        searchButton.sizeToFit()
        addSubview(searchButton)
        searchButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            searchButton.centerYAnchor.constraint(equalTo: titleButton.centerYAnchor),
            searchButton.trailingAnchor.constraint(equalTo: trailingAnchor),
            searchButton.widthAnchor.constraint(equalToConstant: searchButton.frame.width + Padding.normal * 2),
            searchButton.heightAnchor.constraint(equalToConstant: searchButton.frame.height + Padding.normal * 2),
        ])

        let cancelSearchAction = UIAction() { _ in
            app.store.dispatch(MapStopSearching())
        }
        cancelButton.addAction(cancelSearchAction, for: .touchUpInside)
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.sizeToFit()
        addSubview(cancelButton)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            cancelButton.centerYAnchor.constraint(equalTo: titleButton.centerYAnchor),
            cancelButton.trailingAnchor.constraint(equalTo: trailingAnchor),
            cancelButton.widthAnchor.constraint(equalToConstant: cancelButton.frame.width + Padding.normal * 2),
            cancelButton.heightAnchor.constraint(equalToConstant: cancelButton.frame.height + Padding.normal * 2),
        ])

        searchBox.textField.placeholder = "Search for a person or place"
        let editingChangedAction = UIAction() { action in
            let searchQuery = self.searchBox.textField.text ?? ""
            app.store.dispatch(MapSearchQueryChanged(searchQuery: searchQuery))
        }
        searchBox.textField.addAction(editingChangedAction, for: .editingChanged)
        searchBox.textField.delegate = self
        addSubview(searchBox)
        searchBox.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            searchBox.topAnchor.constraint(equalTo: topAnchor, constant: Padding.normal),
            searchBox.heightAnchor.constraint(equalToConstant: Sizing.titleBarHeight),
            searchBox.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Padding.normal),
            searchBox.trailingAnchor.constraint(equalTo: cancelButton.leadingAnchor),
        ])

        let dismissAction = UIAction { _ in app.store.dispatch(MapLocationDetailsDismissed()) }
        dismissButton.addAction(dismissAction, for: .touchUpInside)
        dismissButton.setImage(.init(systemName: "xmark.circle.fill"), for: .normal)
        dismissButton.tintColor = .gray
        dismissButton.sizeToFit()
        addSubview(dismissButton)
        dismissButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            dismissButton.centerYAnchor.constraint(equalTo: titleButton.centerYAnchor),
            dismissButton.trailingAnchor.constraint(equalTo: trailingAnchor),
            dismissButton.widthAnchor.constraint(equalToConstant: dismissButton.frame.width + Padding.normal * 2),
            dismissButton.heightAnchor.constraint(equalToConstant: dismissButton.frame.height + Padding.normal * 2),
        ])

        let hairlineView = UIView()
        hairlineView.backgroundColor = .separator
        addSubview(hairlineView)
        hairlineView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hairlineView.leadingAnchor.constraint(equalTo: leadingAnchor),
            hairlineView.trailingAnchor.constraint(equalTo: trailingAnchor),
            hairlineView.bottomAnchor.constraint(equalTo: bottomAnchor),
            hairlineView.heightAnchor.constraint(equalToConstant: Sizing.hairline()),
        ])

        app.store.subscribe(self) { subscription in
            return subscription.select(MapContactListHeaderState.init)
        }

        updateClusterTitle()
    }

    deinit {
        app.store.unsubscribe(self)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var clusterTitle: String? {
        didSet {
            // TODO: integrate with state, could cause problems
            updateClusterTitle()
        }
    }

    private func updateClusterTitle() {
        if let clusterTitle = clusterTitle {
            titleButton.setAttributedTitle(NSAttributedString(string: clusterTitle), for: .normal)
            searchButton.isHidden = true
            dismissButton.isHidden = false
        } else {
            var categoryName: String = ""
            var categorySuffix: String? = nil
            if (currentState?.selectedAffinities.count == Affinity.allCases.count) {
                categoryName = "Everyone"
            } else if (currentState?.selectedAffinities.count == 1) {
                categoryName = currentState!.selectedAffinities[0].info.title
                categorySuffix = "friends"
            } else if (currentState?.selectedAffinities.count == 0) {
                categoryName = "Empty search"
            } else {
                if let selectedAffinities = currentState?.selectedAffinities {
                    let sortedAffinities = selectedAffinities.sorted(by: { lhs, rhs in
                        lhs.rawValue > rhs.rawValue
                    })
                    var isDescending = true;
                    let firstMinAffinity = sortedAffinities.first!
                    var minAffinity = firstMinAffinity
                    sortedAffinities.forEach { affinity in
                        if (affinity.rawValue < minAffinity.rawValue - 1) {
                            isDescending = false
                        }
                        minAffinity = affinity
                    }
                    if (isDescending) {
                        categoryName = "\(firstMinAffinity.info.title) & closer"
                    } else {
                        categoryName = "Selected"
//                        categoryName = selectedAffinities.map({ affinity in
//                            affinity.info.title
//                        }).joined(separator: " & ")
                    }
                }
                categorySuffix = "friends"
            }
            let initialRange = NSRange(location: 0, length: categoryName.count)
            let attributedText = NSMutableAttributedString(string: categoryName)
            attributedText.setAttributes([
                .foregroundColor: UIColor.tintColor,
                .underlineColor: UIColor.tintColor,
                .underlineStyle: NSUnderlineStyle.single.rawValue,
            ], range: initialRange)

            let highlightedAttributedText = NSMutableAttributedString(attributedString: attributedText)
            highlightedAttributedText.setAttributes([
                .foregroundColor: UIColor.gray,
                .underlineColor: UIColor.gray,
                .underlineStyle: NSUnderlineStyle.single.rawValue,
            ], range: .init(location: 0, length: attributedText.length))

            var extraString = ""
            if let categorySuffix = categorySuffix {
                extraString += " \(categorySuffix)"
            }
            extraString += " nearby"
            attributedText.append(NSAttributedString(string: extraString))
            highlightedAttributedText.append(NSAttributedString(string: extraString))

#if AFFINITES_ENABLED
                titleButton.setAttributedTitle(attributedText, for: .normal)
                titleButton.setAttributedTitle(highlightedAttributedText, for: .highlighted)

                // HACK move
                let affinityMenu = UIMenu(title: "Filter to", children: Affinity.all().map({ affinityInfo in
                    let selected = currentState?.selectedAffinities.contains(affinityInfo.affinity) ?? false
                    return UIAction(title: "\(affinityInfo.title) friends", image: UIImage(systemName: selected ? affinityInfo.selectedIconName : affinityInfo.iconName), attributes: .keepsMenuPresented, state: selected ? .on : .off, handler: { (_) in
                        var newAffinities = self.currentState?.selectedAffinities ?? []
                        if (newAffinities.contains(affinityInfo.affinity)) {
                            if (newAffinities.count > 1) {
                                newAffinities.removeAll { affinity in affinity == affinityInfo.affinity }
                            }
                        } else {
                            newAffinities.append(affinityInfo.affinity)
                        }
                        app.store.dispatch(MapAffinityThresholdChanged(selectedAffinities: newAffinities))
                    })
                }))
                titleButton.menu = affinityMenu
                titleButton.showsMenuAsPrimaryAction = true
#else
                titleButton.setTitle(attributedText.string, for: .normal)
                titleButton.setTitleColor(UIColor.label, for: .normal)
                titleButton.menu = nil
#endif

            searchButton.isHidden = false
            dismissButton.isHidden = true
        }
    }

    override var intrinsicContentSize: CGSize {
        get {
            let height = Padding.normal + Sizing.titleBarHeight + Padding.tight;
            return CGSize(width: UIView.noIntrinsicMetric, height: height)
        }
    }

    func newState(state: MapContactListHeaderState) {
        let prevState = currentState
        currentState = state

        titleButton.isHidden = state.isSearching
        searchButton.isHidden = state.isSearching
        searchBox.isHidden = !state.isSearching
        cancelButton.isHidden = !state.isSearching
        if state.selectedAffinities != prevState?.selectedAffinities {
            updateClusterTitle()
        }
        if state.isSearching != prevState?.isSearching {
            if state.isSearching {
                searchBox.focus()
            } else {
                searchBox.blur()
            }
        }

        if state.searchQuery != prevState?.searchQuery {
            if state.searchQuery != searchBox.textField.text {
                searchBox.textField.text = state.searchQuery
            }
        }
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        let isSearching = currentState?.isSearching ?? false
        if !isSearching { // only send if this changes the state
            app.store.dispatch(MapStartSearching())
        }
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        let isSearching = currentState?.isSearching ?? false
        if isSearching { // only send if this changes the state
            app.store.dispatch(MapStopSearching())
        }
    }

}
