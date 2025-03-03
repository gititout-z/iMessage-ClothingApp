// MARK: - UserDefaultsManager.swift
import Foundation

class UserDefaultsManager {
    static let shared = UserDefaultsManager()
    
    private let defaults = UserDefaults.standard
    
    private init() {}
    
    // MARK: - Generic Get/Set Methods
    
    func set<T>(_ value: T, forKey key: String) {
        defaults.set(value, forKey: key)
    }
    
    func get<T>(forKey key: String, defaultValue: T) -> T {
        return defaults.object(forKey: key) as? T ?? defaultValue
    }
    
    // MARK: - Codable Support
    
    func setCodable<T: Codable>(_ value: T, forKey key: String) {
        if let encoded = try? JSONEncoder().encode(value) {
            defaults.set(encoded, forKey: key)
        }
    }
    
    func getCodable<T: Codable>(forKey key: String) -> T? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }
    
    // MARK: - Specific App Settings
    
    var searchHistory: [String] {
        get { getCodable(forKey: "searchHistory") ?? [] }
        set { setCodable(newValue, forKey: "searchHistory") }
    }
    
    var lastActiveTab: Int {
        get { get(forKey: "lastActiveTab", defaultValue: 0) }
        set { set(newValue, forKey: "lastActiveTab") }
    }
    
    var hasCompletedOnboarding: Bool {
        get { get(forKey: "hasCompletedOnboarding", defaultValue: false) }
        set { set(newValue, forKey: "hasCompletedOnboarding") }
    }
    
    var selectedCategories: [String] {
        get { getCodable(forKey: "selectedCategories") ?? [] }
        set { setCodable(newValue, forKey: "selectedCategories") }
    }
    
    // MARK: - Clear Data
    
    func clearSearchHistory() {
        searchHistory = []
    }
    
    func clearAllData() {
        let domain = Bundle.main.bundleIdentifier!
        defaults.removePersistentDomain(forName: domain)
    }
}