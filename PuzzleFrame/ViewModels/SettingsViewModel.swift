import UIKit

protocol SettingsViewModelDelegate: AnyObject {
    func didUpdateLanguage()
    func didUpdateSettings()
    func didEncounterError(_ error: Error)
}

class SettingsViewModel {
    
    weak var delegate: SettingsViewModelDelegate?
    
    private let userDefaults = UserDefaults.standard
    
    deinit {
        delegate = nil
    }
    
    // MARK: - Language Settings
    
    var currentLanguage: String {
        return LocalizationManager.shared.getCurrentLanguage()
    }
    
    var availableLanguages: [String] {
        return LocalizationManager.shared.getAvailableLanguages()
    }
    
    func getLanguageDisplayName(_ language: String) -> String {
        return LocalizationManager.shared.getLanguageDisplayName(language)
    }
    
    func setLanguage(_ language: String) {
        LocalizationManager.shared.setLanguage(language)
        delegate?.didUpdateLanguage()
    }
    
    // MARK: - Sound Settings
    
    var isSoundEnabled: Bool {
        get { 
            if userDefaults.object(forKey: "sound_enabled") == nil {
                userDefaults.set(true, forKey: "sound_enabled")
            }
            return userDefaults.bool(forKey: "sound_enabled") 
        }
        set {
            userDefaults.set(newValue, forKey: "sound_enabled")
            delegate?.didUpdateSettings()
        }
    }
    
    // MARK: - Haptic Feedback Settings
    
    var isHapticEnabled: Bool {
        get { 
            if userDefaults.object(forKey: "haptic_enabled") == nil {
                userDefaults.set(true, forKey: "haptic_enabled")
            }
            return userDefaults.bool(forKey: "haptic_enabled") 
        }
        set {
            userDefaults.set(newValue, forKey: "haptic_enabled")
            delegate?.didUpdateSettings()
        }
    }
    
    // MARK: - Timer Settings
    
    var isTimerEnabled: Bool {
        get { 
            if userDefaults.object(forKey: "timer_enabled") == nil {
                userDefaults.set(true, forKey: "timer_enabled")
            }
            return userDefaults.bool(forKey: "timer_enabled") 
        }
        set {
            userDefaults.set(newValue, forKey: "timer_enabled")
            delegate?.didUpdateSettings()
        }
    }
    
    // MARK: - High Scores
    
    func resetHighScores() {
        GameStateManager.shared.resetHighScores()
        delegate?.didUpdateSettings()
    }
    
    // MARK: - Photo Access
    
    func getPhotoAccessStatus() -> String {
        let status = PhotoKitManager.shared.getPhotoLibraryAuthorizationStatus()
        switch status {
        case .authorized, .limited:
            return "Granted"
        case .denied, .restricted:
            return "Denied"
        case .notDetermined:
            return "Not Requested"
        @unknown default:
            return "Unknown"
        }
    }
    
    func requestPhotoAccess() {
        PhotoKitManager.shared.requestPhotoLibraryPermission { granted in
            DispatchQueue.main.async { [weak self] in
                self?.delegate?.didUpdateSettings()
            }
        }
    }
    
    // MARK: - Cache Information
    
    func getCacheSize() -> String {
        return CacheManager.shared.getCacheSizeString()
    }
    
    func clearCache() {
        CacheManager.shared.clearMemoryCache()
        delegate?.didUpdateSettings()
    }
    
    // MARK: - App Version
    
    func getAppVersion() -> String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
    
    // MARK: - Memory Information
    
    func getMemoryUsage() -> String {
        return MemoryManager.shared.getMemoryUsageString()
    }
}