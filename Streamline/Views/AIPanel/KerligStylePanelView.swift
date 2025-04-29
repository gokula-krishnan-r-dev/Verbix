import SwiftUI
import AppKit
import Combine

// FocusableTextField to enable auto-focus
struct FocusableTextField: NSViewRepresentable {
    @Binding var text: String
    var placeholder: String
    var onCommit: () -> Void
    var isFocused: Bool
    
    func makeNSView(context: Context) -> NSTextField {
        let textField = NSTextField()
        textField.placeholderString = placeholder
        textField.delegate = context.coordinator
        textField.font = .systemFont(ofSize: 15)
        textField.isBezeled = false
        textField.isBordered = false
        textField.drawsBackground = false
        return textField
    }
    
    func updateNSView(_ nsView: NSTextField, context: Context) {
        nsView.stringValue = text
        
        // Focus the text field when requested
        if isFocused {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                if let window = nsView.window, window.isKeyWindow {
                    nsView.becomeFirstResponder()
                }
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, NSTextFieldDelegate {
        var parent: FocusableTextField
        
        init(_ parent: FocusableTextField) {
            self.parent = parent
        }
        
        func controlTextDidChange(_ obj: Notification) {
            guard let textField = obj.object as? NSTextField else { return }
            parent.text = textField.stringValue
        }
        
        func controlTextDidEndEditing(_ obj: Notification) {
            parent.onCommit()
        }
    }
}

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
    @State private var shouldFocusTextField: Bool = true
    @State private var animatePanel: Bool = false
    @FocusState private var searchQueryIsFocused: Bool

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
            HeaderPanelView()
            
            // Main content area with prompt and actions
            mainContentView
        }
        .frame(width: 640, height: 520)
        .background(
            Color(.windowBackgroundColor)
                .opacity(0.98)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: Color.black.opacity(0.2), radius: 15, x: 0, y: 5)
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
            
            // Set focus state to true when panel opens
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                searchQueryIsFocused = true
            }
            
            // Animate panel appearance
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                animatePanel = true
            }
        }
        .onChange(of: appState.isAIPanelVisible) { oldValue, newValue in
            if newValue {
                // Ensure text field gets focus when panel becomes visible
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    searchQueryIsFocused = true
                }
                
                // Animate panel in
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    animatePanel = true
                }
            } else {
                // Animate panel out
                withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                    animatePanel = false
                }
                searchQueryIsFocused = false
            }
        }
        .onChange(of: appState.selectedText) { oldValue, newValue in
            // Update displayed text when selectedText changes
            displayedText = newValue
            
            // Update tab selection
            if !newValue.isEmpty {
                selectedTab = .withContent
            }
            
            // Clear previous response when text changes
            generatedResponse = ""
        }
        .scaleEffect(animatePanel ? 1.0 : 0.95)
        .opacity(animatePanel ? 1.0 : 0.0)
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
                            // actionButtonsView
                            
                            if !generatedResponse.isEmpty {
                                // responseView
                            }
                        }
                        .padding(.bottom, 20)
                    }
                    .background(Color.white.opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .padding(8)
                } else {
                    // Content when "with content" tab is selected
                    ScrollView {
                        VStack(spacing: 0) {
                            // Selected text display
                            selectedTextView
                            
                            // Search/prompt field
                            promptField
                            
                            // Quick action buttons
                            // actionButtonsView
                            
                            if !generatedResponse.isEmpty {
                                // responseView
                            }
                        }
                        .padding(.bottom, 20)
                    }
                    .background(Color.white.opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .padding(8)
                }
            }
        }
        .background(Color.white.opacity(0.95))
    }
    
    private var selectedTextView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(displayedText)
                .font(.body)
                .foregroundColor(.primary)
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.secondary.opacity(0.1))
                )
                .cornerRadius(8)
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .transition(.move(edge: .top).combined(with: .opacity))
        .animation(.spring(response: 0.4), value: selectedTab == .withContent)
    }
    
    private var promptField: some View {
        HStack(spacing: 12) {
            // Action icon
            Image(systemName: "wand.and.stars")
                .font(.system(size: 16))
                .foregroundColor(.blue)
                .opacity(0.8)
                .scaleEffect(searchQuery.isEmpty ? 1.0 : 0.9)
                .animation(.spring(response: 0.3), value: searchQuery.isEmpty)
            
            // Text field for search or prompt using SwiftUI's TextField
            TextField("Ask AI to...", text: $searchQuery)
                .onSubmit {
                    if !searchQuery.isEmpty {
                        processCustomPrompt()
                    }
                }
                .focused($searchQueryIsFocused)
                .disableAutocorrection(true)
                .textFieldStyle(PlainTextFieldStyle())
                .foregroundColor(.primary)
                .font(.system(size: 15))
            
            // Clear button that appears when text is entered
            if !searchQuery.isEmpty {
                Button(action: {
                    searchQuery = ""
                    // Re-focus the text field after clearing
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        searchQueryIsFocused = true
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.gray.opacity(0.7))
                        .padding(2)
                }
                .buttonStyle(PlainButtonStyle())
                .transition(.scale.combined(with: .opacity))
                .animation(.spring(response: 0.3), value: !searchQuery.isEmpty)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.textBackgroundColor).opacity(0.8))
                .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 1)
        )
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }
    
    private var actionButtonsView: some View {
        VStack(spacing: 0) {
            ForEach(Array(quickActions.enumerated()), id: \.element) { index, action in
                ActionButton(
                    action: action,
                    isSelected: selectedAction == action,
                    isProcessing: isProcessing && selectedAction == action,
                    onSelect: { selectAction(action) }
                )
                .padding(.horizontal, 16)
                .transition(.opacity)
                .animation(.easeInOut.delay(Double(index) * 0.05), value: animatePanel)
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
                .buttonStyle(PlainButtonStyle())
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                
                Button(action: {
                    // Insert text into source app if possible
                    insertTextIntoSourceApp(generatedResponse)
                }) {
                    Label("Insert", systemImage: "arrow.right.doc.on.clipboard")
                        .font(.footnote)
                }
                .buttonStyle(PlainButtonStyle())
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
                .buttonStyle(PlainButtonStyle())
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: !generatedResponse.isEmpty)
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
    
    @State private var isHovered: Bool = false
    @State private var isPressed: Bool = false
    
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
                        .shadow(color: isSelected ? Color.blue.opacity(0.3) : .clear, radius: 2, x: 0, y: 0)
                }
                
                Text(action.title)
                    .font(.system(size: 14, weight: isSelected ? .medium : .regular))
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
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(isSelected ? Color.white.opacity(0.3) : Color.blue)
                        )
                        .cornerRadius(4)
                        .foregroundColor(isSelected ? .white : .white)
                        .shadow(color: isSelected ? .clear : Color.blue.opacity(0.3), radius: 2, x: 0, y: 1)
                }
                .buttonStyle(PlainButtonStyle())
                .scaleEffect(isPressed ? 0.95 : 1.0)
                .animation(.spring(response: 0.2), value: isPressed)
                .disabled(isProcessing)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        isSelected ? Color.blue :
                        isHovered ? Color.secondary.opacity(0.1) :
                                   Color.secondary.opacity(0.05)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(
                        isSelected ? Color.blue.opacity(0.6) :
                        isHovered ? Color.secondary.opacity(0.2) :
                                   Color.clear,
                        lineWidth: 1
                    )
            )
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.bottom, 8)
        .disabled(isProcessing)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(.spring(response: 0.3)) {
                        isPressed = false
                    }
                }
        )
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
