import SwiftUI
// Make sure we can access the SelectedTextView component
// No need for additional imports since the component is in the same module

struct SelectedTextViewDemo: View {
    @State private var selectedSample: Int = 0
    @State private var isVisible: Bool = true
    
    // Sample text variations
    private let samples = [
        "This is a short sample text that fits in the view without truncation.",
        
        "This is a longer sample text that would be truncated because it exceeds the character limit. It demonstrates how the component handles longer text and provides an expand option to view the full content. The user can interact with this component to see more of the text if needed.",
        
        "This is a multi-line sample text.\nIt demonstrates how the component displays text with line breaks.\nThis is the third line of text.\nThis is the fourth line of text.\nThis line should be hidden initially until the user clicks expand.",
        
        "# Sample Markdown\n\nThis text mimics markdown formatting to show how the view handles structured text:\n\n- First bullet point\n- Second bullet point with **emphasis**\n\nCode example: `print(\"Hello world\")`"
    ]
    
    var body: some View {
        VStack(spacing: 24) {
            Text("SelectedTextView Demo")
                .font(.headline)
            
            // Controls
            VStack(spacing: 12) {
                // Sample selector
                Picker("Text Sample", selection: $selectedSample) {
                    Text("Short Text").tag(0)
                    Text("Long Text").tag(1)
                    Text("Multi-line").tag(2)
                    Text("Markdown-like").tag(3)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                // Action buttons
                HStack(spacing: 16) {
                    Button("Toggle Visibility") {
                        withAnimation {
                            isVisible.toggle()
                        }
                    }
                    .buttonStyle(BorderedButtonStyle())
                }
            }
            .padding(.horizontal)
            
            // Description
            Text("Selected sample: \(selectedSample + 1) of \(samples.count)")
                .font(.caption)
                .foregroundColor(.secondary)
            
            // Display the component
            if isVisible {
                SelectedTextView(displayedText: samples[selectedSample], isVisible: isVisible)
                    .frame(width: 550)
            }
            
            // Instructions
            VStack(alignment: .leading, spacing: 4) {
                Text("Instructions:")
                    .font(.caption)
                    .fontWeight(.bold)
                Text("• Hover over the card to see the copy button")
                    .font(.caption)
                Text("• Click 'Expand' to see more text if available")
                    .font(.caption)
                Text("• Try different text samples using the segmented control")
                    .font(.caption)
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
            .padding(.horizontal)
            
            Spacer()
        }
        .padding(.vertical, 32)
        .frame(width: 600, height: 550)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

struct SelectedTextViewDemo_Previews: PreviewProvider {
    static var previews: some View {
        SelectedTextViewDemo()
            .preferredColorScheme(.dark)
        
        SelectedTextViewDemo()
            .preferredColorScheme(.light)
    }
} 