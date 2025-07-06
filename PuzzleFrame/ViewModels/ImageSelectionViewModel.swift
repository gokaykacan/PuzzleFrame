import UIKit
import Photos
import PhotosUI

protocol ImageSelectionViewModelDelegate: AnyObject {
    func didLoadBundledImages()
    func didLoadUserPhotos()
    func didSelectImage(_ image: UIImage, key: String, isUserImage: Bool)
    func didEncounterError(_ error: Error)
    func didRequestPhotoPermission()
}

class ImageSelectionViewModel: NSObject {
    
    weak var delegate: ImageSelectionViewModelDelegate?
    
    private var bundledImages: [String] = []
    private var userPhotos: [PHAsset] = []
    private var imageCache: [String: UIImage] = [:]
    private var thumbnailCache: [String: UIImage] = [:]
    
    var numberOfBundledImages: Int {
        return bundledImages.count
    }
    
    var numberOfUserPhotos: Int {
        return userPhotos.count
    }
    
    override init() {
        super.init()
        setupMemoryWarningHandler()
    }
    
    deinit {
        delegate = nil
        clearCaches()
    }
    
    private func setupMemoryWarningHandler() {
        MemoryManager.shared.addMemoryWarningHandler { [weak self] in
            self?.handleMemoryWarning()
        }
    }
    
    private func clearCaches() {
        imageCache.removeAll()
        thumbnailCache.removeAll()
    }
    
    private func handleMemoryWarning() {
        clearCaches()
    }
    
    func loadBundledImages() {
        bundledImages = Array(1...10).map { "image\($0)" }
        delegate?.didLoadBundledImages()
    }
    
    func loadUserPhotos() {
        PhotoKitManager.shared.requestPhotoLibraryPermission { [weak self] granted in
            if granted {
                self?.fetchUserPhotos()
            } else {
                self?.delegate?.didRequestPhotoPermission()
            }
        }
    }
    
    private func fetchUserPhotos() {
        PhotoKitManager.shared.fetchUserPhotos { [weak self] assets in
            DispatchQueue.main.async {
                self?.userPhotos = assets
                self?.delegate?.didLoadUserPhotos()
            }
        }
    }
    
    func getBundledImageThumbnail(at index: Int, completion: @escaping (UIImage?) -> Void) {
        guard index < bundledImages.count else {
            completion(nil)
            return
        }
        
        let imageKey = bundledImages[index]
        
        if let cachedThumbnail = thumbnailCache[imageKey] {
            completion(cachedThumbnail)
            return
        }
        
        if let cachedImage = CacheManager.shared.loadThumbnail(forKey: imageKey) {
            thumbnailCache[imageKey] = cachedImage
            completion(cachedImage)
            return
        }
        
        guard let bundledImage = UIImage(named: imageKey) else {
            completion(nil)
            return
        }
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            autoreleasepool {
                let imageData = bundledImage.pngData()
                let thumbnail = ImageUtilities.shared.createThumbnail(from: imageData)
                
                DispatchQueue.main.async {
                    if let thumbnail = thumbnail {
                        self?.thumbnailCache[imageKey] = thumbnail
                        CacheManager.shared.saveThumbnail(thumbnail, forKey: imageKey)
                    }
                    completion(thumbnail)
                }
            }
        }
    }
    
    func getUserPhotoThumbnail(at index: Int, completion: @escaping (UIImage?) -> Void) {
        guard index < userPhotos.count else {
            completion(nil)
            return
        }
        
        let asset = userPhotos[index]
        let thumbnailKey = "user_thumb_\(asset.localIdentifier)"
        
        if let cachedThumbnail = thumbnailCache[thumbnailKey] {
            completion(cachedThumbnail)
            return
        }
        
        PhotoKitManager.shared.loadThumbnailForAsset(asset, targetSize: CGSize(width: 150, height: 150)) { [weak self] image in
            if let image = image {
                self?.thumbnailCache[thumbnailKey] = image
            }
            completion(image)
        }
    }
    
    func selectBundledImage(at index: Int) {
        guard index < bundledImages.count else { return }
        
        let imageKey = bundledImages[index]
        
        if let cachedImage = imageCache[imageKey] {
            delegate?.didSelectImage(cachedImage, key: imageKey, isUserImage: false)
            return
        }
        
        if let cachedGameImage = CacheManager.shared.loadGameImage(forKey: imageKey) {
            imageCache[imageKey] = cachedGameImage
            delegate?.didSelectImage(cachedGameImage, key: imageKey, isUserImage: false)
            return
        }
        
        guard let bundledImage = UIImage(named: imageKey) else {
            delegate?.didEncounterError(NSError(domain: "ImageError", code: 1, userInfo: [NSLocalizedDescriptionKey: "error.image.load".localized]))
            return
        }
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            autoreleasepool {
                let processedImage = ImageUtilities.shared.resizeImage(bundledImage, to: CGSize(width: 1024, height: 1024))
                
                DispatchQueue.main.async {
                    guard let processedImage = processedImage else {
                        self?.delegate?.didEncounterError(NSError(domain: "ImageError", code: 2, userInfo: [NSLocalizedDescriptionKey: "error.image.process".localized]))
                        return
                    }
                    
                    self?.imageCache[imageKey] = processedImage
                    CacheManager.shared.saveGameImage(processedImage, forKey: imageKey)
                    self?.delegate?.didSelectImage(processedImage, key: imageKey, isUserImage: false)
                }
            }
        }
    }
    
    func selectUserPhoto(at index: Int) {
        guard index < userPhotos.count else { return }
        
        let asset = userPhotos[index]
        let imageKey = "user_\(asset.localIdentifier)"
        
        if let cachedImage = imageCache[imageKey] {
            delegate?.didSelectImage(cachedImage, key: imageKey, isUserImage: true)
            return
        }
        
        if let cachedUserImage = CacheManager.shared.loadUserImage(forKey: imageKey) {
            imageCache[imageKey] = cachedUserImage
            delegate?.didSelectImage(cachedUserImage, key: imageKey, isUserImage: true)
            return
        }
        
        PhotoKitManager.shared.loadFullImageForAsset(asset) { [weak self] image in
            guard let image = image else {
                self?.delegate?.didEncounterError(NSError(domain: "ImageError", code: 3, userInfo: [NSLocalizedDescriptionKey: "error.image.load".localized]))
                return
            }
            
            let imageKey = "user_\(asset.localIdentifier)"
            self?.imageCache[imageKey] = image
            CacheManager.shared.saveUserImage(image, forKey: imageKey)
            CacheManager.shared.cleanupOldUserImages()
            self?.delegate?.didSelectImage(image, key: imageKey, isUserImage: true)
        }
    }
    
    func showPhotoPicker(from viewController: UIViewController) {
        PhotoKitManager.shared.presentPhotoPickerFromViewController(viewController, delegate: self)
    }
    
    func showPermissionAlert(from viewController: UIViewController) {
        PhotoKitManager.shared.showPermissionAlert(from: viewController)
    }
}

// MARK: - PHPickerViewControllerDelegate
extension ImageSelectionViewModel: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        
        guard let result = results.first else { return }
        
        PhotoKitManager.shared.processSelectedPhoto(result) { [weak self] image in
            guard let image = image else {
                self?.delegate?.didEncounterError(NSError(domain: "ImageError", code: 4, userInfo: [NSLocalizedDescriptionKey: "error.image.process".localized]))
                return
            }
            
            let imageKey = "user_\(UUID().uuidString)"
            self?.imageCache[imageKey] = image
            CacheManager.shared.saveUserImage(image, forKey: imageKey)
            CacheManager.shared.cleanupOldUserImages()
            self?.delegate?.didSelectImage(image, key: imageKey, isUserImage: true)
        }
    }
}