import Foundation
import SwiftUI
import Combine

class AppState: ObservableObject {
    // User settings
    @Published var hotkeyEnabled: Bool = true
    @Published var emptySelectionMode: Bool = false
    @Published var apiKey: String = ""
    @Published var aiModel: String = "gpt-4o"
    @Published var isDarkMode: Bool = false
    @Published var currentTheme: String = "light" // Default to light theme
    @Published var responseStyle: ResponseStyle = .balanced
    
    // History
    @Published var history: [ChatInteraction] = []
    
    // UI state
    @Published var isAIPanelVisible: Bool = false
    @Published var selectedText: String = ""
    @Published var aiResponse: String = ""
    @Published var isLoading: Bool = false
    @Published var isProcessing: Bool = false
    @Published var showingSettings: Bool = false
    @Published var currentAppName: String = ""
    
    // Text source tracking
    @Published var textSource: TextSource = .unknown
    @Published var lastSelectionTimestamp: Date = Date()
    @Published var textMetadata: [String: Any] = [:]
    
    // Saved settings
    var savedAPIKey: String {
        get {
            UserDefaults.standard.string(forKey: "apiKey") ?? ""
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "apiKey")
            apiKey = newValue
        }
    }
    
    var savedModel: String {
        get {
            UserDefaults.standard.string(forKey: "aiModel") ?? "gpt-4o"
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "aiModel")
            aiModel = newValue
        }
    }
    
    var savedTheme: String {
        get {
            UserDefaults.standard.string(forKey: "theme") ?? "light"
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "theme")
            currentTheme = newValue
            updateTheme()
        }
    }
    
    var savedHotkeyEnabled: Bool {
        get {
            UserDefaults.standard.bool(forKey: "hotkeyEnabled")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "hotkeyEnabled")
            hotkeyEnabled = newValue
        }
    }
    
    init() {
        // Load saved settings
        apiKey = savedAPIKey
        aiModel = savedModel
        currentTheme = "light" // Force light theme
        
        // Default to true if never set before
        if UserDefaults.standard.object(forKey: "hotkeyEnabled") == nil {
            UserDefaults.standard.set(true, forKey: "hotkeyEnabled")
        }
        hotkeyEnabled = savedHotkeyEnabled
        
        // Load history
        loadHistory()
        
        // Load response style
        if let rawStyle = UserDefaults.standard.object(forKey: "responseStyle") as? Int,
           let style = ResponseStyle(rawValue: rawStyle) {
            responseStyle = style
        }
        
        // Set app theme to light
        isDarkMode = false
        
        // Set up notification observer for panel closing
        setupNotificationObservers()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func setupNotificationObservers() {
        // Listen for panel close notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handlePanelClose),
            name: NSNotification.Name("ClosePanelNotification"),
            object: nil
        )
    }
    
    @objc private func handlePanelClose() {
        DispatchQueue.main.async {
            self.isAIPanelVisible = false
            self.emptySelectionMode = false
        }
    }
    
    private func updateTheme() {
        // Force light theme regardless of system setting
        isDarkMode = false
    }
    
    // Update selected text and track its source
    func updateSelectedText(_ text: String, source: TextSource) {
        self.selectedText = text
        self.textSource = source
        self.lastSelectionTimestamp = Date()
        
        // Get additional metadata based on source
        switch source {
        case .clipboard:
            if let app = NSWorkspace.shared.frontmostApplication {
                textMetadata["sourceApp"] = app.localizedName
                textMetadata["appBundleId"] = app.bundleIdentifier
            }
        case .directSelection:
            if let app = NSWorkspace.shared.frontmostApplication {
                textMetadata["sourceApp"] = app.localizedName
                textMetadata["appBundleId"] = app.bundleIdentifier
            }
        case .userInput:
            textMetadata["source"] = "manual input"
        case .unknown:
            textMetadata.removeAll()
        }
    }
    
    // Clear the current text and response
    func clearCurrentSession() {
        selectedText = ""
        aiResponse = ""
        textSource = .unknown
        textMetadata.removeAll()
    }
    
    // Save the current interaction to history
    func saveInteraction() {
        if !selectedText.isEmpty && !aiResponse.isEmpty {
            let interaction = ChatInteraction(
                prompt: selectedText,
                response: aiResponse,
                responseStyle: responseStyle,
                timestamp: Date()
            )
            history.append(interaction)
            saveHistory()
        }
    }
    
    // Clear all history
    func clearHistory() {
        history = []
        saveHistory()
    }
    
    // Delete a specific history item
    func deleteHistoryItem(at index: Int) {
        if index >= 0 && index < history.count {
            history.remove(at: index)
            saveHistory()
        }
    }
    
    // Load history from UserDefaults
    private func loadHistory() {
        if let historyData = UserDefaults.standard.data(forKey: "chatHistory"),
           let decodedHistory = try? JSONDecoder().decode([ChatInteraction].self, from: historyData) {
            history = decodedHistory
        }
    }
    
    // Save history to UserDefaults
    private func saveHistory() {
        if let encoded = try? JSONEncoder().encode(history) {
            UserDefaults.standard.set(encoded, forKey: "chatHistory")
        }
    }
    
    // Save settings
    func saveSettings() {
        UserDefaults.standard.set(apiKey, forKey: "apiKey")
        UserDefaults.standard.set(aiModel, forKey: "aiModel")
        UserDefaults.standard.set("light", forKey: "theme") // Always save light theme
        UserDefaults.standard.set(hotkeyEnabled, forKey: "hotkeyEnabled")
        UserDefaults.standard.set(responseStyle.rawValue, forKey: "responseStyle")
    }
}

// Enum to track where text came from
enum TextSource {
    case clipboard
    case directSelection
    case userInput
    case unknown
} 