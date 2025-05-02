import SwiftUI
import AppKit

struct SelectedTextView: View {
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
            // Get first 4 lines or less
            let lines = displayedText.split(separator: "\n", maxSplits: 4, omittingEmptySubsequences: false)
            if lines.count > 4 {
                return lines.prefix(4).joined(separator: "\n") + "\n..."
            } else {
                // If no line breaks, limit to about 200 characters
                if displayedText.count > 200 && !displayedText.contains("\n") {
                    let index = displayedText.index(displayedText.startIndex, offsetBy: 200)
                    return String(displayedText[..<index]) + "..."
                }
                return displayedText
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Main content card
            VStack(alignment: .leading, spacing: 0) {
                // Text content
                ZStack(alignment: .topTrailing) {
                    ScrollView {
                        Text(displayText)
                            .font(.system(size: 14, weight: .regular))
                            .lineSpacing(5)
                            .foregroundColor(.primary)
                            .padding(16)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(height: isExpanded ? 200 : 120)
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
                                .fill(Color.white.opacity(0.95))
                                .frame(width: 32, height: 32)
                                .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                            
                            Image(systemName: "doc.on.doc")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Color.blue)
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
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                        
                        Text("•")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                        
                        Text("\(wordCount) words")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                    
                    Spacer()
                    
                    // Copy notification
                    if showCopiedNotification {
                        Text("Copied to clipboard")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(
                                Capsule()
                                    .fill(Color.green)
                                    .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                            )
                            .transition(.scale.combined(with: .opacity))
                    }
                    
                    // Expand button
                    if displayedText.count > 200 || displayedText.contains("\n") {
                        Button(action: {
                            withAnimation(.spring(response: 0.4)) {
                                isExpanded.toggle()
                            }
                        }) {
                            Text(isExpanded ? "Collapse" : "Expand")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.blue)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 5)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(12)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .frame(height: 36)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(Color(NSColor.controlBackgroundColor).opacity(0.8))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(NSColor.windowBackgroundColor))
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.15), lineWidth: 1)
            )
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
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
    }
}

struct SelectedTextView_Previews: PreviewProvider {
    static var previews: some View {
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
    }
} 