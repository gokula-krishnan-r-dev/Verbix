import SwiftUI

// MARK: - Documentation
/**
 # Rich Text Formatter
 
 A powerful text formatter for SwiftUI that implements markdown-style formatting.
 
 ## Features
 - **Bold text** with double asterisks
 - _Italic text_ with underscores
 - `Code blocks` with backticks
 - Headers with # symbols (# ## ###)
 - Bullet lists (- * +) and numbered lists (1. 2.)
 - Block quotes (> text)
 - Horizontal rules (---)
 - Links ([text](url))
 - Line breaks (/n)
 
 ## Usage
 ```swift
 FormattedTextView("**Hello World**")
 ```
 
 ## Configuration
 You can customize font size, text color, alignment, and line spacing:
 ```swift
 FormattedTextView(
     text,
     fontSize: 16,
     textColor: .primary,
     alignment: .leading,
     lineSpacing: 6
 )
 ```
 */

// MARK: - Formatted Text View
/// A view that renders formatted text with markdown-style syntax
/// - Supports **bold text** for bold formatting
/// - Automatically converts /n to line breaks
/// - Allows customization of text appearance
public struct FormattedTextView: View {
    private let text: String
    private let fontSize: CGFloat
    private let textColor: Color
    private let alignment: TextAlignment
    private let lineSpacing: CGFloat
    private let documentStyle: DocumentStyle
    
    /// Document styling options for the formatted text
    public enum DocumentStyle {
        /// Standard document with default styling
        case standard
        /// Academic paper style with serif fonts, increased line spacing
        case academic
        /// Modern magazine style with dynamic fonts and spacing
        case magazine
        /// Compact technical documentation style
        case technical
        /// Custom style with specified parameters
        case custom(primaryFont: Font, headerFont: Font, codeFont: Font)
        
        /// Returns the body text font for this document style
        func bodyFont(size: CGFloat) -> Font {
            switch self {
            case .standard:
                return .system(size: size)
            case .academic:
                return .system(size: size, design: .serif)
            case .magazine:
                return .system(size: size, weight: .light, design: .rounded)
            case .technical:
                return .system(size: size, design: .monospaced)
            case .custom(let primaryFont, _, _):
                return primaryFont
            }
        }
        
        /// Returns the header font for this document style
        func headingFont(size: CGFloat, level: Int) -> Font {
            switch self {
            case .standard:
                return .system(size: size, weight: .bold)
            case .academic:
                return .system(size: size, weight: .bold, design: .serif)
            case .magazine:
                return .system(size: size, weight: .heavy, design: .rounded)
            case .technical:
                return .system(size: size, weight: .bold)
            case .custom(_, let headerFont, _):
                return headerFont
            }
        }
        
        /// Returns the code font for this document style
        func codeFont(size: CGFloat) -> Font {
            switch self {
            case .standard, .academic, .magazine, .technical:
                return .system(size: size, design: .monospaced)
            case .custom(_, _, let codeFont):
                return codeFont
            }
        }
        
        /// Returns the appropriate horizontal padding for sections
        var sectionPadding: CGFloat {
            switch self {
            case .standard:
                return 4
            case .academic:
                return 8
            case .magazine:
                return 12
            case .technical:
                return 6
            case .custom:
                return 8
            }
        }
    }
    
    public init(
        _ text: String,
        fontSize: CGFloat = 15,
        textColor: Color = .primary,
        alignment: TextAlignment = .leading,
        lineSpacing: CGFloat = 4,
        documentStyle: DocumentStyle = .standard
    ) {
        self.text = text
        self.fontSize = fontSize
        self.textColor = textColor
        self.alignment = alignment
        self.lineSpacing = lineSpacing
        self.documentStyle = documentStyle
    }
    
    public var body: some View {
        formattedText
            .frame(maxWidth: .infinity, alignment: alignment == .leading ? .leading : alignment == .trailing ? .trailing : .center)
    }
    
    private var formattedText: some View {
        let components = TextFormatter.parse(text)
        
        return VStack(alignment: alignment == .leading ? .leading : alignment == .trailing ? .trailing : .center, spacing: lineSpacing) {
            ForEach(components.indices, id: \.self) { index in
                let component = components[index]
                
                switch component.type {
                case .plainText:
                    Text(component.text)
                        .font(documentStyle.bodyFont(size: fontSize))
                        .foregroundColor(textColor)
                        .multilineTextAlignment(alignment)
                case .boldText:
                    Text(component.text)
                        .font(documentStyle.bodyFont(size: fontSize).bold())
                        .foregroundColor(textColor)
                        .multilineTextAlignment(alignment)
                case .italicText:
                    Text(component.text)
                        .font(documentStyle.bodyFont(size: fontSize).italic())
                        .foregroundColor(textColor)
                        .multilineTextAlignment(alignment)
                case .codeText:
                    Text(component.text)
                        .font(documentStyle.codeFont(size: fontSize))
                        .padding(4)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(4)
                        .foregroundColor(textColor)
                        .multilineTextAlignment(alignment)
                case .bulletPoint:
                    bulletPointView(text: component.text)
                case .numberedPoint(let number):
                    numberedPointView(text: component.text, number: number)
                case .header(let level):
                    headerView(text: component.text, level: level)
                case .quote:
                    quoteView(text: component.text)
                case .link(let url):
                    linkView(text: component.text, url: url)
                case .horizontalRule:
                    Divider()
                        .background(textColor.opacity(0.5))
                        .padding(.vertical, 8)
                }
            }
        }
    }
    
    // MARK: - Component Views
    
    private func bulletPointView(text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .font(documentStyle.bodyFont(size: fontSize))
                .foregroundColor(textColor)
            
            Text(text)
                .font(documentStyle.bodyFont(size: fontSize))
                .foregroundColor(textColor)
                .multilineTextAlignment(alignment)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.leading, documentStyle.sectionPadding)
    }
    
    private func numberedPointView(text: String, number: Int) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("\(number).")
                .font(documentStyle.bodyFont(size: fontSize))
                .foregroundColor(textColor)
                .frame(width: 24, alignment: .trailing)
            
            Text(text)
                .font(documentStyle.bodyFont(size: fontSize))
                .foregroundColor(textColor)
                .multilineTextAlignment(alignment)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.leading, documentStyle.sectionPadding)
    }
    
    private func headerView(text: String, level: Int) -> some View {
        let scale: CGFloat = switch level {
            case 1: 1.5
            case 2: 1.3
            case 3: 1.15
            case 4: 1.05
            default: 1.0
        }
        
        return Text(text)
            .font(documentStyle.headingFont(size: fontSize * scale, level: level))
            .foregroundColor(textColor)
            .multilineTextAlignment(alignment)
            .padding(.vertical, 4)
    }
    
    private func quoteView(text: String) -> some View {
        HStack(spacing: 12) {
            Rectangle()
                .fill(Color.gray.opacity(0.5))
                .frame(width: 3)
            
            Text(text)
                .font(documentStyle.bodyFont(size: fontSize))
                .italic()
                .foregroundColor(textColor.opacity(0.8))
                .multilineTextAlignment(alignment)
        }
        .padding(.vertical, 4)
    }
    
    private func linkView(text: String, url: URL) -> some View {
        Link(destination: url) {
            Text(text)
                .font(documentStyle.bodyFont(size: fontSize))
                .foregroundColor(.blue)
                .underline()
                .multilineTextAlignment(alignment)
        }
    }
}

// MARK: - Text Formatter
public struct TextFormatter {
    public struct TextComponent {
        public enum ComponentType {
            case plainText
            case boldText
            case italicText
            case codeText
            case bulletPoint
            case numberedPoint(number: Int)
            case header(level: Int)
            case quote
            case link(url: URL)
            case horizontalRule
        }
        
        public let text: String
        public let type: ComponentType
        
        public init(text: String, type: ComponentType) {
            self.text = text
            self.type = type
        }
    }
    
    public static func parse(_ text: String) -> [TextComponent] {
        // Replace /n with actual newlines
        var formattedText = text.replacingOccurrences(of: "/n", with: "\n")
        
        // Split the text by newlines
        let lines = formattedText.components(separatedBy: "\n")
        
        var components: [TextComponent] = []
        var numberedListCounter = 0
        
        for line in lines {
            if line.isEmpty {
                // Add empty line
                components.append(TextComponent(text: " ", type: .plainText))
                continue
            }
            
            // Check for horizontal rule
            if line.matches(pattern: "^-{3,}$") || line.matches(pattern: "^\\*{3,}$") {
                components.append(TextComponent(text: "", type: .horizontalRule))
                continue
            }
            
            // Check for headers (supports multiple levels #, ##, ###)
            if line.hasPrefix("#") {
                var level = 0
                var headerText = line
                
                // Count the number of # at the beginning
                while headerText.hasPrefix("#") && level < 6 {
                    level += 1
                    headerText.removeFirst()
                }
                
                // Get the header text and trim whitespace
                headerText = headerText.trimmingCharacters(in: .whitespaces)
                components.append(TextComponent(text: headerText, type: .header(level: level)))
                continue
            }
            
            // Check for blockquotes
            if line.hasPrefix(">") {
                let quoteText = line.dropFirst().trimmingCharacters(in: .whitespaces)
                components.append(TextComponent(text: quoteText, type: .quote))
                continue
            }
            
            // Check for bullet points
            if line.matches(pattern: "^[\\*\\-\\+]\\s+") {
                // Reset numbered list counter
                numberedListCounter = 0
                
                // Extract bullet text (after *, -, or + and whitespace)
                if let range = line.range(of: #"^[\*\-\+]\s+"#, options: .regularExpression) {
                    let bulletText = line[range.upperBound...].trimmingCharacters(in: .whitespaces)
                    components.append(TextComponent(text: bulletText, type: .bulletPoint))
                    continue
                }
            }
            
            // Check for numbered list
            if line.matches(pattern: "^\\d+\\.\\s+") {
                // Extract the number and text
                if let range = line.range(of: #"^\d+\.\s+"#, options: .regularExpression),
                   let numberString = line.prefix(upTo: range.lowerBound).last,
                   let number = Int(String(numberString)) {
                    let listText = line[range.upperBound...].trimmingCharacters(in: .whitespaces)
                    numberedListCounter = number
                    components.append(TextComponent(text: listText, type: .numberedPoint(number: number)))
                    continue
                } else {
                    // If the number can't be parsed, increment the counter
                    numberedListCounter += 1
                    if let range = line.range(of: #"^\d+\.\s+"#, options: .regularExpression) {
                        let listText = line[range.upperBound...].trimmingCharacters(in: .whitespaces)
                        components.append(TextComponent(text: listText, type: .numberedPoint(number: numberedListCounter)))
                        continue
                    }
                }
            }
            
            // Process formatting within the line
            var currentIndex = line.startIndex
            var currentText = ""
            var inBold = false
            var inItalic = false
            var inCode = false
            var inLink = false
            var linkText = ""
            
            while currentIndex < line.endIndex {
                let char = line[currentIndex]
                let nextIndex = line.index(after: currentIndex)
                
                // Check for bold (**text**)
                if char == "*" && nextIndex < line.endIndex && line[nextIndex] == "*" {
                    if inBold {
                        // End of bold text
                        if !currentText.isEmpty {
                            components.append(TextComponent(text: currentText, type: .boldText))
                            currentText = ""
                        }
                        inBold = false
                        currentIndex = line.index(currentIndex, offsetBy: 2)
                        if currentIndex >= line.endIndex { break }
                    } else {
                        // Start of bold text
                        if !currentText.isEmpty {
                            components.append(TextComponent(text: currentText, type: .plainText))
                            currentText = ""
                        }
                        inBold = true
                        currentIndex = line.index(currentIndex, offsetBy: 2)
                        if currentIndex >= line.endIndex { break }
                    }
                    continue
                }
                
                // Check for italic (_text_)
                if char == "_" {
                    if inItalic {
                        // End of italic text
                        if !currentText.isEmpty {
                            components.append(TextComponent(text: currentText, type: .italicText))
                            currentText = ""
                        }
                        inItalic = false
                    } else {
                        // Start of italic text
                        if !currentText.isEmpty {
                            components.append(TextComponent(text: currentText, type: .plainText))
                            currentText = ""
                        }
                        inItalic = true
                    }
                    currentIndex = nextIndex
                    continue
                }
                
                // Check for code (`text`)
                if char == "`" {
                    if inCode {
                        // End of code text
                        if !currentText.isEmpty {
                            components.append(TextComponent(text: currentText, type: .codeText))
                            currentText = ""
                        }
                        inCode = false
                    } else {
                        // Start of code text
                        if !currentText.isEmpty {
                            components.append(TextComponent(text: currentText, type: .plainText))
                            currentText = ""
                        }
                        inCode = true
                    }
                    currentIndex = nextIndex
                    continue
                }
                
                // Check for links [text](url)
                if char == "[" && !inLink && !inBold && !inItalic && !inCode {
                    // Start of link text
                    if !currentText.isEmpty {
                        components.append(TextComponent(text: currentText, type: .plainText))
                        currentText = ""
                    }
                    inLink = true
                    linkText = ""
                    currentIndex = nextIndex
                    continue
                } else if char == "]" && inLink && nextIndex < line.endIndex && line[nextIndex] == "(" {
                    // End of link text, start of URL
                    let urlStartIndex = line.index(nextIndex, offsetBy: 1)
                    if let urlEndIndex = line[urlStartIndex...].firstIndex(of: ")") {
                        let urlString = String(line[urlStartIndex..<urlEndIndex])
                        if let url = URL(string: urlString) {
                            components.append(TextComponent(text: linkText, type: .link(url: url)))
                        } else {
                            components.append(TextComponent(text: linkText, type: .plainText))
                        }
                        inLink = false
                        linkText = ""
                        currentText = ""
                        currentIndex = line.index(after: urlEndIndex)
                        continue
                    }
                } else if inLink {
                    // Add to link text
                    linkText.append(char)
                    currentIndex = nextIndex
                    continue
                }
                
                // Add the character to current text
                currentText.append(char)
                currentIndex = nextIndex
            }
            
            // Add any remaining text
            if !currentText.isEmpty {
                let type: TextComponent.ComponentType
                if inBold {
                    type = .boldText
                } else if inItalic {
                    type = .italicText
                } else if inCode {
                    type = .codeText
                } else {
                    type = .plainText
                }
                
                components.append(TextComponent(text: currentText, type: type))
            }
        }
        
        return components
    }
}

// MARK: - String Extensions
extension String {
    func matches(pattern: String) -> Bool {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return false }
        let range = NSRange(self.startIndex..., in: self)
        return regex.firstMatch(in: self, range: range) != nil
    }
}

// MARK: - Preview View
struct FormattedTextPreviewView: View {
    @State private var inputText: String = "# Markdown Text Formatter\n\nThis is a **rich text** formatter that supports various markdown features:\n\n## Formatting Options\n\n- **Bold text** with double asterisks\n- _Italic text_ with underscores\n- `Code blocks` with backticks\n\n### Lists\n\n1. Numbered lists work too\n2. Just start lines with numbers\n\n> This is a blockquote for important notes\n\n---\n\nYou can also include [links](https://www.apple.com) to websites.\n\nUse /n for manual line breaks."
    @State private var fontSize: Double = 16
    @State private var darkMode: Bool = false
    @State private var lineSpacing: Double = 6
    @State private var showPreview: Bool = true
    @State private var selectedTab: Int = 0
    @State private var selectedDocumentStyle: FormattedTextView.DocumentStyle = .standard
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with title and theme toggle
            header
            
            // Content tabs and preview
            VStack(spacing: 0) {
                HStack {
                    TabButton(title: "Editor", icon: "pencil", isSelected: selectedTab == 0) {
                        withAnimation { selectedTab = 0 }
                    }
                    
                    TabButton(title: "Preview", icon: "eye", isSelected: selectedTab == 1) {
                        withAnimation { selectedTab = 1 }
                    }
                    
                    TabButton(title: "Split View", icon: "rectangle.split.2x1", isSelected: selectedTab == 2) {
                        withAnimation { selectedTab = 2 }
                    }
                    
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 12)
                
                if selectedTab == 0 {
                    editorView
                } else if selectedTab == 1 {
                    previewView
                } else {
                    splitView
                }
            }
        }
        .frame(minWidth: 800, minHeight: 600)
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    private var header: some View {
        HStack {
            Image(systemName: "text.format")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.blue)
                .padding(8)
                .background(Color.blue.opacity(0.1))
                .clipShape(Circle())
            
            Text("Rich Text Formatter")
                .font(.headline)
                .foregroundColor(.primary)
            
            Spacer()
            
            HStack(spacing: 16) {
                // Document style picker
                HStack(spacing: 4) {
                    Text("Style:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
//                    Picker("", selection: $selectedDocumentStyle) {
//                        Text("Standard").tag(FormattedTextView.DocumentStyle.standard)
//                        Text("Academic").tag(FormattedTextView.DocumentStyle.academic)
//                        Text("Magazine").tag(FormattedTextView.DocumentStyle.magazine)
//                        Text("Technical").tag(FormattedTextView.DocumentStyle.technical)
//                    }
//                    .frame(width: 120)
                }
                
                // Font size control
                HStack(spacing: 8) {
                    Text("Text Size:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Button(action: { 
                        if fontSize > 12 { fontSize -= 1 }
                    }) {
                        Image(systemName: "minus.circle")
                            .foregroundColor(fontSize > 12 ? .blue : .gray)
                    }
                    .buttonStyle(BorderlessButtonStyle())
                    
                    Text("\(Int(fontSize))")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)
                        .frame(width: 24, alignment: .center)
                    
                    Button(action: { 
                        if fontSize < 24 { fontSize += 1 }
                    }) {
                        Image(systemName: "plus.circle")
                            .foregroundColor(fontSize < 24 ? .blue : .gray)
                    }
                    .buttonStyle(BorderlessButtonStyle())
                }
                
                // Line spacing control
                HStack(spacing: 8) {
                    Text("Spacing:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Slider(value: $lineSpacing, in: 2...12, step: 1)
                        .frame(width: 100)
                }
                
                // Theme toggle
                Toggle("Dark Mode", isOn: $darkMode)
                    .toggleStyle(SwitchToggleStyle(tint: .blue))
                    .padding(.horizontal)
            }
        }
        .padding()
        .background(Color(NSColor.windowBackgroundColor))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color.gray.opacity(0.3)),
            alignment: .bottom
        )
    }
    
    private var toolbarView: some View {
        HStack(spacing: 12) {
            FormatToolbarButton(title: "Bold", icon: "bold", action: { insertTag("**", "**") })
            FormatToolbarButton(title: "Italic", icon: "italic", action: { insertTag("_", "_") })
            FormatToolbarButton(title: "Code", icon: "chevron.left.forwardslash.chevron.right", action: { insertTag("`", "`") })
            
            Divider().frame(height: 20)
            
            FormatToolbarButton(title: "Heading", icon: "text.heading", action: { insertPrefix("# ") })
            FormatToolbarButton(title: "Bullet List", icon: "list.bullet", action: { insertPrefix("- ") })
            FormatToolbarButton(title: "Numbered List", icon: "list.number", action: { insertPrefix("1. ") })
            FormatToolbarButton(title: "Quote", icon: "text.quote", action: { insertPrefix("> ") })
            
            Divider().frame(height: 20)
            
            FormatToolbarButton(title: "Link", icon: "link", action: { insertTag("[", "](https://example.com)") })
            FormatToolbarButton(title: "Line Break", icon: "arrow.turn.down.right", action: { insertText("/n") })
            FormatToolbarButton(title: "Horizontal Rule", icon: "minus", action: { insertText("\n---\n") })
            
            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(Color(NSColor.textBackgroundColor).opacity(0.5))
    }
    
    private var editorView: some View {
        VStack(spacing: 0) {
            toolbarView
            
            TextEditor(text: $inputText)
                .font(.system(size: 14, design: .monospaced))
                .padding(16)
                .background(darkMode ? Color.black.opacity(0.7) : Color.white)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
                .padding(16)
        }
    }
    
    private var previewView: some View {
        VStack(spacing: 0) {
            // Preview content
            ScrollView {
                FormattedTextView(
                    inputText,
                    fontSize: CGFloat(fontSize),
                    textColor: darkMode ? .white : .primary,
                    alignment: .leading,
                    lineSpacing: CGFloat(lineSpacing),
                    documentStyle: selectedDocumentStyle
                )
                .padding(24)
                .background(darkMode ? Color.black.opacity(0.7) : Color.white)
                .cornerRadius(8)
                .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                .padding(16)
            }
            
            // Export buttons
            HStack {
                Spacer()
                
                Button(action: {
                    copyTextAsHTML()
                }) {
                    Label("Copy as HTML", systemImage: "doc.richtext")
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                }
                .buttonStyle(BorderedButtonStyle())
                
                Button(action: {
                    copyToClipboard(inputText)
                }) {
                    Label("Copy Markdown", systemImage: "doc.on.clipboard")
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                }
                .buttonStyle(BorderedButtonStyle())
                .padding(.leading, 8)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .animation(.easeInOut(duration: 0.2), value: inputText)
        .animation(.easeInOut(duration: 0.2), value: fontSize)
        .animation(.easeInOut(duration: 0.2), value: lineSpacing)
        .animation(.easeInOut(duration: 0.2), value: darkMode)
//        .animation(.easeInOut(duration: 0.2), value: selectedDocumentStyle)
    }
    
    private var splitView: some View {
        HStack(spacing: 0) {
            // Editor side
            VStack(spacing: 0) {
                toolbarView
                
                TextEditor(text: $inputText)
                    .font(.system(size: 14, design: .monospaced))
                    .padding(16)
                    .background(darkMode ? Color.black.opacity(0.7) : Color.white)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                    .padding(16)
            }
            
            // Divider
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 1)
                .padding(.vertical, 16)
            
            // Preview side
            ScrollView {
                FormattedTextView(
                    inputText,
                    fontSize: CGFloat(fontSize),
                    textColor: darkMode ? .white : .primary,
                    alignment: .leading,
                    lineSpacing: CGFloat(lineSpacing),
                    documentStyle: selectedDocumentStyle
                )
                .padding(24)
                .background(darkMode ? Color.black.opacity(0.7) : Color.white)
                .cornerRadius(8)
                .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                .padding(16)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: inputText)
        .animation(.easeInOut(duration: 0.2), value: fontSize)
        .animation(.easeInOut(duration: 0.2), value: lineSpacing)
        .animation(.easeInOut(duration: 0.2), value: darkMode)
    }
    
    // MARK: - Helper Methods
    
    private func insertTag(_ opening: String, _ closing: String) {
        // Get NSTextView from TextEditor
        let keyWindow = NSApplication.shared.keyWindow
        let contentView = keyWindow?.contentView
        let textView = findTextView(in: contentView)
        
        if let textView = textView, let selectedRange = textView.selectedRanges.first?.rangeValue {
            let selectedText = (inputText as NSString).substring(with: selectedRange)
            let taggedText = opening + selectedText + closing
            
            let mutableString = NSMutableString(string: inputText)
            mutableString.replaceCharacters(in: selectedRange, with: taggedText)
            inputText = mutableString as String
            
            // Update selection to be inside tags
            let newSelectionLocation = selectedRange.location + opening.count
            let newSelectionLength = selectedText.count
            let newRange = NSRange(location: newSelectionLocation, length: newSelectionLength)
            textView.setSelectedRange(newRange)
        } else {
            inputText.append(opening + closing)
        }
    }
    
    private func insertPrefix(_ prefix: String) {
        // Get NSTextView from TextEditor
        let keyWindow = NSApplication.shared.keyWindow
        let contentView = keyWindow?.contentView
        let textView = findTextView(in: contentView)
        
        if let textView = textView, let selectedRange = textView.selectedRanges.first?.rangeValue {
            let mutableString = NSMutableString(string: inputText)
            
            // Find the beginning of the line
            let text = inputText as NSString
            var lineStart = 0
            var lineEnd = 0
            var contentsEnd = 0
            
            text.getLineStart(&lineStart, end: &lineEnd, contentsEnd: &contentsEnd, for: NSRange(location: selectedRange.location, length: 0))
            
            // Insert prefix at the beginning of the line
            let lineRange = NSRange(location: lineStart, length: 0)
            mutableString.replaceCharacters(in: lineRange, with: prefix)
            inputText = mutableString as String
            
            // Update selection
            let newCursorLocation = selectedRange.location + prefix.count
            textView.setSelectedRange(NSRange(location: newCursorLocation, length: selectedRange.length))
        } else {
            inputText.append(prefix)
        }
    }
    
    private func insertText(_ text: String) {
        // Get NSTextView from TextEditor
        let keyWindow = NSApplication.shared.keyWindow
        let contentView = keyWindow?.contentView
        let textView = findTextView(in: contentView)
        
        if let textView = textView, let selectedRange = textView.selectedRanges.first?.rangeValue {
            let mutableString = NSMutableString(string: inputText)
            mutableString.replaceCharacters(in: selectedRange, with: text)
            inputText = mutableString as String
            
            // Update cursor position
            let newCursorLocation = selectedRange.location + text.count
            textView.setSelectedRange(NSRange(location: newCursorLocation, length: 0))
        } else {
            inputText.append(text)
        }
    }
    
    private func findTextView(in view: NSView?) -> NSTextView? {
        if let textView = view as? NSTextView {
            return textView
        }
        
        for subview in view?.subviews ?? [] {
            if let textView = findTextView(in: subview) {
                return textView
            }
        }
        
        return nil
    }
    
    // MARK: - Helper Methods for Export
    
    private func copyTextAsHTML() {
        let html = convertMarkdownToHTML(inputText)
        copyToClipboard(html)
        
        // Show brief success feedback
        let notification = NSUserNotification()
        notification.title = "Copied as HTML"
        notification.informativeText = "The formatted text has been copied as HTML to your clipboard"
        NSUserNotificationCenter.default.deliver(notification)
    }
    
    private func convertMarkdownToHTML(_ markdown: String) -> String {
        var html = markdown
        
        // Process line by line for headers and list items
        let lines = html.components(separatedBy: "\n")
        var processedLines: [String] = []
        
        for line in lines {
            var processedLine = line
            
            // Convert headers
            if let range = processedLine.range(of: #"^# (.*?)$"#, options: .regularExpression) {
                let headerContent = String(processedLine[range].dropFirst(2))
                processedLine = "<h1>\(headerContent)</h1>"
            } else if let range = processedLine.range(of: #"^## (.*?)$"#, options: .regularExpression) {
                let headerContent = String(processedLine[range].dropFirst(3))
                processedLine = "<h2>\(headerContent)</h2>"
            } else if let range = processedLine.range(of: #"^### (.*?)$"#, options: .regularExpression) {
                let headerContent = String(processedLine[range].dropFirst(4))
                processedLine = "<h3>\(headerContent)</h3>"
            }
            // Convert bullet lists
            else if let range = processedLine.range(of: #"^- (.*?)$"#, options: .regularExpression) {
                let listContent = String(processedLine[range].dropFirst(2))
                processedLine = "<li>\(listContent)</li>"
            }
            
            processedLines.append(processedLine)
        }
        
        // Rejoin lines
        html = processedLines.joined(separator: "\n")
        
        // Convert bold and italic (these work across multiple lines)
        html = html.replacingOccurrences(of: #"\*\*(.*?)\*\*"#, with: "<strong>$1</strong>", options: .regularExpression)
        html = html.replacingOccurrences(of: #"_(.*?)_"#, with: "<em>$1</em>", options: .regularExpression)
        
        // Convert code blocks
        html = html.replacingOccurrences(of: #"`(.*?)`"#, with: "<code>$1</code>", options: .regularExpression)
        
        // Add basic wrapper
        html = "<div style=\"font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; line-height: 1.5;\">\(html)</div>"
        
        return html
    }
    
    private func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
}

// MARK: - Supporting Views

struct TabButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                
                Text(title)
                    .font(.system(size: 13))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color.blue.opacity(0.2) : Color.clear)
            .foregroundColor(isSelected ? .blue : .secondary)
            .cornerRadius(6)
            .overlay(
                isSelected ?
                    Rectangle()
                        .frame(height: 2)
                        .foregroundColor(.blue)
                        .offset(y: 14)
                    : nil
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct FormatToolbarButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .frame(width: 30, height: 30)
                .background(isHovered ? Color.blue.opacity(0.1) : Color.clear)
                .foregroundColor(isHovered ? .blue : .secondary)
                .cornerRadius(4)
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hover in
            withAnimation(.easeOut(duration: 0.2)) {
                isHovered = hover
            }
        }
        .help(title)
    }
}

struct FormatBadge: View {
    let text: String
    let color: Color
    
    var body: some View {
        Text(text)
            .font(.system(size: 12, design: .monospaced))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.2))
            .foregroundColor(color)
            .cornerRadius(4)
    }
}

struct FormattedTextPreviewView_Previews: PreviewProvider {
    static var previews: some View {
        FormattedTextPreviewView()
            .preferredColorScheme(.dark)
    }
} 
