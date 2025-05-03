import SwiftUI
import AppKit
import Combine
import UserNotifications
// Import the SelectedTextView component (if needed, but should be visible since it's in the same module)

// Define the custom color extension
extension Color {
    static let customDarkGray = Color(NSColor(red: 32/255, green: 32/255, blue: 32/255, alpha: 1.0))
    static  let customLightGray = Color(NSColor(red: 235/255, green: 222/255, blue: 240/255, alpha: 1.0))
    
    // Gradient colors for dark mode
    static let darkGradientTop = Color(red: 50/255, green: 17/255, blue: 87/255)
    static let darkGradientBottom = Color(red: 28/255, green: 10/255, blue: 50/255)
    
    // Gradient colors for light mode
    static let lightGradientTop = Color(red: 235/255, green: 222/255, blue: 240/255)
    static let lightGradientBottom = Color(red: 203/255, green: 187/255, blue: 220/255)
}

// Helper to get appropriate gradient based on color scheme
struct BackgroundGradient: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        content
            .background(
               Color(NSColor.windowBackgroundColor)
            )
    }
}

extension View {
    func backgroundGradient() -> some View {
        self.modifier(BackgroundGradient())
    }
}

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
    @State private var aiModel: String =  UserDefaults.standard.string(forKey: "aiModel") ?? "@cf/meta/llama-3.3-70b-instruct-fp8-fast"
    @State private var generatedResponse: String = ""
    @State private var isProcessing: Bool = false
    @State private var insertionStatus: InsertionStatus = .none

    // Focus states for keyboard navigation
    enum FocusableField: Hashable {
        case searchField
        case actionButton(Int)
        case copyButton
        case insertButton
        case regenerateButton
    }
    @FocusState private var focusedField: FocusableField?

    @State private var cancellables = Set<AnyCancellable>()
    @State private var shouldFocusTextField: Bool = true
    @State private var animatePanel: Bool = false
    @State private var isAnimating: Bool = false
    @FocusState private var searchQueryIsFocused: Bool
    
    // New states for insert functionality
    @State var isInserting: Bool = false
    @State var insertAttempts: Int = 0
    @State var showInsertionHelp: Bool = false
    @State var textToInsert: String = ""
    @State private var textInsertionService = TextInsertionService(delegate: nil)
    @State var shouldInsertAfterClose: Bool = false

    
    // Services
    private let aiService = AIService()
    private let hotkeyManager = HotkeyManager()
    
    // Enum to track insertion status
    private enum InsertionStatus {
        case none
        case inserting
        case success
        case failed
        case preparing
    }
    
    // Predefined actions
    private let quickActions: [AIAction] = [
        .fixSpellingGrammar,
        .improveWriting,
        .translate,
        .makeShorter
    ]
    
    // Update ActionTab to match the AIPromptField.AIPromptTab type
    private enum ActionTab: Hashable {
        case blank
        case withContent
    }
    

    
    var body: some View {
        VStack(spacing: 0) {
            // Header with app info
            HeaderPanelView()
            
            // Main content area with prompt and actions
            mainContentView
        }
        .frame(width: 640, height: 520)
        .backgroundGradient()
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: Color.black.opacity(0.2), radius: 15, x: 0, y: 5)
        .onAppear {
            // Initialize the coordinator if needed
            // if coordinator == nil {
            //     coordinator = TextInsertionCoordinator(parentView: self)
            // }
            
            // Initialize displayed text from appState
            displayedText = appState.selectedText
            
            
            // Set correct tab based on whether text is selected
            selectedTab = displayedText.isEmpty ? .blank : .withContent
            
            // Auto-select first action if text is available
            if !displayedText.isEmpty && selectedAction == nil {
                selectedAction = quickActions.first
            }
            
            // Set initial focus on search field
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                focusedField = .searchField
                searchQueryIsFocused = true
            }
            
            // Animate panel appearance
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                animatePanel = true
            }
            
            // Request notification permission
            requestNotificationPermission()
            
            // Create a new TextInsertionService with the coordinator as delegate
            // if let coordinator = coordinator {
            //     textInsertionService = TextInsertionService(delegate: coordinator)
            // }
        }
        .onChange(of: appState.isAIPanelVisible) { oldValue, newValue in
            if newValue {
                // Ensure text field gets focus when panel becomes visible
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.focusedField = .searchField
                    self.searchQueryIsFocused = true
                }
                
                // Animate panel in
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    self.animatePanel = true
                }
            } else {
                // Animate panel out
                withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                    self.animatePanel = false
                }
                self.searchQueryIsFocused = false
                
                // Check if we need to insert text after panel closure
                if self.shouldInsertAfterClose {
                    self.shouldInsertAfterClose = false
                    // Allow time for panel to fully close before inserting
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        self.textInsertionService.insertText(self.textToInsert)
                    }
                }
            }
        }
        .onChange(of: appState.selectedText) { oldValue, newValue in
            // Update displayed text when selectedText changes
            self.displayedText = newValue
            
            // Update tab selection
            if !newValue.isEmpty {
                self.selectedTab = .withContent
            }
            
            // Clear previous response when text changes
            self.generatedResponse = ""
        }
        .scaleEffect(animatePanel ? 1.0 : 0.95)
        .opacity(animatePanel ? 1.0 : 0.0)
    }
    
    
    
    // Handle text insertion using the service
    private func handleInsertText(_ text: String) {
        // Save text for potential help dialog
        textToInsert = text
        
        print("⏺️ [INSERT] Starting insertion process for text: \(text.prefix(20))...")
        
        // Update UI state
        insertionStatus = .inserting
        isInserting = true
        
        // Copy to clipboard first to ensure text is available for pasting
        copyToClipboard(text)
        print("⏺️ [INSERT] Text copied to clipboard")
        
        // Show notification that text is ready
        showNotification(title: "Preparing to Insert", 
                         message: "Text copied, preparing to insert...", 
                         isError: false)
        
        // Use a sequence for proper timing
        DispatchQueue.main.async {
            print("⏺️ [INSERT] Closing panel...")
            // First close the panel
            self.closePanel()
            
            // Wait for panel to fully close before attempting to insert
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                print("⏺️ [INSERT] Panel closed, activating target app...")
                
                // Activate frontmost app before insertion
                if self.activateFrontmostApp() {
                    print("⏺️ [INSERT] Starting text insertion...")
                    // Now perform the actual insertion
                    self.textInsertionService.insertText(text)
                    
                    // Track insertion status
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        if self.insertionStatus != .success {
                            print("⏺️ [INSERT] No success confirmation received, insertion may have failed")
                            self.showNotification(title: "Insertion Status", 
                                               message: "Text insertion may not have completed successfully", 
                                               isError: true)
                        }
                    }
                }
            }
        }
    }
    
    // Close panel method with improved logging
    private func closePanel() {
        print("⏺️ [PANEL] Closing panel...")
        
        // First hide the panel in AppState
        appState.isAIPanelVisible = false
        print("⏺️ [PANEL] Set isAIPanelVisible to false")
        
        // Post notification to ensure any observers know to close the panel
        NotificationCenter.default.post(name: NSNotification.Name("ClosePanelNotification"), object: nil)
        print("⏺️ [PANEL] Posted ClosePanelNotification")
        
        // Additional safety measure - dismiss any active sheets
        if showInsertionHelp {
            showInsertionHelp = false
            print("⏺️ [PANEL] Dismissed insertion help sheet")
        }
        
        // Force window closure with fallbacks
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // Check all windows with "AI" in the title
            for window in NSApplication.shared.windows where window.title.contains("AI") {
                print("⏺️ [PANEL] Found AI window: \(window.title), ordering out")
                window.orderOut(nil)
            }
            
            // Try to force minimization of all panels
            for window in NSApplication.shared.windows where window.isVisible {
                if window.title.isEmpty || window.title.contains("Panel") || window.title.contains("AI") {
                    print("⏺️ [PANEL] Force-minimizing window: \(window.title)")
                    window.miniaturize(nil)
                }
            }
            
            // Additional check to verify panel closure
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                let aiWindowsCount = NSApplication.shared.windows.filter { 
                    $0.isVisible && ($0.title.contains("AI") || $0.title.contains("Panel")) 
                }.count
                
                print("⏺️ [PANEL] Verification check: Found \(aiWindowsCount) AI/Panel windows still visible")
                
                if aiWindowsCount > 0 {
                    print("⏺️ [PANEL] ⚠️ Warning: Panel may not have closed properly, attempting forceful closure")
                    
                    // Try running the app.hide command
                    NSApplication.shared.hide(nil)
                    print("⏺️ [PANEL] Called NSApplication.shared.hide()")
                    
                    // Try activating Teams or target app to force focus away
                    if let frontmostApp = NSWorkspace.shared.frontmostApplication {
                        print("⏺️ [PANEL] Forcing activation of: \(frontmostApp.localizedName ?? "Unknown app")")
                        frontmostApp.activate(options: [])
                    }
                }
            }
        }
    }
    
    // Notification helper
    private func showNotification(title: String, message: String, isError: Bool = false) {
        // Use newer UNUserNotificationCenter API for macOS 10.14+
        if #available(macOS 10.14, *) {
            let content = UNMutableNotificationContent()
            content.title = title
            content.body = message
            content.sound = isError ? UNNotificationSound.default : nil
            
            // Create a request with the content
            let request = UNNotificationRequest(
                identifier: UUID().uuidString,
                content: content,
                trigger: nil // deliver immediately
            )
            
            // Add the request to the notification center
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("Error showing notification: \(error.localizedDescription)")
                }
            }
        } else {
            // Fallback for older macOS versions
            let notification = NSUserNotification()
            notification.title = title
            notification.informativeText = message
            notification.soundName = isError ? NSUserNotificationDefaultSoundName : nil
            
            let center = NSUserNotificationCenter.default
            center.deliver(notification)
        }
    }
    
    // Add a method to request notification permissions
    private func requestNotificationPermission() {
        if #available(macOS 10.14, *) {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
                if let error = error {
                    print("Error requesting notification permission: \(error.localizedDescription)")
                }
            }
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

        aiService.processWithAction(text: textToProcess, action: AIService.ActionType(rawValue: action.rawValue) ?? .summarize, apiKey: appState.apiKey, model: "@cf/meta/llama-3.3-70b-instruct-fp8-fast")
            .sink { completion in
                self.isProcessing = false
                if case .failure(let error) = completion {
                    self.generatedResponse = "Error: \(error.localizedDescription)"
                }
            } receiveValue: { response in
                self.generatedResponse = response
                self.isProcessing = false
                
                // Save to app state
                self.appState.aiResponse = response
                self.appState.saveInteraction()
            }
            .store(in: &cancellables)
    }
    
    private func processCustomPrompt() {
        guard !searchQuery.isEmpty else { 
            // Give visual feedback for empty query
            withAnimation {
                self.searchQueryIsFocused = true
            }
            return 
        }
        
        // Set loading state
        self.isProcessing = true
        self.isAnimating = true
        
        // Clear previous response to show loading state properly
        self.generatedResponse = ""
        
        // Check if user has selected text or is making a direct query
        let hasSelectedText = !displayedText.isEmpty && selectedTab == .withContent
        
        // Use the PromptManager to generate a well-structured prompt
        let promptManager = PromptManager()
        let (systemPrompt, promptContent) = promptManager.generatePrompt(
            for: searchQuery,
            selectedText: hasSelectedText ? displayedText : nil
        )
        
        // Add response format directive
        let formattedPrompt = promptManager.addResponseFormat(to: promptContent)
        
        // Log the request for debugging
        print("System prompt: \(systemPrompt)")
        print("Content prompt: \(formattedPrompt)")
        
        // Cancel any existing requests
        self.cancellables.removeAll()
        
        // Use API key if available with enhanced error handling
        let requestPublisher = self.aiService.generateResponse(
            prompt: formattedPrompt,
            systemPrompt: systemPrompt,
            model: "@cf/meta/llama-3.3-70b-instruct-fp8-fast"
        )
        
        // Add retry logic with better error handling
        requestPublisher
            .retry(2) // Retry up to 2 times before failing
            .timeout(.seconds(45), scheduler: DispatchQueue.main, customError: { URLError(.timedOut) })
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    DispatchQueue.main.async {
                        self.isProcessing = false
                        self.isAnimating = false
                        
                        if case .failure(let error) = completion {
                            // Provide user-friendly error messages based on error type
                            if let urlError = error as? URLError {
                                switch urlError.code {
                                case .notConnectedToInternet:
                                    self.generatedResponse = "No internet connection. Please check your connection and try again."
                                case .timedOut:
                                    self.generatedResponse = "Request timed out. The server might be busy, please try again."
                                case .cancelled:
                                    self.generatedResponse = "Request was cancelled."
                                default:
                                    self.generatedResponse = "Network error: \(urlError.localizedDescription)"
                                }
                            } else {
                                self.generatedResponse = "Error: \(error.localizedDescription)"
                            }
                        }
                    }
                },
                receiveValue: { response in
                    DispatchQueue.main.async {
                        self.generatedResponse = response
                        self.isProcessing = false
                        self.isAnimating = false
                        
                        // Save to app state for history
                        if hasSelectedText {
                            // Include both the instruction and selected text for context
                            self.appState.selectedText = "Instruction: \(self.searchQuery)\n\nSelected text: \(self.displayedText)"
                        } else {
                            self.appState.selectedText = self.searchQuery
                        }
                        self.appState.aiResponse = response
                        self.appState.saveInteraction()
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    // Copy to clipboard (still needed for certain operations)
    private func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
    
    // Main content view
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
                            if appState.aiResponse.isEmpty {
                            actionButtonsView
                            }
                            // actionButtonsView
                            if !appState.aiResponse.isEmpty {
                                responseView
                            }
                        }
                        .padding(.bottom, 20)
                    }
                    .backgroundGradient()
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .padding(8)
                } else {
                    // Content when "with content" tab is selected
                    ScrollView {
                        VStack(spacing: 0) {
                            // Selected text display
                            if !appState.selectedText.isEmpty {
                                selectedTextView
                            }
                            
                            // Search/prompt field
                            promptField
                            
                            // Quick action buttons
                                     if appState.aiResponse.isEmpty {
                         actionButtonsView
                                     }
                            
                            if !appState.aiResponse.isEmpty {
                                responseView
                            }
                        }
                        .padding(.bottom, 20)
                    }
                    .backgroundGradient()
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .padding(8)
                }
            }
        }
        .backgroundGradient()
    }
    
    private var selectedTextView: some View {
        SelectedTextView(displayedText: displayedText, isVisible: selectedTab == .withContent)
            .padding(.bottom, 8)  // Add some padding to separate from the prompt field
            .environmentObject(appState)  // Make sure to pass the AppState to the SelectedTextView
    }
    
    // Replace the old promptField implementation with our new component
    private var promptField: some View {
        AIPromptField(
            searchQuery: $searchQuery,
            isProcessing: $isProcessing,
            selectedTab: Binding<AIPromptField.AIPromptTab>(
                get: {
                    switch selectedTab {
                    case .blank: return .blank
                    case .withContent: return .withContent
                    }
                },
                set: { newValue in
                    switch newValue {
                    case .blank: selectedTab = .blank
                    case .withContent: selectedTab = .withContent
                    case .custom: selectedTab = .withContent // Fallback option
                    }
                }
            ),
            aiModel: $aiModel,
            focusedField: Binding<AIPromptField.FocusableField?>(
                get: {
                    if let focus = focusedField {
                        switch focus {
                        case .searchField:
                            return .searchField
                        case .actionButton(let index):
                            return .actionButton(index)
                        case .copyButton:
                            return .copyButton
                        case .insertButton:
                            return .insertButton
                        case .regenerateButton:
                            return .regenerateButton
                        }
                    }
                    return nil
                },
                set: { newValue in
                    if let newFocus = newValue {
                        switch newFocus {
                        case .searchField:
                            focusedField = .searchField
                        case .actionButton(let index):
                            focusedField = .actionButton(index)
                        case .copyButton:
                            focusedField = .copyButton
                        case .insertButton:
                            focusedField = .insertButton
                        case .regenerateButton:
                            focusedField = .regenerateButton
                        case .custom:
                            break // Ignore custom fields from AIPromptField
                        }
                    } else {
                        focusedField = nil
                    }
                }
            ),
            onSubmit: {
                self.processCustomPrompt()
            },
            onCancel: {
                self.cancellables.removeAll()
                self.isProcessing = false
                self.generatedResponse = "Request canceled."
            }
        )
    }
    
    private var actionButtonsView: some View {
        VStack(spacing: 0) {
            ForEach(Array(quickActions.enumerated()), id: \.element) { index, action in
                ActionButton(
                    action: action,
                    isSelected: self.selectedAction == action,
                    isProcessing: self.isProcessing && self.selectedAction == action,
                    isFocused: focusedField == .actionButton(index),
                    onSelect: { self.selectAction(action) }
                )
                .focused($focusedField, equals: .actionButton(index))
                .padding(.horizontal, 16)
                .transition(.opacity)
                .animation(.easeInOut.delay(Double(index) * 0.05), value: self.animatePanel)
            }
        }
        .padding(.top, 12)
    }
    
    private var responseView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Response")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if isProcessing {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.blue.opacity(0.2))
                            .frame(width: 8, height: 8)
                            .overlay(
                                Circle()
                                    .stroke(Color.blue, lineWidth: 1)
                                    .scaleEffect(isAnimating ? 2 : 0.1)
                                    .opacity(isAnimating ? 0 : 1)
                                    .animation(
                                        Animation.easeOut(duration: 1)
                                            .repeatForever(autoreverses: false)
                                            .delay(0.2 * 1),
                                        value: isAnimating
                                    )
                            )
                        
                        Circle()
                            .fill(Color.blue.opacity(0.2))
                            .frame(width: 8, height: 8)
                            .overlay(
                                Circle()
                                    .stroke(Color.blue, lineWidth: 1)
                                    .scaleEffect(isAnimating ? 2 : 0.1)
                                    .opacity(isAnimating ? 0 : 1)
                                    .animation(
                                        Animation.easeOut(duration: 1)
                                            .repeatForever(autoreverses: false)
                                            .delay(0.2 * 2),
                                        value: isAnimating
                                    )
                            )
                        
                        Circle()
                            .fill(Color.blue.opacity(0.2))
                            .frame(width: 8, height: 8)
                            .overlay(
                                Circle()
                                    .stroke(Color.blue, lineWidth: 1)
                                    .scaleEffect(isAnimating ? 2 : 0.1)
                                    .opacity(isAnimating ? 0 : 1)
                                    .animation(
                                        Animation.easeOut(duration: 1)
                                            .repeatForever(autoreverses: false)
                                            .delay(0.2 * 3),
                                        value: isAnimating
                                    )
                            )
                        
                        Text("Processing...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .strokeBorder(Color.blue.opacity(0.2), lineWidth: 1)
                            )
                    )
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            
            if isProcessing && generatedResponse.isEmpty {
                // Enhanced skeleton loading UI
                VStack(alignment: .leading, spacing: 16) {
                    // Header section
                    HStack(spacing: 12) {
                        Circle()
                            .fill(Color.blue.opacity(0.1))
                            .frame(width: 30, height: 30)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            SkeletonLine(width: 140)
                            SkeletonLine(width: 80, height: 10)
                        }
                    }
                    
                    // Content sections - simulate paragraphs
                    VStack(alignment: .leading, spacing: 12) {
                        SkeletonLine(width: nil)
                        SkeletonLine(width: nil)
                        SkeletonLine(width: nil)
                        SkeletonLine(width: 250)
                    }
                    
                    Spacer(minLength: 8)
                    
                    // Second paragraph
                    VStack(alignment: .leading, spacing: 12) {
                        SkeletonLine(width: nil)
                        SkeletonLine(width: nil)
                        SkeletonLine(width: 180)
                    }
                    
                    Spacer(minLength: 8)
                    
                    // Final section
                    VStack(alignment: .leading, spacing: 12) {
                        SkeletonLine(width: 200)
                        SkeletonLine(width: 250)
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(NSColor.windowBackgroundColor))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(Color.gray.opacity(0.2), lineWidth: 1)
                )
                .padding(.horizontal, 16)
                .transition(.opacity)
      } else {
        if !appState.aiResponse.isEmpty {
            FormattedTextView(appState.aiResponse)
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .backgroundGradient()
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(Color.gray.opacity(0.2), lineWidth: 1)
                )
        } else {
            Text("No response available")
        }
      }
            
            if !appState.aiResponse.isEmpty {
                Divider()
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                
                HStack(spacing: 12) {
                    Spacer()
                    
                    Button(action: {
                        self.copyToClipboard(self.appState.aiResponse)
                    }) {
                        Label("Copy", systemImage: "doc.on.doc")
                            .font(.footnote)
                    }
                    .buttonStyle(AnimatedButtonStyle(
                        backgroundColor: focusedField == .copyButton ? Color.blue.opacity(0.1) : Color.clear,
                        isFocused: focusedField == .copyButton
                    ))
                    .focused($focusedField, equals: .copyButton)
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
                    .overlay(Group {
                        if focusedField == .copyButton {
                            Text("C")
                                .font(.system(size: 9, weight: .bold))
                                .padding(4)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .clipShape(Circle())
                                .offset(x: -32, y: -10)
                        }
                    })
                    
                    // Updated insert button
                    Button(action: {
                        self.handleInsertText(self.appState.aiResponse)
                    }) {
                        HStack(spacing: 4) {
                            if isInserting {
                                ProgressView()
                                    .scaleEffect(0.7)
                                    .frame(width: 14, height: 14)
                                Text(insertAttempts > 1 ? "Retrying..." : "Inserting...")
                                    .font(.footnote)
                            } else if insertionStatus == .success {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("Inserted")
                                    .font(.footnote)
                            } else if insertionStatus == .failed {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .foregroundColor(.orange)
                                Text("Insert Failed")
                                    .font(.footnote)
                            } else {
                                Image(systemName: "arrow.right.doc.on.clipboard")
                                Text("Insert")
                                    .font(.footnote)
                            }
                        }
                    }
                    .buttonStyle(AnimatedButtonStyle(
                        backgroundColor: focusedField == .insertButton ? Color.blue.opacity(0.1) : 
                                       insertionStatus == .success ? Color.green.opacity(0.15) :
                                       insertionStatus == .failed ? Color.orange.opacity(0.15) :
                                       isInserting ? Color.blue.opacity(0.1) : Color.clear,
                        textColor: insertionStatus == .success ? .green :
                                 insertionStatus == .failed ? .orange : .blue,
                        showPulse: isInserting,
                        isFocused: focusedField == .insertButton
                    ))
                    .focused($focusedField, equals: .insertButton)
                    .disabled(isInserting)
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
                    .overlay(Group {
                        if focusedField == .insertButton {
                            Text("I")
                                .font(.system(size: 9, weight: .bold))
                                .padding(4)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .clipShape(Circle())
                                .offset(x: -32, y: -10)
                        }
                    })
                    
                    Button(action: {
                        if let action = self.selectedAction {
                            self.processText(with: action)
                        } else {
                            self.processCustomPrompt()
                        }
                    }) {
                        Label("Regenerate", systemImage: "arrow.clockwise")
                            .font(.footnote)
                    }
                    .buttonStyle(AnimatedButtonStyle(
                        backgroundColor: focusedField == .regenerateButton ? Color.blue.opacity(0.1) : Color.clear,
                        isFocused: focusedField == .regenerateButton
                    ))
                    .focused($focusedField, equals: .regenerateButton)
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
                    .disabled(appState.aiResponse.isEmpty || isProcessing)
                    .overlay(Group {
                        if focusedField == .regenerateButton {
                            Text("R")
                                .font(.system(size: 9, weight: .bold))
                                .padding(4)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .clipShape(Circle())
                                .offset(x: -32, y: -10)
                        }
                    })
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: !generatedResponse.isEmpty || isProcessing)
        .onAppear {
            self.isAnimating = true
        }
    }
    
    // Update the app activate calls to use the non-deprecated API
    private func activateFrontmostApp() -> Bool {
        print("🔄 [SERVICE] Attempting to activate frontmost application")
        guard let frontmostApp = NSWorkspace.shared.frontmostApplication else {
            print("🔄 [SERVICE] ⚠️ No frontmost application found")
            return false
        }
        
        print("🔄 [SERVICE] Activating app: \(frontmostApp.localizedName ?? "Unknown")")
        // Use the API without the deprecated parameter
        frontmostApp.activate(options: [])
        return true
    }
}

// Extension to make KerligStylePanelView a delegate for TextInsertionService
// extension KerligStylePanelView: TextInsertionService.TextInsertionDelegate { ... }

// MARK: - Supporting Views

struct ActionButton: View {
    let action: AIAction
    let isSelected: Bool
    let isProcessing: Bool
    var isFocused: Bool = false
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
                    Text("ENTER")
                        .font(.system(size: 11, weight: .semibold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.white.opacity(0.3))
                        .cornerRadius(4)
                        .foregroundColor(.white)
                } else if isFocused {
                    Text("ENTER")
                        .font(.system(size: 11, weight: .semibold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(4)
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        isSelected ? Color.blue : 
                        isFocused ? Color.blue.opacity(0.1) : Color.white
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(
                        isSelected ? Color.blue.opacity(0.6) :
                        isFocused ? Color.blue.opacity(0.5) :
                        isHovered ? Color.gray.opacity(0.3) :
                                   Color.clear,
                        lineWidth: isFocused && !isSelected ? 2 : 1
                    )
            )
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.bottom, 8)
        .disabled(isProcessing)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                self.isHovered = hovering
            }
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        self.isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(.spring(response: 0.3)) {
                        self.isPressed = false
                    }
                }
        )
    }
}

// Add extension for shimmer effect
extension View {
    func shimmering() -> some View {
        self.modifier(Shimmer())
    }
}

struct Shimmer: ViewModifier {
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geo in
                    LinearGradient(
                        gradient: Gradient(stops: [
                            .init(color: .clear, location: 0),
                            .init(color: .white.opacity(0.5), location: 0.3),
                            .init(color: .clear, location: 0.6)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geo.size.width * 2)
                    .offset(x: -geo.size.width + (geo.size.width * 2) * phase)
                }
            )
            .mask(content)
            .onAppear {
                withAnimation(Animation.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
    }
}

// Add this after the existing Shimmer modifier
struct SkeletonLoadingModifier: ViewModifier {
    @State private var isAnimating = false
    
    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.gray.opacity(0.2),
                                Color.gray.opacity(0.1),
                                Color.gray.opacity(0.2)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .opacity(isAnimating ? 1 : 0.6)
                    )
            )
            .onAppear {
                withAnimation(Animation.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                    isAnimating = true
                }
            }
    }
}

extension View {
    func skeletonLoading() -> some View {
        self.modifier(SkeletonLoadingModifier())
    }
}

// Add this helper to create typographic skeletons
struct SkeletonLine: View {
    var width: CGFloat? = nil
    var height: CGFloat = 14
    
    var body: some View {
        RoundedRectangle(cornerRadius: height / 3)
            .fill(Color.gray.opacity(0.2))
            .frame(width: width, height: height)
            .shimmering()
    }
}

// Add this animated button style
struct AnimatedButtonStyle: ButtonStyle {
    var backgroundColor: Color
    var textColor: Color
    var showPulse: Bool = false
    var isFocused: Bool = false
    @State private var isPulsing: Bool = false
    @State private var outerPulse: Bool = false
    
    // Initialize with default values for backward compatibility
    init(backgroundColor: Color = .clear, textColor: Color = .blue, showPulse: Bool = false, isFocused: Bool = false) {
        self.backgroundColor = backgroundColor
        self.textColor = textColor
        self.showPulse = showPulse
        self.isFocused = isFocused
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .background(
                ZStack {
                    // Base background
                    RoundedRectangle(cornerRadius: 6)
                        .fill(configuration.isPressed ? (backgroundColor != .clear ? backgroundColor : Color.blue.opacity(0.15)) : backgroundColor)
                    
                    // Focus ring
                    if isFocused {
                        RoundedRectangle(cornerRadius: 6)
                            .strokeBorder(textColor.opacity(0.8), lineWidth: 1.5)
                    }
                    
                    // Pulse animation when showPulse is true
                    if showPulse {
                        // Inner pulse
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(textColor.opacity(0.5), lineWidth: 1.5)
                            .scaleEffect(isPulsing ? 1.2 : 1.0)
                            .opacity(isPulsing ? 0.0 : 0.5)
                        
                        // Middle pulse with delay
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(textColor.opacity(0.3), lineWidth: 1)
                            .scaleEffect(isPulsing ? 1.1 : 1.0)
                            .opacity(isPulsing ? 0.0 : 0.3)
                        
                        // Outer pulse with longer delay and different timing
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(textColor.opacity(0.2), lineWidth: 0.5)
                            .scaleEffect(outerPulse ? 1.3 : 1.0)
                            .opacity(outerPulse ? 0.0 : 0.2)
                    }
                }
            )
            .foregroundColor(textColor)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3), value: configuration.isPressed)
            .onAppear {
                if showPulse {
                    startPulseAnimation()
                }
            }
            .onChange(of: showPulse) { _, newValue in
                if newValue {
                    startPulseAnimation()
                } else {
                    isPulsing = false
                    outerPulse = false
                }
            }
    }
    
    private func startPulseAnimation() {
        // Start main pulse
        withAnimation(Animation.easeOut(duration: 1.2).repeatForever(autoreverses: false)) {
            isPulsing = true
        }
        
        // Start outer pulse with delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(Animation.easeOut(duration: 1.5).repeatForever(autoreverses: false)) {
                outerPulse = true
            }
        }
    }
}


