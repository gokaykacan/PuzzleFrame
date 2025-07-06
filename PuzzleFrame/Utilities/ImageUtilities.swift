import UIKit
import ImageIO
import CoreGraphics
import UniformTypeIdentifiers

class ImageUtilities {
    
    static let shared = ImageUtilities()
    
    private init() {}
    
    // MARK: - Memory-Optimized Image Processing
    
    func downsampleImage(from url: URL, to pointSize: CGSize, scale: CGFloat = UIScreen.main.scale) -> UIImage? {
        let imageSourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, imageSourceOptions) else {
            return nil
        }
        
        let maxDimensionInPixels = max(pointSize.width, pointSize.height) * scale
        let downsampleOptions = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxDimensionInPixels
        ] as CFDictionary
        
        guard let downsampledImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, downsampleOptions) else {
            return nil
        }
        
        return UIImage(cgImage: downsampledImage)
    }
    
    func downsampleImage(from data: Data, to pointSize: CGSize, scale: CGFloat = UIScreen.main.scale) -> UIImage? {
        let imageSourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let imageSource = CGImageSourceCreateWithData(data as CFData, imageSourceOptions) else {
            return nil
        }
        
        let maxDimensionInPixels = max(pointSize.width, pointSize.height) * scale
        let downsampleOptions = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxDimensionInPixels
        ] as CFDictionary
        
        guard let downsampledImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, downsampleOptions) else {
            return nil
        }
        
        return UIImage(cgImage: downsampledImage)
    }
    
    func createThumbnail(from url: URL, size: CGSize = CGSize(width: 150, height: 150)) -> UIImage? {
        return downsampleImage(from: url, to: size)
    }
    
    func createThumbnail(from data: Data?, size: CGSize = CGSize(width: 150, height: 150)) -> UIImage? {
        guard let data = data else { return nil }
        return downsampleImage(from: data, to: size)
    }
    
    // MARK: - Image Resizing and Optimization
    
    func resizeImage(_ image: UIImage, to targetSize: CGSize, compressionQuality: CGFloat = 0.8) -> UIImage? {
        let size = image.size
        let widthRatio = targetSize.width / size.width
        let heightRatio = targetSize.height / size.height
        
        let newSize: CGSize
        if widthRatio > heightRatio {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio, height: size.height * widthRatio)
        }
        
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
    
    func compressImage(_ image: UIImage, quality: CGFloat = 0.8) -> Data? {
        return image.jpegData(compressionQuality: quality)
    }
    
    func processImageWithMemoryOptimization(_ image: UIImage, targetSize: CGSize, completion: @escaping (UIImage?) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            autoreleasepool {
                let processedImage = self.resizeImage(image, to: targetSize)
                DispatchQueue.main.async {
                    completion(processedImage)
                }
            }
        }
    }
    
    // MARK: - Image Validation
    
    func validateImageSize(_ image: UIImage) -> Bool {
        let maxSize: CGFloat = 4096
        return image.size.width <= maxSize && image.size.height <= maxSize
    }
    
    func getImageSize(from url: URL) -> CGSize? {
        guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil),
              let imageProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [CFString: Any],
              let width = imageProperties[kCGImagePropertyPixelWidth] as? CGFloat,
              let height = imageProperties[kCGImagePropertyPixelHeight] as? CGFloat else {
            return nil
        }
        return CGSize(width: width, height: height)
    }
    
    // MARK: - Memory-Aware Batch Processing
    
    func processBatchImages(_ images: [UIImage], targetSize: CGSize, completion: @escaping ([UIImage]) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            var processedImages: [UIImage] = []
            
            for image in images {
                autoreleasepool {
                    if let resizedImage = self.resizeImage(image, to: targetSize) {
                        processedImages.append(resizedImage)
                    }
                }
            }
            
            DispatchQueue.main.async {
                completion(processedImages)
            }
        }
    }
    
    // MARK: - Image Format Utilities
    
    func isImageFormatSupported(_ data: Data) -> Bool {
        guard let imageSource = CGImageSourceCreateWithData(data as CFData, nil) else {
            return false
        }
        
        guard let type = CGImageSourceGetType(imageSource) else { return false }
        let typeString = type as String
        let supportedTypes = [UTType.jpeg.identifier, UTType.png.identifier, UTType.heic.identifier, UTType.bmp.identifier, UTType.gif.identifier]
        
        return supportedTypes.contains(typeString)
    }
    
    func getImageFileSize(from url: URL) -> Int64? {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            return attributes[.size] as? Int64
        } catch {
            return nil
        }
    }
}