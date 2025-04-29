import SwiftUI
import AppKit

struct SelectedTextDisplayView: View {
    let text: String
    @State private var animateGlow = false
    @State private var textDisplayHeight: CGFloat = 150
    @State private var isCopied = false
    @State private var selectedTextAnimation = false
    @Binding var isCodeText: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Selected Text")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
                
                Spacer()
                
                HStack(spacing: 8) {
                    Button(action: {
                        withAnimation {
                            if textDisplayHeight > 150 {
                                textDisplayHeight = 150
                            } else {
                                textDisplayHeight = 300
                            }
                        }
                    }) {
                        Image(systemName: textDisplayHeight > 150 ? "arrow.up.left.and.arrow.down.right" : "arrow.down.right.and.arrow.up.left")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .help(textDisplayHeight > 150 ? "Collapse text" : "Expand text")
                    
                    Button(action: {
                        toggleCodeDisplay()
                    }) {
                        Image(systemName: isCodeText ? "doc.text" : "chevron.left.forwardslash.chevron.right")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .help(isCodeText ? "View as regular text" : "View as code")
                    
                    Button(action: {
                        // Copy selected text to clipboard
                        let pasteboard = NSPasteboard.general
                        pasteboard.clearContents()
                        pasteboard.setString(text, forType: .string)
                        
                        // Show feedback
                        isCopied = true
                        
                        // Animate the label
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            selectedTextAnimation = true
                        }
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            withAnimation {
                                selectedTextAnimation = false
                            }
                        }
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            isCopied = false
                        }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                                .font(.system(size: 12))
                            if isCopied {
                                Text("Copied")
                                    .font(.caption)
                            }
                        }
                        .foregroundColor(isCopied ? .green : .secondary)
                        .padding(4)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 8)
            
            // Format selected text based on content type
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.blue.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    )
                    .shadow(color: Color.blue.opacity(animateGlow ? 0.2 : 0), radius: 8, x: 0, y: 0)
                
                ScrollView {
                    if isCodeText {
                        Text(text)
                            .font(.system(size: 13, design: .monospaced))
                            .padding(16)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        Text(text)
                            .font(.system(size: 14))
                            .padding(16)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .frame(height: textDisplayHeight)
            .scaleEffect(selectedTextAnimation ? 1.02 : 1)
            .onAppear {
                withAnimation(Animation.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                    animateGlow = true
                }
            }
        }
        .padding(.bottom, 8)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
    
    private func toggleCodeDisplay() {
        withAnimation {
            isCodeText.toggle()
        }
    }
}

struct CodeLanguageSelector: View {
    let languages = ["Auto", "Swift", "JavaScript", "Python", "Java", "HTML", "CSS", "Markdown"]
    @Binding var selectedLanguage: String
    
    var body: some View {
        Menu {
            ForEach(languages, id: \.self) { language in
                Button(action: {
                    selectedLanguage = language
                }) {
                    Text(language)
                    if selectedLanguage == language {
                        Image(systemName: "checkmark")
                    }
                }
            }
        } label: {
            HStack {
                Text(selectedLanguage)
                    .font(.caption)
                Image(systemName: "chevron.down")
                    .font(.system(size: 9))
            }
            .foregroundColor(.secondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(4)
        }
        .menuStyle(BorderlessButtonMenuStyle())
    }
} 