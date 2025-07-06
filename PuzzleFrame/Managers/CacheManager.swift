import UIKit
import Foundation

class CacheManager {
    
    static let shared = CacheManager()
    
    private let memoryCache = NSCache<NSString, UIImage>()
    private let maxCacheSize: Int64 = 50 * 1024 * 1024 // 50MB
    private let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    private let cachesPath = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
    
    private init() {
        setupMemoryCache()
        createCacheDirectories()
    }
    
    private func setupMemoryCache() {
        memoryCache.countLimit = 20
        memoryCache.totalCostLimit = 25 * 1024 * 1024 // 25MB
    }
    
    private func createCacheDirectories() {
        let directories = [
            cachesPath.appendingPathComponent("Thumbnails"),
            cachesPath.appendingPathComponent("GameImages"),
            documentsPath.appendingPathComponent("Images")
        ]
        
        for directory in directories {
            try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)
        }
    }
    
    // MARK: - Memory Cache
    
    func cacheImage(_ image: UIImage, forKey key: String) {
        let cost = Int(image.size.width * image.size.height * 4)
        memoryCache.setObject(image, forKey: key as NSString, cost: cost)
    }
    
    func getCachedImage(forKey key: String) -> UIImage? {
        return memoryCache.object(forKey: key as NSString)
    }
    
    func removeCachedImage(forKey key: String) {
        memoryCache.removeObject(forKey: key as NSString)
    }
    
    func clearMemoryCache() {
        memoryCache.removeAllObjects()
    }
    
    // MARK: - Disk Cache
    
    func saveThumbnail(_ image: UIImage, forKey key: String) {
        let url = cachesPath.appendingPathComponent("Thumbnails").appendingPathComponent("\(key).jpg")
        saveImageToDisk(image, at: url, quality: 0.8)
    }
    
    func loadThumbnail(forKey key: String) -> UIImage? {
        let url = cachesPath.appendingPathComponent("Thumbnails").appendingPathComponent("\(key).jpg")
        return loadImageFromDisk(at: url)
    }
    
    func saveGameImage(_ image: UIImage, forKey key: String) {
        let url = cachesPath.appendingPathComponent("GameImages").appendingPathComponent("\(key).jpg")
        saveImageToDisk(image, at: url, quality: 0.8)
    }
    
    func loadGameImage(forKey key: String) -> UIImage? {
        let url = cachesPath.appendingPathComponent("GameImages").appendingPathComponent("\(key).jpg")
        return loadImageFromDisk(at: url)
    }
    
    func saveUserImage(_ image: UIImage, forKey key: String) {
        let url = documentsPath.appendingPathComponent("Images").appendingPathComponent("\(key).jpg")
        saveImageToDisk(image, at: url, quality: 0.7)
    }
    
    func loadUserImage(forKey key: String) -> UIImage? {
        let url = documentsPath.appendingPathComponent("Images").appendingPathComponent("\(key).jpg")
        return loadImageFromDisk(at: url)
    }
    
    private func saveImageToDisk(_ image: UIImage, at url: URL, quality: CGFloat) {
        DispatchQueue.global(qos: .utility).async {
            if let data = image.jpegData(compressionQuality: quality) {
                try? data.write(to: url)
            }
        }
    }
    
    private func loadImageFromDisk(at url: URL) -> UIImage? {
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        return UIImage(contentsOfFile: url.path)
    }
    
    // MARK: - Cache Management
    
    func getUserImages() -> [String] {
        let userImagesPath = documentsPath.appendingPathComponent("Images")
        do {
            let files = try FileManager.default.contentsOfDirectory(at: userImagesPath, includingPropertiesForKeys: nil)
            return files.map { $0.deletingPathExtension().lastPathComponent }
        } catch {
            return []
        }
    }
    
    func deleteUserImage(forKey key: String) {
        let url = documentsPath.appendingPathComponent("Images").appendingPathComponent("\(key).jpg")
        try? FileManager.default.removeItem(at: url)
    }
    
    func cleanupOldUserImages() {
        let userImagesPath = documentsPath.appendingPathComponent("Images")
        do {
            let files = try FileManager.default.contentsOfDirectory(at: userImagesPath, includingPropertiesForKeys: [.contentModificationDateKey])
            
            if files.count > 10 {
                let sortedFiles = files.sorted { file1, file2 in
                    guard let date1 = try? file1.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate,
                          let date2 = try? file2.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate else {
                        return false
                    }
                    return date1 < date2
                }
                
                let filesToDelete = sortedFiles.prefix(files.count - 10)
                for file in filesToDelete {
                    try? FileManager.default.removeItem(at: file)
                }
            }
        } catch {
            print("Error cleaning up old user images: \(error)")
        }
    }
    
    func getCacheSize() -> Int64 {
        let paths = [
            cachesPath.appendingPathComponent("Thumbnails"),
            cachesPath.appendingPathComponent("GameImages"),
            documentsPath.appendingPathComponent("Images")
        ]
        
        var totalSize: Int64 = 0
        
        for path in paths {
            do {
                let files = try FileManager.default.contentsOfDirectory(at: path, includingPropertiesForKeys: [.fileSizeKey])
                for file in files {
                    let attributes = try file.resourceValues(forKeys: [.fileSizeKey])
                    totalSize += Int64(attributes.fileSize ?? 0)
                }
            } catch {
                continue
            }
        }
        
        return totalSize
    }
    
    func clearCacheIfNeeded() {
        let currentSize = getCacheSize()
        if currentSize > maxCacheSize {
            clearThumbnailCache()
            clearGameImageCache()
        }
    }
    
    private func clearThumbnailCache() {
        let thumbnailsPath = cachesPath.appendingPathComponent("Thumbnails")
        try? FileManager.default.removeItem(at: thumbnailsPath)
        try? FileManager.default.createDirectory(at: thumbnailsPath, withIntermediateDirectories: true, attributes: nil)
    }
    
    private func clearGameImageCache() {
        let gameImagesPath = cachesPath.appendingPathComponent("GameImages")
        try? FileManager.default.removeItem(at: gameImagesPath)
        try? FileManager.default.createDirectory(at: gameImagesPath, withIntermediateDirectories: true, attributes: nil)
    }
    
    func getCacheSizeString() -> String {
        let size = getCacheSize()
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }
}