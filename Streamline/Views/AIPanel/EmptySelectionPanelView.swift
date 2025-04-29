import SwiftUI
import AppKit

struct EmptySelectionPanelView: View {
    @EnvironmentObject var appState: AppState
    @State private var inputText: String = ""
    @State private var isTyping: Bool = false
    @State private var isAppearing: Bool = false
    @State private var selectedSuggestion: String?
    @State private var hoveredAction: String?
    private let hotkeyManager = HotkeyManager()
    
    var body: some View {
        VStack(spacing: 0) {
            // Slack-like Header with app icon
            HStack(spacing: 12) {
                Image(systemName: "message.and.waveform.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.primary)
                
                Text("EveryChat")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("Start blank")
                    .font(.subheadline)
                    .foregroundColor(.blue)
                
                Button(action: {
                    // Open customization or settings
                }) {
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isAppearing = false
                        
                        // Delay closure of panel to allow animation to complete
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                            appState.isAIPanelVisible = false
                            appState.emptySelectionMode = false
                        }
                    }
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
            .background(Color(NSColor.windowBackgroundColor))
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(Color.gray.opacity(0.2)),
                alignment: .bottom
            )
            
            // Main content area
            VStack(alignment: .leading, spacing: 16) {
                // Input field
                VStack(alignment: .leading, spacing: 8) {
                    // Text input field with magnifying glass icon
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                            .font(.system(size: 16))
                        
                        TextField("Ask anything...", text: $inputText, onEditingChanged: { editing in
                            isTyping = editing
                        })
                        .font(.body)
                        .textFieldStyle(PlainTextFieldStyle())
                        .onSubmit {
                            submitQuery()
                        }
                        
                        if !inputText.isEmpty {
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    inputText = ""
                                }
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                                    .font(.system(size: 14))
                            }
                            .buttonStyle(PlainButtonStyle())
                            .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .padding(8)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isTyping ? Color.blue : Color.clear, lineWidth: 2)
                    )
                    .animation(.easeInOut(duration: 0.2), value: isTyping)
                    
                    // // Suggestion chips
                    // ScrollView(.horizontal, showsIndicators: false) {
                    //     HStack(spacing: 8) {
                    //         SuggestionChip(text: "Summarize selected text", isSelected: selectedSuggestion == "Summarize selected text") {
                    //             selectSuggestion("Summarize selected text")
                    //         }
                    //         SuggestionChip(text: "Draft a response", isSelected: selectedSuggestion == "Draft a response") {
                    //             selectSuggestion("Draft a response")
                    //         }
                    //         SuggestionChip(text: "Explain concept", isSelected: selectedSuggestion == "Explain concept") {
                    //             selectSuggestion("Explain concept")
                    //         }
                    //         SuggestionChip(text: "Improve writing", isSelected: selectedSuggestion == "Improve writing") {
                    //             selectSuggestion("Improve writing")
                    //         }
                    //     }
                    //     .padding(.vertical, 4)
                    // }
                }
                
                // if !isTyping && inputText.isEmpty && selectedSuggestion == nil {
                //     // Quick action examples
                //     Text("Quick actions")
                //         .font(.headline)
                //         .foregroundColor(.primary)
                //         .padding(.top, 8)
                    
                //     VStack(alignment: .leading, spacing: 12) {
                //         QuickActionRow(
                //             icon: "wand.and.stars", 
                //             title: "Write a draft email",
                //             description: "Reply to client about project status",
                //             isHovered: hoveredAction == "email"
                //         ) {
                //             selectAction("Write a professional email reply to our client about the project status update")
                //         }
                //         .onHover { isHovered in
                //             withAnimation(.easeInOut(duration: 0.2)) {
                //                 hoveredAction = isHovered ? "email" : nil
                //             }
                //         }
                        
                //         QuickActionRow(
                //             icon: "text.badge.checkmark", 
                //             title: "Summarize text",
                //             description: "Condense selected text into key points", 
                //             isHovered: hoveredAction == "summarize"
                //         ) {
                //             selectAction("Summarize the following text into key bullet points")
                //         }
                //         .onHover { isHovered in
                //             withAnimation(.easeInOut(duration: 0.2)) {
                //                 hoveredAction = isHovered ? "summarize" : nil
                //             }
                //         }
                        
                //         QuickActionRow(
                //             icon: "lightbulb", 
                //             title: "Generate ideas", 
                //             description: "Brainstorm solutions for a problem",
                //             isHovered: hoveredAction == "ideas"
                //         ) {
                //             selectAction("Generate 5 creative ideas to solve the following problem")
                //         }
                //         .onHover { isHovered in
                //             withAnimation(.easeInOut(duration: 0.2)) {
                //                 hoveredAction = isHovered ? "ideas" : nil
                //             }
                //         }
                //     }
                // }
                
                // // Run button at the bottom
                // if !inputText.isEmpty || selectedSuggestion != nil {
                //     HStack {
                //         Spacer()
                        
                //         Button(action: submitQuery) {
                //             HStack(spacing: 6) {
                //                 Text("Run")
                //                     .fontWeight(.medium)
                                
                //                 Image(systemName: "arrow.right")
                //                     .font(.system(size: 12))
                //             }
                //             .foregroundColor(.white)
                //             .padding(.horizontal, 16)
                //             .padding(.vertical, 8)
                //             .background(Color.blue)
                //             .cornerRadius(6)
                //         }
                //         .keyboardShortcut(.return, modifiers: [])
                //         .buttonStyle(PlainButtonStyle())
                //         .shadow(color: Color.blue.opacity(0.3), radius: 5, x: 0, y: 2)
                //     }
                //     .padding(.top, 8)
                // }
            }
            .padding(16)
        }
        .padding()
        .frame(width: 380)
        .background(Color.primary.opacity(0.05))
        .cornerRadius(12)
        .shadow(
            color: Color.black.opacity(0.3),
            radius: 28,
            x: 0,
            y: 10
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
        )
        .scaleEffect(isAppearing ? 1 : 0.95)
        .opacity(isAppearing ? 1 : 0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isAppearing)
        .onAppear {
            // Focus the text field when the view appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                NSApp.keyWindow?.makeFirstResponder(nil)
                withAnimation {
                    isAppearing = true
                }
            }
        }
    }
    
    private func selectSuggestion(_ suggestion: String) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            if selectedSuggestion == suggestion {
                selectedSuggestion = nil
            } else {
                selectedSuggestion = suggestion
                inputText = ""
            }
        }
    }
    
    private func selectAction(_ prompt: String) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            inputText = prompt
        }
    }
    
    private func submitQuery() {
        if !inputText.isEmpty || selectedSuggestion != nil {
            // Use either inputText or the selected suggestion
            let prompt = !inputText.isEmpty ? inputText : (selectedSuggestion ?? "")
            
            // Close this panel with animation
            withAnimation(.easeInOut(duration: 0.2)) {
                isAppearing = false
            }
            
            // Show the AI panel with the entered text after delay for animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                appState.emptySelectionMode = false
                let floatingPanel = FloatingPanelController()
                floatingPanel.showPanel(with: prompt, appState: appState)
                inputText = ""
                selectedSuggestion = nil
            }
        }
    }
}

// Supporting components
struct SuggestionChip: View {
    let text: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.subheadline)
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.blue : Color(NSColor.controlBackgroundColor))
                .cornerRadius(16)
                .shadow(color: isSelected ? Color.blue.opacity(0.3) : Color.clear, radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

struct QuickActionRow: View {
    let icon: String
    let title: String
    let description: String
    let isHovered: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(isHovered ? .blue : .secondary)
                    .frame(width: 24, height: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .opacity(isHovered ? 1 : 0.6)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(NSColor.controlBackgroundColor).opacity(isHovered ? 0.8 : 0.5))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isHovered ? Color.blue.opacity(0.3) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// Preview
struct EmptySelectionPanelView_Previews: PreviewProvider {
    static var previews: some View {
        EmptySelectionPanelView()
            .environmentObject(AppState())
            .preferredColorScheme(.light)
    }
} 