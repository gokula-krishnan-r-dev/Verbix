import SwiftUI
import AppKit
import Combine

struct KerligStylePanelView: View {
    @EnvironmentObject var appState: AppState
    @State private var inputText: String = ""
    @State private var selectedAction: AIAction? = nil
    @State private var isGeneratingSuggestion: Bool = false
    @State private var displayedText: String = ""
    @State private var selectedTab: ActionTab = .blank
    @State private var searchQuery: String = ""
    @State private var isPanelPinned: Bool = false
    @State private var aiModel: AIModel = .gpt4o
    @State private var generatedResponse: String = ""
    @State private var isProcessing: Bool = false
    @State private var cancellables = Set<AnyCancellable>()
    
    // Services
    private let aiService = AIService()
    private let hotkeyManager = HotkeyManager()
    
    // Predefined actions
    private let quickActions: [AIAction] = [
        .fixSpellingGrammar,
        .improveWriting,
        .translate,
        .makeShorter
    ]
    
    private enum ActionTab {
        case blank
        case withContent
    }
    
    private enum AIModel: String, CaseIterable {
        case gpt4o = "GPT-4o Turbo"
        case gpt4 = "GPT-4"
        case claude = "Claude 3"
        
        var badgeText: String {
            switch self {
            case .gpt4o: return "GPT-4o"
            case .gpt4: return "GPT-4"
            case .claude: return "Claude"
            }
        }
        
        var apiModel: String {
            switch self {
            case .gpt4o: return "gpt-4o"
            case .gpt4: return "gpt-4"
            case .claude: return "claude-3-opus-20240229"
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with app info
            headerView
            
            // Main content area with prompt and actions
            mainContentView
        }
        .frame(width: 640, height: 520)
        .background(Color(.windowBackgroundColor))
        .onAppear {
            // Initialize displayed text from appState
            displayedText = appState.selectedText
            
            // Set model from app state
            if let model = AIModel(rawValue: appState.aiModel) {
                aiModel = model
            }
            
            // Set correct tab based on whether text is selected
            selectedTab = displayedText.isEmpty ? .blank : .withContent
            
            // Auto-select first action if text is available
            if !displayedText.isEmpty && selectedAction == nil {
                selectedAction = quickActions.first
            }
        }
        .onChange(of: appState.selectedText) { newText in
            // Update displayed text when selectedText changes
            displayedText = newText
            
            // Update tab selection
            if !newText.isEmpty {
                selectedTab = .withContent
            }
            
            // Clear previous response when text changes
            generatedResponse = ""
        }
    }
    
    // MARK: - Subviews
    
    private var headerView: some View {
        HStack(spacing: 12) {
            // Source app icon
            Image(systemName: "globe")
                .font(.system(size: 16))
                .foregroundColor(.blue)
                .frame(width: 24, height: 24)
            
            // App name
            Text(appState.currentAppName.isEmpty ? "Google Chrome" : appState.currentAppName)
                .font(.system(size: 14))
                .foregroundColor(.primary)
            
            Spacer()
            
            // Start blank / with content toggle
            HStack(spacing: 0) {
                Button(action: {
                    selectedTab = .blank
                }) {
                    Text("Start blank")
                        .font(.system(size: 13))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .foregroundColor(selectedTab == .blank ? .primary : .secondary)
                        .background(selectedTab == .blank ? Color.white : Color.clear)
                        .cornerRadius(4)
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: {
                    selectedTab = .withContent
                }) {
                    Image(systemName: "arrow.up.doc.fill")
                        .font(.system(size: 12))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .foregroundColor(selectedTab == .withContent ? .primary : .secondary)
                        .background(selectedTab == .withContent ? Color.white : Color.clear)
                        .cornerRadius(4)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(4)
            
            // Pin button
            Button(action: {
                isPanelPinned.toggle()
                
                // Notify panel controller about pin state change
                NotificationCenter.default.post(
                    name: NSNotification.Name("PanelPinStateChanged"),
                    object: isPanelPinned
                )
            }) {
                Image(systemName: isPanelPinned ? "pin.fill" : "pin")
                    .font(.system(size: 14))
                    .foregroundColor(isPanelPinned ? .blue : .secondary)
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(PlainButtonStyle())
            
            // History button
            Button(action: {
                // Navigate to history in main app
                NotificationCenter.default.post(
                    name: NSNotification.Name("ShowHistoryView"),
                    object: nil
                )
                
                // Close panel
                closePanel()
            }) {
                Image(systemName: "clock")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.white)
    }
    
    private var mainContentView: some View {
        VStack(spacing: 0) {
            // Main content area
            ZStack {
                // Content when blank tab is selected
                if selectedTab == .blank {
                    ScrollView {
                        VStack(spacing: 0) {
                            // Search/prompt field
                            promptField
                            
                            // Quick action buttons
                            actionButtonsView
                            
                            if !generatedResponse.isEmpty {
                                responseView
                            }
                        }
                    }
                } else {
                    // Content when "with content" tab is selected
                    ScrollView {
                        VStack(spacing: 0) {
                            // Selected text display
                            selectedTextView
                            
                            // Search/prompt field
                            promptField
                            
                            // Quick action buttons
                            actionButtonsView
                            
                            if !generatedResponse.isEmpty {
                                responseView
                            }
                        }
                    }
                }
            }
        }
        .background(Color.white.opacity(0.97))
    }
    
    private var selectedTextView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(displayedText)
                .font(.body)
                .foregroundColor(.primary)
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.secondary.opacity(0.1))
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }
    
    private var promptField: some View {
        HStack(spacing: 12) {
            // Action icon
            Image(systemName: "wand.and.stars")
                .font(.system(size: 16))
                .foregroundColor(.blue)
            
            // Text field for search or prompt
            TextField("Ask AI to...", text: $searchQuery)
                .font(.system(size: 15))
                .textFieldStyle(PlainTextFieldStyle())
                .onSubmit {
                    // Process the search query when user presses Enter
                    if !searchQuery.isEmpty {
                        processCustomPrompt()
                    }
                }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white)
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }
    
    private var actionButtonsView: some View {
        VStack(spacing: 0) {
            ForEach(quickActions, id: \.self) { action in
                ActionButton(
                    action: action,
                    isSelected: selectedAction == action,
                    isProcessing: isProcessing && selectedAction == action,
                    onSelect: { selectAction(action) }
                )
                .padding(.horizontal, 16)
            }
        }
        .padding(.top, 12)
    }
    
    private var responseView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Response")
                .font(.headline)
                .foregroundColor(.secondary)
                .padding(.horizontal, 16)
                .padding(.top, 16)
            
            Text(generatedResponse)
                .font(.body)
                .foregroundColor(.primary)
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
                .padding(.horizontal, 16)
            
            HStack {
                Spacer()
                
                Button(action: {
                    copyToClipboard(generatedResponse)
                }) {
                    Label("Copy", systemImage: "doc.on.doc")
                        .font(.footnote)
                }
                .buttonStyle(.plain)
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                
                Button(action: {
                    // Insert text into source app if possible
                    insertTextIntoSourceApp(generatedResponse)
                }) {
                    Label("Insert", systemImage: "arrow.right.doc.on.clipboard")
                        .font(.footnote)
                }
                .buttonStyle(.plain)
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                
                Button(action: {
                    // Regenerate response
                    if let action = selectedAction {
                        processText(with: action)
                    } else {
                        processCustomPrompt()
                    }
                }) {
                    Label("Regenerate", systemImage: "arrow.clockwise")
                        .font(.footnote)
                }
                .buttonStyle(.plain)
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
    }
    
    // MARK: - Helper Methods
    
    private func selectAction(_ action: AIAction) {
        selectedAction = action
        
        // Prepare to process with the selected action
        processText(with: action)
    }
    
    private func processText(with action: AIAction) {
        // Check if we have text to process
        let textToProcess = selectedTab == .withContent ? displayedText : searchQuery
        
        guard !textToProcess.isEmpty else { return }
        
        isProcessing = true
        
        // Use API key if available, otherwise simulate
        if !appState.apiKey.isEmpty {
            aiService.processWithAction(
                text: textToProcess,
                action: action,
                apiKey: appState.apiKey,
                model: aiModel.apiModel
            )
            .sink(
                receiveCompletion: { completion in
                    isProcessing = false
                    
                    if case .failure(let error) = completion {
                        generatedResponse = "Error: \(error.localizedDescription)"
                    }
                },
                receiveValue: { response in
                    generatedResponse = response
                    isProcessing = false
                    
                    // Save to app state
                    appState.aiResponse = response
                    appState.saveInteraction()
                }
            )
            .store(in: &cancellables)
        } else {
            // Simulate response with no API key
            aiService.simulateResponseForAction(text: textToProcess, action: action)
                .sink(
                    receiveCompletion: { _ in
                        isProcessing = false
                    },
                    receiveValue: { response in
                        generatedResponse = response
                        isProcessing = false
                        
                        // Save to app state
                        appState.aiResponse = response
                        appState.saveInteraction()
                    }
                )
                .store(in: &cancellables)
        }
    }
    
    private func processCustomPrompt() {
        guard !searchQuery.isEmpty else { return }
        
        isProcessing = true
        
        // Create a custom system prompt
        let systemPrompt = "You are a helpful assistant. Respond to the following prompt:"
        
        // Use API key if available, otherwise simulate
        if !appState.apiKey.isEmpty {
            aiService.generateResponse(
                prompt: searchQuery,
                systemPrompt: systemPrompt,
                apiKey: appState.apiKey,
                model: aiModel.apiModel
            )
            .sink(
                receiveCompletion: { completion in
                    isProcessing = false
                    
                    if case .failure(let error) = completion {
                        generatedResponse = "Error: \(error.localizedDescription)"
                    }
                },
                receiveValue: { response in
                    generatedResponse = response
                    isProcessing = false
                    
                    // Save to app state for history
                    appState.selectedText = searchQuery
                    appState.aiResponse = response
                    appState.saveInteraction()
                }
            )
            .store(in: &cancellables)
        } else {
            // Simulate a response
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                generatedResponse = "Here is a response to your custom prompt: \(searchQuery)"
                isProcessing = false
                
                // Save to app state for history
                appState.selectedText = searchQuery
                appState.aiResponse = generatedResponse
                appState.saveInteraction()
            }
        }
    }
    
    private func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
    
    private func insertTextIntoSourceApp(_ text: String) {
        // Copy to clipboard first
        copyToClipboard(text)
        
        // Try to simulate paste in the frontmost app
        // This is a simplified approach - the real implementation would use accessibility APIs
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            hotkeyManager.simulateKeyPress(virtualKey: 0x09, withCommand: true) // Cmd+V
        }
        
        // Close the panel
        closePanel()
    }
    
    private func closePanel() {
        appState.isAIPanelVisible = false
        NotificationCenter.default.post(name: NSNotification.Name("ClosePanelNotification"), object: nil)
    }
}

// MARK: - Supporting Views

struct ActionButton: View {
    let action: AIAction
    let isSelected: Bool
    let isProcessing: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                if isProcessing {
                    ProgressView()
                        .scaleEffect(0.7)
                        .frame(width: 16, height: 16)
                        .foregroundColor(isSelected ? .white : .blue)
                } else {
                    Image(systemName: action.icon)
                        .font(.system(size: 16))
                        .foregroundColor(isSelected ? .white : .blue)
                }
                
                Text(action.title)
                    .font(.system(size: 14))
                    .foregroundColor(isSelected ? .white : .primary)
                
                Spacer()
                
                if isSelected {
                    Text("TAB")
                        .font(.system(size: 11, weight: .semibold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.white.opacity(0.3))
                        .cornerRadius(4)
                        .foregroundColor(.white)
                }
                
                Button(action: {
                    // Run action
                    onSelect()
                }) {
                    Text("Run")
                        .font(.system(size: 13, weight: .medium))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(isSelected ? Color.white.opacity(0.3) : Color.blue)
                        .cornerRadius(4)
                        .foregroundColor(isSelected ? .white : .white)
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(isProcessing)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(isSelected ? Color.blue : Color.secondary.opacity(0.05))
            .cornerRadius(6)
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.bottom, 8)
        .disabled(isProcessing)
    }
}

// MARK: - Preview

struct KerligStylePanelView_Previews: PreviewProvider {
    static var previews: some View {
        KerligStylePanelView()
            .environmentObject(AppState())
            .frame(width: 640, height: 520)
            .preferredColorScheme(.light)
    }
} 