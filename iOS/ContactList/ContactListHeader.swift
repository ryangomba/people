import UIKit
import ReSwift

struct ContactListHeaderState: Equatable {
    var isSearching: Bool
    var searchQuery: String

    init(newState: AppState) {
        isSearching = newState.isSearching
        searchQuery = newState.searchQuery
    }
}

class ContactListHeader: UIView, UITextFieldDelegate, StoreSubscriber {
    private var currentState: ContactListHeaderState?
    private let titleLabel = UILabel()
    private let filterButton = UIButton(type: .system)
    private let searchButton = UIButton(type: .system)
    private let cancelButton = UIButton(type: .system)
    private let dismissButton = UIButton(type: .system)
    private let searchBox = SearchBox(frame: .zero)

    init() {
        super.init(frame: .zero)

        setContentHuggingPriority(.defaultHigh, for: .vertical)

        titleLabel.font = .systemFont(ofSize: FontSize.bigTitle, weight: .bold)
        addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: Padding.normal),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Padding.normal),
            titleLabel.heightAnchor.constraint(equalToConstant: Sizing.titleBarHeight),
        ])

        filterButton.setImage(.init(systemName: "chevron.up.circle"), for: .normal)
        filterButton.sizeToFit()
        addSubview(filterButton)
        filterButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            filterButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            filterButton.leadingAnchor.constraint(equalTo: titleLabel.trailingAnchor, constant: Padding.tight),
        ])
        filterButton.isHidden = true // TODO: enable

        let searchAction = UIAction() { _ in
            app.store.dispatch(StartSearching())
        }
        searchButton.addAction(searchAction, for: .touchUpInside)
        searchButton.setImage(.init(systemName: "magnifyingglass"), for: .normal)
        searchButton.sizeToFit()
        addSubview(searchButton)
        searchButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            searchButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            searchButton.trailingAnchor.constraint(equalTo: trailingAnchor),
            searchButton.widthAnchor.constraint(equalToConstant: searchButton.frame.width + Padding.normal * 2),
            searchButton.heightAnchor.constraint(equalToConstant: searchButton.frame.height + Padding.normal * 2),
        ])

        let cancelSearchAction = UIAction() { _ in
            app.store.dispatch(StopSearching())
        }
        cancelButton.addAction(cancelSearchAction, for: .touchUpInside)
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.sizeToFit()
        addSubview(cancelButton)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            cancelButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            cancelButton.trailingAnchor.constraint(equalTo: trailingAnchor),
            cancelButton.widthAnchor.constraint(equalToConstant: cancelButton.frame.width + Padding.normal * 2),
            cancelButton.heightAnchor.constraint(equalToConstant: cancelButton.frame.height + Padding.normal * 2),
        ])

        searchBox.textField.placeholder = "Search for a person or place"
        let editingChangedAction = UIAction() { action in
            let searchQuery = self.searchBox.textField.text ?? ""
            app.store.dispatch(SearchQueryChanged(searchQuery: searchQuery))
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

        let dismissAction = UIAction { _ in app.store.dispatch(LocationDetailsDismissed()) }
        dismissButton.addAction(dismissAction, for: .touchUpInside)
        dismissButton.setImage(.init(systemName: "xmark.circle.fill"), for: .normal)
        dismissButton.tintColor = .gray
        dismissButton.sizeToFit()
        addSubview(dismissButton)
        dismissButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            dismissButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
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
            return subscription.select(ContactListHeaderState.init)
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
            titleLabel.text = clusterTitle
            searchButton.isHidden = true
            dismissButton.isHidden = false
        } else {
            titleLabel.text = "People"
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

    func newState(state: ContactListHeaderState) {
        let prevState = currentState
        currentState = state

        titleLabel.isHidden = state.isSearching
        searchButton.isHidden = state.isSearching
        searchBox.isHidden = !state.isSearching
        cancelButton.isHidden = !state.isSearching
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
            app.store.dispatch(StartSearching())
        }
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        let isSearching = currentState?.isSearching ?? false
        if isSearching { // only send if this changes the state
            app.store.dispatch(StopSearching())
        }
    }

}
