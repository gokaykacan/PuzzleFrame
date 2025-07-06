import UIKit
import Foundation

class MemoryManager {
    
    static let shared = MemoryManager()
    
    private var memoryWarningHandlers: [() -> Void] = []
    private var isMemoryWarningActive = false
    
    private init() {
        setupMemoryWarningNotifications()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func setupMemoryWarningNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMemoryWarning),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
    }
    
    @objc func handleMemoryWarning() {
        isMemoryWarningActive = true
        
        for handler in memoryWarningHandlers {
            handler()
        }
        
        CacheManager.shared.clearMemoryCache()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
            self?.isMemoryWarningActive = false
        }
    }
    
    func addMemoryWarningHandler(_ handler: @escaping () -> Void) {
        memoryWarningHandlers.append(handler)
    }
    
    func removeAllMemoryWarningHandlers() {
        memoryWarningHandlers.removeAll()
    }
    
    func releaseMemory() {
        CacheManager.shared.clearMemoryCache()
        
        if #available(iOS 13.0, *) {
            for scene in UIApplication.shared.connectedScenes {
                if let windowScene = scene as? UIWindowScene {
                    for window in windowScene.windows {
                        window.rootViewController?.viewDidDisappear(true)
                    }
                }
            }
        }
    }
    
    func prepareForForeground() {
        if isMemoryWarningActive {
            handleMemoryWarning()
        }
    }
    
    func getCurrentMemoryUsage() -> UInt64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            return info.resident_size
        }
        
        return 0
    }
    
    func getMemoryUsageString() -> String {
        let usage = getCurrentMemoryUsage()
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB]
        formatter.countStyle = .memory
        return formatter.string(fromByteCount: Int64(usage))
    }
    
    func isMemoryUsageHigh() -> Bool {
        let usage = getCurrentMemoryUsage()
        let maxMemory: UInt64 = 50 * 1024 * 1024 // 50MB threshold
        return usage > maxMemory
    }
    
    func performMemoryOptimizedOperation<T>(_ operation: () throws -> T) rethrows -> T {
        let result = try autoreleasepool {
            return try operation()
        }
        
        if isMemoryUsageHigh() {
            DispatchQueue.main.async { [weak self] in
                self?.handleMemoryWarning()
            }
        }
        
        return result
    }
}