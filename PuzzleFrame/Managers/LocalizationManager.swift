import Foundation

class LocalizationManager {
    
    static let shared = LocalizationManager()
    
    private var currentLanguage: String = "en"
    private var localizedStrings: [String: String] = [:]
    
    private init() {
        loadSavedLanguage()
        loadLocalizedStrings()
    }
    
    private func loadSavedLanguage() {
        if let savedLanguage = UserDefaults.standard.string(forKey: "selected_language") {
            currentLanguage = savedLanguage
        } else {
            currentLanguage = detectSystemLanguage()
            UserDefaults.standard.set(currentLanguage, forKey: "selected_language")
        }
    }
    
    private func detectSystemLanguage() -> String {
        let systemLanguage = Locale.preferredLanguages.first ?? "en"
        return systemLanguage.hasPrefix("tr") ? "tr" : "en"
    }
    
    private func loadLocalizedStrings() {
        // Try to load from the localization directory first
        if let path = Bundle.main.path(forResource: "Localizable", ofType: "strings", inDirectory: "Localizations/\(currentLanguage).lproj"),
           let strings = NSDictionary(contentsOfFile: path) as? [String: String] {
            localizedStrings = strings
            return
        }
        
        // Fallback to standard localization
        if let path = Bundle.main.path(forResource: "Localizable", ofType: "strings", inDirectory: nil, forLocalization: currentLanguage),
           let strings = NSDictionary(contentsOfFile: path) as? [String: String] {
            localizedStrings = strings
            return
        }
        
        loadFallbackStrings()
    }
    
    private func loadFallbackStrings() {
        // Try localization directory first
        if let path = Bundle.main.path(forResource: "Localizable", ofType: "strings", inDirectory: "Localizations/en.lproj"),
           let strings = NSDictionary(contentsOfFile: path) as? [String: String] {
            localizedStrings = strings
            return
        }
        
        // Standard fallback
        if let path = Bundle.main.path(forResource: "Localizable", ofType: "strings", inDirectory: nil, forLocalization: "en"),
           let strings = NSDictionary(contentsOfFile: path) as? [String: String] {
            localizedStrings = strings
            return
        }
        
        // Final fallback with some default strings
        localizedStrings = [
            "main.title": "PuzzleFrame",
            "main.select.image": "Select Image",
            "main.settings": "Settings",
            "error.title": "Error",
            "common.ok": "OK",
            "common.cancel": "Cancel",
            "common.back": "Back"
        ]
    }
    
    func localizedString(for key: String) -> String {
        return localizedStrings[key] ?? key
    }
    
    func setLanguage(_ language: String) {
        guard language == "en" || language == "tr" else { return }
        
        currentLanguage = language
        UserDefaults.standard.set(language, forKey: "selected_language")
        loadLocalizedStrings()
        
        NotificationCenter.default.post(name: .languageChanged, object: nil)
    }
    
    func getCurrentLanguage() -> String {
        return currentLanguage
    }
    
    func getAvailableLanguages() -> [String] {
        return ["en", "tr"]
    }
    
    func getLanguageDisplayName(_ language: String) -> String {
        switch language {
        case "en":
            return "English"
        case "tr":
            return "Türkçe"
        default:
            return language
        }
    }
}

extension Notification.Name {
    static let languageChanged = Notification.Name("languageChanged")
}

extension String {
    var localized: String {
        return LocalizationManager.shared.localizedString(for: self)
    }
}