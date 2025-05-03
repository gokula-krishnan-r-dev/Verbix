import SwiftUI
import AppKit
import Combine

struct AIPromptField: View {
    @Binding var searchQuery: String
    @Binding var isProcessing: Bool
    @Binding var selectedTab: AIPromptTab
    @Binding var aiModel: String
    
    var onSubmit: () -> Void
    var onCancel: () -> Void
    
    @FocusState private var searchQueryIsFocused: Bool
    @Binding var focusedField: FocusableField?
    
    // Enum for tabs that can be customized by parent
    public enum AIPromptTab {
        case blank
        case withContent
        case custom(String)
    }
    
    // Focus fields enum to be used by parent
    public enum FocusableField: Hashable {
        case searchField
        case actionButton(Int)
        case copyButton
        case insertButton
        case regenerateButton
        case custom(String)
    }
    
    init(
        searchQuery: Binding<String>,
        isProcessing: Binding<Bool>,
        selectedTab: Binding<AIPromptTab>,
        aiModel: Binding<String>,
        focusedField: Binding<FocusableField?>,
        onSubmit: @escaping () -> Void,
        onCancel: @escaping () -> Void
    ) {
        self._searchQuery = searchQuery
        self._isProcessing = isProcessing
        self._selectedTab = selectedTab
        self._aiModel = aiModel
        self._focusedField = focusedField
        self.onSubmit = onSubmit
        self.onCancel = onCancel
    }
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                // Action icon
                ZStack {
                    Image(systemName: "wand.and.stars")
                        .font(.system(size: 16))
                        .foregroundColor(isProcessing ? .gray : .blue)
                        .opacity(0.8)
                        .scaleEffect(searchQuery.isEmpty ? 1.0 : 0.9)
                    
                    if isProcessing {
                        Circle()
                            .stroke(Color.blue, lineWidth: 1.5)
                            .frame(width: 24, height: 24)
                            .opacity(0.7)
                            .scaleEffect(isProcessing ? 1.2 : 0.8)
                            .opacity(isProcessing ? 0.0 : 0.8)
                            .animation(
                                Animation.easeInOut(duration: 1.2)
                                    .repeatForever(autoreverses: false),
                                value: isProcessing
                            )
                    }
                }
                .animation(.spring(response: 0.3), value: searchQuery.isEmpty)
                .animation(.spring(response: 0.3), value: isProcessing)
                
                // Text field for search or prompt
                TextField("Ask AI to...", text: $searchQuery)
                    .onSubmit {
                        if !self.searchQuery.isEmpty && !self.isProcessing {
                            self.onSubmit()
                        }
                    }
                    .focused($searchQueryIsFocused)
                    .disableAutocorrection(true)
                    .textFieldStyle(PlainTextFieldStyle())
                    .foregroundColor(.primary)
                    .font(.system(size: 15))
                    .background(Color(NSColor.windowBackgroundColor))
                    .disabled(isProcessing)
                    .opacity(isProcessing ? 0.7 : 1.0)
                    .overlay(
                        focusedField == .searchField ? 
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color.blue, lineWidth: 1.5)
                                .padding(-4) : nil
                    )
                
                // Clear button that appears when text is entered and not processing
                if !searchQuery.isEmpty && !isProcessing {
                    Button(action: {
                        self.searchQuery = ""
                        // Re-focus the text field after clearing
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            self.searchQueryIsFocused = true
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
                
                // Ask/Cancel button
                if !searchQuery.isEmpty {
                    Button(action: {
                        if self.isProcessing {
                            // Cancel operation
                            self.onCancel()
                        } else {
                            // Start operation
                            self.onSubmit()
                        }
                    }) {
                        HStack(spacing: 4) {
                            if isProcessing {
                                Text("Cancel")
                                Image(systemName: "stop.circle.fill")
                            } else {
                                Text("Ask")
                                Image(systemName: "arrow.up.circle.fill")
                            }
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(isProcessing ? Color.orange : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(16)
                        .shadow(color: isProcessing ? Color.orange.opacity(0.3) : Color.blue.opacity(0.3), radius: 2, x: 0, y: 1)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .transition(.scale.combined(with: .opacity))
                    .animation(.spring(response: 0.4), value: !searchQuery.isEmpty)
                    .animation(.spring(response: 0.4), value: isProcessing)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(NSColor.windowBackgroundColor))
            
            // Model indicator and status
            HStack {
                HStack(spacing: 4) {
                    Text("Model:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(aiModel)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(4)
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                if case .withContent = selectedTab {
                    Text("Using selected text")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(4)
                } else if case .custom(let label) = selectedTab {
                    Text(label)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.purple.opacity(0.1))
                        .cornerRadius(4)
                }
                
                if isProcessing {
                    HStack(spacing: 4) {
                        ProgressView()
                            .scaleEffect(0.5)
                            .frame(width: 12, height: 12)
                        
                        Text("Processing...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .transition(.opacity)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
            .animation(.easeInOut(duration: 0.2), value: isProcessing)
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                searchQueryIsFocused = true
                focusedField = .searchField
            }
        }
    }
}

// MARK: - Preview Provider
struct AIPromptField_Previews: PreviewProvider {
    static var previews: some View {
        @State var searchQuery = ""
        @State var isProcessing = false
        @State var selectedTab = AIPromptField.AIPromptTab.blank
        @State var aiModel = "@cf/meta/llama-3.3-70b-instruct-fp8-fast"
        @State var focusedField: AIPromptField.FocusableField? = .searchField
        
        return AIPromptField(
            searchQuery: $searchQuery, 
            isProcessing: $isProcessing,
            selectedTab: $selectedTab,
            aiModel: $aiModel,
            focusedField: $focusedField,
            onSubmit: {},
            onCancel: {}
        )
        .frame(width: 640)
        .background(Color(NSColor.windowBackgroundColor))
        .previewLayout(.sizeThatFits)
    }
} 
