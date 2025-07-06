import UIKit

class ImageSelectionViewController: UIViewController {
    
    private let viewModel = ImageSelectionViewModel()
    
    var gridSize: Int = 4
    
    // MARK: - UI Components
    private let segmentedControl = UISegmentedControl(items: ["gallery.bundled".localized, "gallery.photos".localized])
    private let collectionView: UICollectionView
    private let addPhotoButton = UIButton(type: .system)
    private let loadingIndicator = UIActivityIndicatorView(style: .medium)
    
    private let cellIdentifier = "ImageCell"
    private var currentSegmentIndex = 0
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 10
        layout.minimumLineSpacing = 10
        layout.sectionInset = UIEdgeInsets(top: 10, left: 20, bottom: 10, right: 20)
        
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViewModel()
        setupUI()
        setupConstraints()
        loadInitialData()
    }
    
    deinit {
        viewModel.delegate = nil
    }
    
    private func setupViewModel() {
        viewModel.delegate = self
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "gallery.title".localized
        
        // Navigation items
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "common.back".localized, style: .plain, target: self, action: #selector(backTapped))
        
        // Segmented Control
        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(segmentedControl)
        
        // Collection View
        collectionView.backgroundColor = .systemBackground
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(ImageCollectionViewCell.self, forCellWithReuseIdentifier: cellIdentifier)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(collectionView)
        
        // Add Photo Button
        addPhotoButton.setTitle("Add Photo", for: .normal)
        addPhotoButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        addPhotoButton.backgroundColor = .systemBlue
        addPhotoButton.setTitleColor(.white, for: .normal)
        addPhotoButton.layer.cornerRadius = 12
        addPhotoButton.addTarget(self, action: #selector(addPhotoTapped), for: .touchUpInside)
        addPhotoButton.translatesAutoresizingMaskIntoConstraints = false
        addPhotoButton.isHidden = true
        view.addSubview(addPhotoButton)
        
        // Loading Indicator
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(loadingIndicator)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Segmented Control
            segmentedControl.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            segmentedControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            segmentedControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            segmentedControl.heightAnchor.constraint(equalToConstant: 32),
            
            // Collection View
            collectionView.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 10),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: addPhotoButton.topAnchor, constant: -10),
            
            // Add Photo Button
            addPhotoButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            addPhotoButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            addPhotoButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            addPhotoButton.heightAnchor.constraint(equalToConstant: 44),
            
            // Loading Indicator
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    private func loadInitialData() {
        loadingIndicator.startAnimating()
        viewModel.loadBundledImages()
    }
    
    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func segmentChanged() {
        currentSegmentIndex = segmentedControl.selectedSegmentIndex
        
        if currentSegmentIndex == 1 {
            addPhotoButton.isHidden = false
            loadingIndicator.startAnimating()
            viewModel.loadUserPhotos()
        } else {
            addPhotoButton.isHidden = true
        }
        
        collectionView.reloadData()
    }
    
    @objc private func addPhotoTapped() {
        viewModel.showPhotoPicker(from: self)
    }
    
    private func showLoadingState() {
        loadingIndicator.startAnimating()
        collectionView.isUserInteractionEnabled = false
    }
    
    private func hideLoadingState() {
        loadingIndicator.stopAnimating()
        collectionView.isUserInteractionEnabled = true
    }
}

// MARK: - UICollectionViewDataSource
extension ImageSelectionViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if currentSegmentIndex == 0 {
            return viewModel.numberOfBundledImages
        } else {
            return viewModel.numberOfUserPhotos
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath) as! ImageCollectionViewCell
        
        cell.configure(with: nil)
        
        if currentSegmentIndex == 0 {
            viewModel.getBundledImageThumbnail(at: indexPath.item) { image in
                DispatchQueue.main.async {
                    if let currentCell = collectionView.cellForItem(at: indexPath) as? ImageCollectionViewCell {
                        currentCell.configure(with: image)
                    }
                }
            }
        } else {
            viewModel.getUserPhotoThumbnail(at: indexPath.item) { image in
                DispatchQueue.main.async {
                    if let currentCell = collectionView.cellForItem(at: indexPath) as? ImageCollectionViewCell {
                        currentCell.configure(with: image)
                    }
                }
            }
        }
        
        return cell
    }
}

// MARK: - UICollectionViewDelegate
extension ImageSelectionViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        showLoadingState()
        
        if currentSegmentIndex == 0 {
            viewModel.selectBundledImage(at: indexPath.item)
        } else {
            viewModel.selectUserPhoto(at: indexPath.item)
        }
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension ImageSelectionViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let padding: CGFloat = 20 + 10 + 10 + 20 // left + spacing + spacing + right
        let availableWidth = collectionView.frame.width - padding
        let itemWidth = availableWidth / 3
        return CGSize(width: itemWidth, height: itemWidth)
    }
}

// MARK: - ImageSelectionViewModelDelegate
extension ImageSelectionViewController: ImageSelectionViewModelDelegate {
    func didLoadBundledImages() {
        DispatchQueue.main.async { [weak self] in
            self?.hideLoadingState()
            self?.collectionView.reloadData()
        }
    }
    
    func didLoadUserPhotos() {
        DispatchQueue.main.async { [weak self] in
            self?.hideLoadingState()
            self?.collectionView.reloadData()
        }
    }
    
    func didSelectImage(_ image: UIImage, key: String, isUserImage: Bool) {
        hideLoadingState()
        
        let puzzleVC = PuzzleViewController()
        puzzleVC.setupNewGame(image: image, imageKey: key, isUserImage: isUserImage, gridSize: gridSize)
        navigationController?.pushViewController(puzzleVC, animated: true)
    }
    
    func didEncounterError(_ error: Error) {
        DispatchQueue.main.async { [weak self] in
            self?.hideLoadingState()
            self?.showErrorAlert(message: error.localizedDescription)
        }
    }
    
    func didRequestPhotoPermission() {
        DispatchQueue.main.async { [weak self] in
            self?.hideLoadingState()
            guard let self = self else { return }
            self.viewModel.showPermissionAlert(from: self)
        }
    }
}

// MARK: - ImageCollectionViewCell
class ImageCollectionViewCell: UICollectionViewCell {
    
    private let imageView = UIImageView()
    private let loadingIndicator = UIActivityIndicatorView(style: .medium)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
        loadingIndicator.startAnimating()
    }
    
    private func setupUI() {
        contentView.layer.cornerRadius = 8
        contentView.layer.masksToBounds = true
        contentView.backgroundColor = .systemGray6
        
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(imageView)
        
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.startAnimating()
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(loadingIndicator)
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            loadingIndicator.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }
    
    func configure(with image: UIImage?) {
        if let image = image {
            imageView.image = image
            loadingIndicator.stopAnimating()
        } else {
            imageView.image = nil
            loadingIndicator.startAnimating()
        }
    }
}

// MARK: - Error Handling
extension ImageSelectionViewController {
    private func showErrorAlert(message: String) {
        let alert = UIAlertController(title: "error.title".localized, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "common.ok".localized, style: .default))
        present(alert, animated: true)
    }
}