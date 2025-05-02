import SwiftUI
import AppKit

struct SelectedTextView: View {
    // Access AppState for dynamic values
    @EnvironmentObject var appState: AppState
    @Environment(\.colorScheme) var colorScheme
    
    let displayedText: String
    let isVisible: Bool
    @State private var isHovered: Bool = false
    @State private var showCopiedNotification: Bool = false
    @State private var isExpanded: Bool = false
    @State private var copyButtonScale: CGFloat = 1.0
    
    // Calculate word count 
    private var wordCount: Int {
        displayedText.split(separator: " ").count
    }
    
    // Calculate character count
    private var characterCount: Int {
        displayedText.count
    }
    
    // Text truncation logic
    private var displayText: String {
        if isExpanded {
            return displayedText
        } else {
            // Get approximate number of characters we can display in the collapsed view
            let lineHeight: CGFloat = 20
            let maxCollapsedHeight: CGFloat = 120
            
            // Number of visible lines within the collapsed height (minus padding)
            let visibleLines = Int((maxCollapsedHeight - 32) / lineHeight)
            
            // Estimate based on lines and character count
            let lines = displayedText.components(separatedBy: "\n")
            
            if lines.count > visibleLines {
                // More lines than we can display
                return lines.prefix(visibleLines).joined(separator: "\n") + "\n..."
            } else if displayedText.count > visibleLines * 60 {
                // Approximate character cutoff based on visible lines and estimated chars per line
                let maxChars = visibleLines * 60
                let index = displayedText.index(displayedText.startIndex, offsetBy: min(maxChars, displayedText.count))
                return displayedText.count > maxChars ? 
                    String(displayedText[..<index]) + "..." : 
                    displayedText
            }
            
            return displayedText
        }
    }
    
    // Get accent color dynamically based on app state and color scheme
    private var accentColor: Color {
        appState.isDarkMode || colorScheme == .dark ? Color.blue : Color.blue.opacity(0.8)
    }
    
    // Background color based on color scheme
    private var cardBackgroundColor: Color {
        appState.isDarkMode || colorScheme == .dark ? 
            Color(NSColor(red: 32/255, green: 32/255, blue: 36/255, alpha: 1.0)) : 
            Color(NSColor.windowBackgroundColor)
    }
    
    // Text background color based on color scheme
    private var textBackgroundColor: Color {
        appState.isDarkMode || colorScheme == .dark ? 
            Color(NSColor(red: 28/255, green: 28/255, blue: 30/255, alpha: 1.0)) : 
            Color(NSColor.textBackgroundColor)
    }
    
    // Stats background color
    private var statsBackgroundColor: Color {
        appState.isDarkMode || colorScheme == .dark ?
            Color.gray.opacity(0.2) :
            Color.gray.opacity(0.1)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Main content card
            VStack(alignment: .leading, spacing: 0) {
                // Text content
                ZStack(alignment: .topTrailing) {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 0) {
                            Text(displayText)
                                .font(.system(size: 14, weight: .regular))
                                .lineSpacing(5)
                                .foregroundColor(.primary)
                                .padding(16)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            // Show a subtle fade indicator at the bottom when text is truncated
                            if shouldShowExpandButton() && !isExpanded {
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        textBackgroundColor.opacity(0),
                                        textBackgroundColor.opacity(0.8),
                                        textBackgroundColor
                                    ]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                                .frame(height: 24)
                                .padding(.top, -24)
                            }
                        }
                    }
                    .frame(height: calculateTextHeight())
                    .background(textBackgroundColor)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    // Copy button overlay
                    Button(action: {
                        copyToClipboard(displayedText)
                        
                        // Button animation
                        withAnimation(.spring(response: 0.2)) {
                            copyButtonScale = 0.8
                        }
                        
                        // Reset scale
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation(.spring(response: 0.2)) {
                                copyButtonScale = 1.2
                            }
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                withAnimation(.spring(response: 0.2)) {
                                    copyButtonScale = 1.0
                                }
                            }
                        }
                        
                        // Show notification
                        withAnimation(.spring(response: 0.3)) {
                            showCopiedNotification = true
                        }
                        
                        // Hide notification after delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            withAnimation(.easeOut(duration: 0.5)) {
                                showCopiedNotification = false
                            }
                        }
                    }) {
                        ZStack {
                            Circle()
                                .fill(colorScheme == .dark ? Color(white: 0.2) : Color.white.opacity(0.95))
                                .frame(width: 32, height: 32)
                                .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                            
                            Image(systemName: "doc.on.doc")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(accentColor)
                        }
                        .scaleEffect(copyButtonScale)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .opacity(isHovered ? 1.0 : 0.0)
                    .padding(12)
                }
                
                // Footer with stats and expand button
                HStack {
                    // Stats
                    HStack(spacing: 8) {
                        Text("\(characterCount) chars")
                            .font(.system(size: 8))
                            .foregroundColor(.secondary)
                        
                        Text("•")
                            .font(.system(size: 8))
                            .foregroundColor(.secondary)
                        
                        Text("\(wordCount) words")
                            .font(.system(size: 8))
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statsBackgroundColor)
                    .cornerRadius(8)
                    
                    Spacer()
                    
                    // Copy notification
                    if showCopiedNotification {
                        Text("Copied to clipboard")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(Color.green)
                                    .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                            )
                            .transition(.scale.combined(with: .opacity))
                    }
                    
                    // Expand button
                    if shouldShowExpandButton() {
                        Button(action: {
                            withAnimation(.spring(response: 0.4)) {
                                isExpanded.toggle()
                            }
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                    .font(.system(size: 10, weight: .bold))
                                
                                Text(isExpanded ? "Collapse" : "Expand")
                                    .font(.system(size: 12, weight: .medium))
                            }
                            .foregroundColor(accentColor)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 5)
                            .background(accentColor.opacity(0.1))
                            .cornerRadius(12)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .contentShape(Rectangle())
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                .frame(height: 24)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(cardBackgroundColor.opacity(0.8))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(cardBackgroundColor)
                    .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.1), radius: 5, x: 0, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(colorScheme == .dark ? 0.3 : 0.15), lineWidth: 1)
            )
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .transition(.asymmetric(
            insertion: .scale(scale: 0.9).combined(with: .opacity),
            removal: .scale(scale: 0.9).combined(with: .opacity)
        ))
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isVisible)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
    }
    
    // Copy to clipboard function
    private func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        
        // Also update the appState if needed
        appState.updateSelectedText(text, source: .clipboard)
    }
    
    // Calculate dynamic height based on text content
    private func calculateTextHeight() -> CGFloat {
        if isExpanded {
            return 200  // Maximum expanded height
        } else {
            // Calculate approximate height based on text content
            let lineHeight: CGFloat = 20  // Approximate height per line including spacing
            let minHeight: CGFloat = 60   // Minimum height for any content
            let maxCollapsedHeight: CGFloat = 60 // Maximum height when collapsed
            
            // Count lines (explicitly shown newlines plus estimated line wraps)
            var explicitLineCount = displayedText.components(separatedBy: "\n").count
            
            // Estimate additional wrapped lines based on character count
            // Assuming approximately 60 characters per line for the given width
            let charsPerLine = 60
            let textLength = displayedText.count
            let estimatedWrappedLines = textLength / charsPerLine
            
            // Total estimated lines
            let totalEstimatedLines = max(explicitLineCount, estimatedWrappedLines)
            
            // Calculate height based on line count with padding
            let calculatedHeight = CGFloat(totalEstimatedLines) * lineHeight + 32  // 32px for padding
            
            // Return constrained height
            return min(max(calculatedHeight, minHeight), maxCollapsedHeight)
        }
    }
    
    // Determine if we should show the expand button
    private func shouldShowExpandButton() -> Bool {
        if isExpanded {
            // Always show when expanded (to collapse)
            return true
        }
        
        // Check if text is truncated
        let lineHeight: CGFloat = 20
        let maxCollapsedHeight: CGFloat = 120
        let visibleLines = Int((maxCollapsedHeight - 32) / lineHeight)
        let charsPerLine = 60
        let maxVisibleChars = visibleLines * charsPerLine
        
        // Show button if:
        // 1. The text has more lines than can be displayed
        // 2. The text has more characters than can be comfortably displayed
        let lines = displayedText.components(separatedBy: "\n")
        return lines.count > visibleLines || displayedText.count > maxVisibleChars
    }
}

struct SelectedTextView_Previews: PreviewProvider {
    static var previews: some View {
        let appState = AppState()
        
        Group {
            VStack {
                SelectedTextView(
                    displayedText: "This is a sample text that would be selected by the user.\nIt demonstrates how the component displays and handles the selected text from another application.\nThis is the third line of text.\nThis is the fourth line of text.\nThis line should be hidden initially.",
                    isVisible: true
                )
                
                SelectedTextView(
                    displayedText: "This is a shorter sample text with no line breaks that fits within the initial view.",
                    isVisible: true
                )
            }
            .frame(width: 500)
            .padding()
            .preferredColorScheme(.dark)
            .environmentObject(appState)
            
            VStack {
                SelectedTextView(
                    displayedText: "This is a sample text that would be selected by the user.\nIt demonstrates how the component displays and handles the selected text from another application.\nThis is the third line of text.\nThis is the fourth line of text.\nThis line should be hidden initially.",
                    isVisible: true
                )
                
                SelectedTextView(
                    displayedText: "This is a shorter sample text with no line breaks that fits within the initial view.",
                    isVisible: true
                )
            }
            .frame(width: 500)
            .padding()
            .preferredColorScheme(.light)
            .environmentObject(appState)
        }
    }
} 