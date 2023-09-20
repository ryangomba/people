import UIKit

class ProfilePhotosViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    private let contact: Contact
    private let collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
    private var imageResults: [GoogleImageResult] = []

    init(contact: Contact) {
        self.contact = contact
        super.init(nibName: nil, bundle: nil)

        updateGoogleImages(query: contact.fullName)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .customBackground

        let dismissAction = UIAction { _ in self.dismiss(animated: true) }
        let headerView = ProfilePhotosHeader(dismissAction: dismissAction)
        let queryChangedAction = UIAction() { _ in
            self.updateGoogleImages(query: headerView.searchQuery)
        }
        headerView.searchQuery = contact.fullName
        headerView.searchBox.textField.returnKeyType = .search
        headerView.searchBox.textField.addAction(queryChangedAction, for: .editingDidEndOnExit)
        view.addSubview(headerView)
        headerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])

        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(ProfilePhotoCollectionViewCell.self, forCellWithReuseIdentifier: ProfilePhotoCollectionViewCell.reuseIdentifier)
        view.addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    private func updateGoogleImages(query: String) {
        Task {
            imageResults = await GoogleImageSearcher.search(query)
            collectionView.reloadData()
        }
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return imageResults.count
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: Padding.normal, left: Padding.normal, bottom: Padding.normal, right: Padding.normal)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let size = (collectionView.frame.size.width - 2 * Padding.normal - 2 * Padding.tight) / 3
        return CGSize(width: size, height: size)
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ProfilePhotoCollectionViewCell.reuseIdentifier, for: indexPath) as! ProfilePhotoCollectionViewCell
        let imageResult = imageResults[indexPath.item]
        cell.photoView.remoteImage = imageResult
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath)! as! ProfilePhotoCollectionViewCell
        if let image = cell.photoView.image {
            // TODO: unify this logic with table view cell
            let data = image.jpegData(compressionQuality: 0.95)!
            app.contactRepository.updateContactPhoto(contact: contact, imageData: data)
            app.store.dispatch(ContactPhotoChanged(contact: contact))
            dismiss(animated: true)
        }
    }

}
