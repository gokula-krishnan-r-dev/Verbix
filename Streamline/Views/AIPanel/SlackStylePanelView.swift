import SwiftUI
import AppKit
import Combine
import OSLog

struct SlackStylePanelView: View {
    @EnvironmentObject var appState: AppState
    @State private var inputText: String = ""
    @State private var selectedTab: Int = 0
    @State private var quickReplySuggestion: String = "reply that it went well and we can meet tomorrow at 2pm"
    @State private var senderName: String = "Taylor"
    @State private var messageTime: String = "8:00 PM"
    @State private var displayedText: String = ""
    @State private var isGeneratingSuggestion: Bool = false
    @State private var selectedTextAnimation: Bool = false
    
    // Predefined tabs
    private let tabs = ["Reply", "Summarize", "Rewrite", "Translate"]
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            slackHeaderView
            
            // Tab bar for different actions
            tabBarView
            
            // Main content
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Original message section
                    messageContentView
                    
                    // AI suggestion for reply
                    suggestedReplyView
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .background(Color(.windowBackgroundColor))
        }
        .onAppear {
            // Detect app name when showing panel
            detectAppAndContext()
            
            // Initialize displayed text from appState
            displayedText = appState.selectedText
            
            // Animate the text to draw attention
            animateSelectedText()
        }
        .onChange(of: appState.selectedText) { newText in
            // Update displayed text when selectedText changes
            displayedText = newText
            
            // Animate the text to draw attention
            animateSelectedText()
        }
    }
    
    // MARK: - Subviews
    
    private var slackHeaderView: some View {
        HStack(spacing: 12) {
            // App icon
            ZStack {
                Circle()
                    .fill(Color.purple.opacity(0.2))
                    .frame(width: 32, height: 32)
                
                Image(systemName: "message.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.purple)
            }
            
            // App name
            VStack(alignment: .leading, spacing: 2) {
                Text(appState.currentAppName.isEmpty ? "Slack" : appState.currentAppName)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("reply / \(appState.aiModel)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Close button
            Button(action: {
                closePanel()
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .padding(4)
            }
            .buttonStyle(PlainButtonStyle())
            .keyboardShortcut(.escape, modifiers: [])
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(.windowBackgroundColor))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color.gray.opacity(0.2)),
            alignment: .bottom
        )
    }
    
    private var tabBarView: some View {
        HStack(spacing: 0) {
            ForEach(0..<tabs.count, id: \.self) { index in
                Button(action: {
                    withAnimation {
                        selectedTab = index
                        generateSuggestionBasedOnTab()
                    }
                }) {
                    Text(tabs[index])
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .foregroundColor(selectedTab == index ? .blue : .primary)
                        .background(
                            ZStack {
                                if selectedTab == index {
                                    Rectangle()
                                        .fill(Color.blue.opacity(0.1))
                                }
                            }
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }
            Spacer()
        }
        .padding(.horizontal, 8)
        .background(Color(.windowBackgroundColor))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color.gray.opacity(0.2)),
            alignment: .bottom
        )
    }
    
    // Original message view
    private var messageContentView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                // User avatar
                ZStack {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 36, height: 36)
                    
                    Text(getSenderInitial())
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.gray)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    // User name and timestamp
                    HStack(spacing: 6) {
                        Text(senderName)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text(messageTime)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Message content - use displayedText state variable
                    Text(displayedText.isEmpty ? "No text selected. Please select or copy text to get AI suggestions." : displayedText)
                        .font(.body)
                        .foregroundColor(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                        .scaleEffect(selectedTextAnimation ? 1.02 : 1)
                        .animation(.spring(response: 0.3), value: selectedTextAnimation)
                }
            }
            .padding()
            .background(Color(.windowBackgroundColor))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
        }
    }
    
    // AI suggestion for quick reply
    private var suggestedReplyView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(tabs[selectedTab]) AI suggestion...")
                .font(.headline)
                .foregroundColor(.secondary)
                .padding(.top, 8)
            
            // Suggestion box
            if isGeneratingSuggestion {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    
                    Text("Generating suggestion...")
                        .font(.body)
                        .foregroundColor(.primary)
                        .padding(.leading, 8)
                    
                    Spacer()
                }
                .padding(12)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
            } else {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.system(size: 16))
                    
                    Text(quickReplySuggestion)
                        .font(.body)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Button(action: {
                        // Edit suggestion
                        editSuggestion()
                    }) {
                        Text("Edit")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: {
                        // Delete suggestion
                        deleteSuggestion()
                    }) {
                        Text("Del")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(12)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
            }
            
            HStack {
                // Options below suggestion
                Button(action: {
                    // Insert in source app
                    insertInSourceApp()
                }) {
                    Label("Insert in \(appState.currentAppName)", systemImage: "arrow.up.doc.fill")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.vertical, 4)
                
                Spacer()
                
                Button(action: {
                    // Copy to clipboard
                    copyToClipboard()
                }) {
                    Label("Copy to clipboard", systemImage: "doc.on.doc")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.vertical, 4)
                
                Spacer()
                
                Button(action: {
                    // Regenerate response
                    regenerateResponse()
                }) {
                    Label("Regenerate", systemImage: "arrow.clockwise")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.vertical, 4)
            }
            .padding(.horizontal, 8)
        }
    }
    
    // MARK: - Helper Methods
    
    private func closePanel() {
        appState.isAIPanelVisible = false
        NotificationCenter.default.post(name: NSNotification.Name("ClosePanelNotification"), object: nil)
    }
    
    private func detectAppAndContext() {
        // Set default values if needed
        if senderName == "Unknown" {
            senderName = "Taylor"
        }
        
        if messageTime.isEmpty {
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mm a"
            messageTime = formatter.string(from: Date())
        }
        
        // Detect current app
        if let app = NSWorkspace.shared.frontmostApplication {
            if app.bundleIdentifier?.contains("slack") == true {
                // It's Slack
                appState.currentAppName = "Slack"
            } else {
                // Use generic app name
                appState.currentAppName = app.localizedName ?? "Message"
            }
        }
        
        // Generate a suggestion based on selected tab
        generateSuggestionBasedOnTab()
    }
    
    private func getSenderInitial() -> String {
        return String(senderName.prefix(1))
    }
    
    private func animateSelectedText() {
        guard !displayedText.isEmpty else { return }
        selectedTextAnimation = true
        
        // Reset animation after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            selectedTextAnimation = false
        }
    }
    
    private func generateSuggestionBasedOnTab() {
        // Only generate if we have selected text
        guard !appState.selectedText.isEmpty else { return }
        
        isGeneratingSuggestion = true
        
        // Simulate AI generation with a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            switch selectedTab {
            case 0: // Reply
                quickReplySuggestion = "reply that it went well and we can meet tomorrow at 2pm"
            case 1: // Summarize
                quickReplySuggestion = "The key points are: \(generateSummary(from: appState.selectedText))"
            case 2: // Rewrite
                quickReplySuggestion = rewriteText(appState.selectedText)
            case 3: // Translate
                quickReplySuggestion = "Here's the translation: \(translateText(appState.selectedText))"
            default:
                quickReplySuggestion = "I can help you respond to this message."
            }
            
            isGeneratingSuggestion = false
        }
    }
    
    private func generateSummary(from text: String) -> String {
        // In a real app, this would call the AI service
        // For now, return a simplified version
        let words = text.split(separator: " ")
        if words.count > 10 {
            return words.prefix(10).joined(separator: " ") + "..."
        }
        return text
    }
    
    private func rewriteText(_ text: String) -> String {
        // Simulate rewriting the text
        return "I've rewritten this to be more concise: " + text.prefix(50) + (text.count > 50 ? "..." : "")
    }
    
    private func translateText(_ text: String) -> String {
        // Simulate translation
        return text.prefix(50) + (text.count > 50 ? "... (translated)" : " (translated)")
    }
    
    private func editSuggestion() {
        // In a real app, this would open an editing interface
        // For now, just log the action
        NSLog("Edit suggestion requested")
    }
    
    private func deleteSuggestion() {
        // Clear current suggestion and regenerate
        quickReplySuggestion = ""
        generateSuggestionBasedOnTab()
    }
    
    private func insertInSourceApp() {
        // Copy suggestion to clipboard
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(quickReplySuggestion, forType: .string)
        
        // In a real app, this would integrate with accessibility APIs to paste
        // For now, just close the panel so user can paste manually
        NSLog("Inserted suggestion in \(appState.currentAppName)")
        
        // Save interaction to history
        saveInteraction()
        
        // Close panel
        closePanel()
    }
    
    private func copyToClipboard() {
        // Copy suggestion to clipboard
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(quickReplySuggestion, forType: .string)
        
        // Provide feedback (in a real app, show a toast or notification)
        NSLog("Copied suggestion to clipboard")
        
        // Save interaction to history
        saveInteraction()
    }
    
    private func regenerateResponse() {
        // Clear current suggestion and regenerate
        quickReplySuggestion = ""
        generateSuggestionBasedOnTab()
    }
    
    private func saveInteraction() {
        // Save the interaction for history
        appState.aiResponse = quickReplySuggestion
        appState.saveInteraction()
    }
}

// MARK: - Previews

struct SlackStylePanelView_Previews: PreviewProvider {
    static var previews: some View {
        SlackStylePanelView()
            .environmentObject(AppState())
            .frame(width: 400, height: 500)
            .preferredColorScheme(.light)
    }
} 
