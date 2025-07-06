import UIKit
import Photos
import PhotosUI

class PhotoKitManager: NSObject {
    
    static let shared = PhotoKitManager()
    
    private override init() {
        super.init()
    }
    
    // MARK: - Permission Management
    
    func requestPhotoLibraryPermission(completion: @escaping (Bool) -> Void) {
        if #available(iOS 14, *) {
            let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
            
            switch status {
            case .authorized, .limited:
                completion(true)
            case .notDetermined:
                PHPhotoLibrary.requestAuthorization(for: .readWrite) { newStatus in
                    DispatchQueue.main.async {
                        completion(newStatus == .authorized || newStatus == .limited)
                    }
                }
            case .denied, .restricted:
                completion(false)
            @unknown default:
                completion(false)
            }
        } else {
            let status = PHPhotoLibrary.authorizationStatus()
            
            switch status {
            case .authorized, .limited:
                completion(true)
            case .notDetermined:
                PHPhotoLibrary.requestAuthorization { newStatus in
                    DispatchQueue.main.async {
                        completion(newStatus == .authorized || newStatus == .limited)
                    }
                }
            case .denied, .restricted:
                completion(false)
            @unknown default:
                completion(false)
            }
        }
    }
    
    func getPhotoLibraryAuthorizationStatus() -> PHAuthorizationStatus {
        return PHPhotoLibrary.authorizationStatus()
    }
    
    // MARK: - Photo Selection
    
    func presentPhotoPickerFromViewController(_ viewController: UIViewController, delegate: PHPickerViewControllerDelegate) {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = 1
        configuration.preferredAssetRepresentationMode = .current
        
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = delegate
        
        viewController.present(picker, animated: true)
    }
    
    // MARK: - Photo Processing
    
    func processSelectedPhoto(_ result: PHPickerResult, completion: @escaping (UIImage?) -> Void) {
        let itemProvider = result.itemProvider
        
        if itemProvider.canLoadObject(ofClass: UIImage.self) {
            itemProvider.loadObject(ofClass: UIImage.self) { [weak self] image, error in
                guard let image = image as? UIImage else {
                    DispatchQueue.main.async { completion(nil) }
                    return
                }
                
                self?.processImageWithMemoryOptimization(image, completion: completion)
            }
        } else {
            DispatchQueue.main.async { completion(nil) }
        }
    }
    
    private func processImageWithMemoryOptimization(_ image: UIImage, completion: @escaping (UIImage?) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            autoreleasepool {
                let maxSize: CGFloat = 2048
                let processedImage = self.resizeImageIfNeeded(image, maxSize: maxSize)
                
                DispatchQueue.main.async {
                    completion(processedImage)
                }
            }
        }
    }
    
    private func resizeImageIfNeeded(_ image: UIImage, maxSize: CGFloat) -> UIImage {
        let size = image.size
        
        if size.width <= maxSize && size.height <= maxSize {
            return image
        }
        
        let ratio = min(maxSize / size.width, maxSize / size.height)
        let targetSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        
        UIGraphicsBeginImageContextWithOptions(targetSize, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: targetSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return resizedImage ?? image
    }
    
    // MARK: - Photo Library Access
    
    func fetchUserPhotos(completion: @escaping ([PHAsset]) -> Void) {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        fetchOptions.fetchLimit = 100
        
        let assets = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        var photoAssets: [PHAsset] = []
        
        assets.enumerateObjects { asset, _, _ in
            photoAssets.append(asset)
        }
        
        completion(photoAssets)
    }
    
    func loadThumbnailForAsset(_ asset: PHAsset, targetSize: CGSize, completion: @escaping (UIImage?) -> Void) {
        let imageManager = PHImageManager.default()
        let options = PHImageRequestOptions()
        options.deliveryMode = .opportunistic
        options.resizeMode = .fast
        options.isSynchronous = false
        
        imageManager.requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFill, options: options) { image, _ in
            DispatchQueue.main.async {
                completion(image)
            }
        }
    }
    
    func loadFullImageForAsset(_ asset: PHAsset, completion: @escaping (UIImage?) -> Void) {
        let imageManager = PHImageManager.default()
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.resizeMode = .none
        options.isSynchronous = false
        
        imageManager.requestImage(for: asset, targetSize: PHImageManagerMaximumSize, contentMode: .default, options: options) { [weak self] image, _ in
            guard let image = image else {
                DispatchQueue.main.async { completion(nil) }
                return
            }
            
            self?.processImageWithMemoryOptimization(image, completion: completion)
        }
    }
    
    // MARK: - Permission Helper
    
    func showPermissionAlert(from viewController: UIViewController) {
        let alert = UIAlertController(
            title: "permission.photos.title".localized,
            message: "permission.photos.message".localized,
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "permission.photos.settings".localized, style: .default) { _ in
            self.openSettings()
        })
        
        alert.addAction(UIAlertAction(title: "permission.photos.cancel".localized, style: .cancel))
        
        viewController.present(alert, animated: true)
    }
    
    private func openSettings() {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else { return }
        
        if UIApplication.shared.canOpenURL(settingsUrl) {
            UIApplication.shared.open(settingsUrl)
        }
    }
}