import SwiftUI
import Combine

struct AIPanelView: View {
    @EnvironmentObject var appState: AppState
    @State private var inputText: String = ""
    @State private var isLoading: Bool = false
    @State private var selectedOption: AIAction = .summarize
    @FocusState private var isInputFocused: Bool
    @State private var editedResponse: String = ""
    @State private var isEditing: Bool = false
    @State private var selectedStyle: ResponseStyle = .balanced
    @State private var isCopied: Bool = false
    @State private var isAppearing: Bool = false
    @State private var hoveredButton: String? = nil
    
    private let aiService = AIService()
    private let hotkeyManager = HotkeyManager()
    @State private var cancellables = Set<AnyCancellable>()
    
    private let buttonGradient = LinearGradient(
        gradient: Gradient(colors: [Color.blue, Color.purple]),
        startPoint: .leading, 
        endPoint: .trailing
    )
    
    enum AIAction: String, CaseIterable, Identifiable {
        case summarize = "Summarize"
        case explain = "Explain"
        case rewrite = "Rewrite"
        case translate = "Translate"
        case custom = "Custom"
        
        var id: String { self.rawValue }
        
        var systemPrompt: String {
            switch self {
            case .summarize: return "Summarize the following text concisely:"
            case .explain: return "Explain the following text in simple terms:"
            case .rewrite: return "Rewrite the following text to improve clarity and flow:"
            case .translate: return "Translate the following text to another language:"
            case .custom: return ""
            }
        }
    }
    
    // Extract complex button view into a separate component
    struct ActionButton: View {
        let action: AIAction
        let selectedOption: AIAction
        let buttonGradient: LinearGradient
        let onTap: (AIAction) -> Void
        
        var body: some View {
            Button(action: {
                onTap(action)
            }) {
                Text(action.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Color.secondary.opacity(0.1)
                    )
                    .foregroundColor(selectedOption == action ? .white : .primary)
                    .cornerRadius(16)
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // HEADER
            HStack {
                Text("AI Assistant")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button(action: {
                    withAnimation {
                        appState.isAIPanelVisible = false
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                        .font(.system(size: 16))
                }
            }
            .padding(.bottom, 4)
            
            // DIVIDER
            Divider()
            
            // CONTENT SECTION
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // SELECTED TEXT SECTION
                    selectedTextSection
                    
                    // ACTION SELECTION
                    actionSelectionSection
                    
                    // CUSTOM INPUT FIELD
                    if selectedOption == .custom || appState.emptySelectionMode {
                        customInputSection
                    }
                    
                    // SUBMIT BUTTON
                    submitButton
                    
                    // AI RESPONSE SECTION
                    if !appState.aiResponse.isEmpty || appState.isProcessing {
                        responseSection
                    }
                }
                .padding(.horizontal, 4)
            }
        }
        .padding()
        .frame(width: 380)
        .background(Color.primary.opacity(0.05))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
        .scaleEffect(isAppearing ? 1 : 0.95)
        .opacity(isAppearing ? 1 : 0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isAppearing)
        // .onAppear {
        //     selectedStyle = appState.responseStyle
            
        //     // Appear animation
        //     DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
        //         withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
        //             isAppearing = true
        //         }
        //     }
            
        //     // If text is selected, automatically generate a response
        //     if !appState.selectedText.isEmpty {
        //         DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
        //             generateResponse()
        //         }
        //     }
        // }
    }
    
    // Break down the body view into smaller components
    private var selectedTextSection: some View {
        Group {
            if !appState.selectedText.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Selected Text")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    Text(appState.selectedText)
                        .font(.body)
                        .padding(10)
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(8)
                }
            } else if appState.emptySelectionMode {
                VStack(alignment: .leading, spacing: 8) {
                    Text("No text selected")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    Text("Type your question below or select text from a document to get assistance.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(8)
                }
            }
        }
    }
    
    private var actionSelectionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("What would you like to do?")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            HStack(spacing: 10) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(AIAction.allCases) { action in
                            ActionButton(
                                action: action,
                                selectedOption: selectedOption,
                                buttonGradient: buttonGradient,
                                onTap: { selected in
                                    selectedOption = selected
                                }
                            )
                        }
                    }
                }
            }
        }
    }
    
    private var customInputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Your custom request")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            TextEditor(text: $inputText)
                .focused($isInputFocused)
                .font(.body)
                .padding(10)
                .frame(height: 100)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        isInputFocused = true
                    }
                }
        }
    }
    
    private var submitButton: some View {
        Button(action: {
            submitAction()
        }) {
            HStack {
                Spacer()
                Text("Process")
                    .fontWeight(.medium)
                Spacer()
            }
            .padding(.vertical, 12)
            .background(buttonGradient)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .disabled(appState.isProcessing || (appState.selectedText.isEmpty && inputText.isEmpty && appState.emptySelectionMode))
    }
    
    private var responseSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Response")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            if appState.isProcessing {
                HStack {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(1.0)
                    Spacer()
                }
                .frame(height: 100)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(8)
            } else {
                Text(appState.aiResponse)
                    .font(.body)
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(8)
            }
        }
    }
    
    private func submitAction() {
        let textToProcess = !appState.selectedText.isEmpty ? appState.selectedText : inputText
        
        if textToProcess.isEmpty {
            return
        }
        
        appState.isProcessing = true
        
        // Simulate AI processing
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            appState.aiResponse = simulateAIResponse(for: selectedOption, text: textToProcess)
            appState.isProcessing = false
            appState.saveInteraction()
        }
    }
    
    private func simulateAIResponse(for action: AIAction, text: String) -> String {
        let prefix: String
        
        switch action {
        case .summarize:
            prefix = "Summary: "
        case .explain:
            prefix = "Explanation: "
        case .rewrite:
            prefix = "Rewritten version: "
        case .translate:
            prefix = "Translated text: "
        case .custom:
            prefix = "Response: "
        }
        
        return prefix + "This is a simulated AI response for the '\(action.rawValue)' action based on the " + (appState.selectedText.isEmpty ? "input" : "selected") + " text. In a real implementation, this would connect to an AI service to process your request."
    }
    
}

#Preview {
    AIPanelView()
        .environmentObject(AppState())
        .preferredColorScheme(.light)
} 
