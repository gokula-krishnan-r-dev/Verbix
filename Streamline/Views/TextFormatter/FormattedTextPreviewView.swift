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
        /// VS Code-inspired dark theme
        case vscodeDark
        /// VS Code-inspired light theme
        case vscodeLight
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
            case .vscodeDark, .vscodeLight:
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
            case .vscodeDark, .vscodeLight:
                return .system(size: size, weight: .bold)
            case .custom(_, let headerFont, _):
                return headerFont
            }
        }
        
        /// Returns the code font for this document style
        func codeFont(size: CGFloat) -> Font {
            switch self {
            case .standard, .academic, .magazine:
                return .system(size: size, design: .monospaced)
            case .technical, .vscodeDark, .vscodeLight:
                return .system(size: size, weight: .regular, design: .monospaced)
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
            case .technical, .vscodeDark, .vscodeLight:
                return 6
            case .custom:
                return 8
            }
        }
        
        /// Returns the appropriate background color for the document
        func backgroundColor(isDarkMode: Bool) -> Color {
            switch self {
            case .vscodeDark:
                return Color(red: 0.12, green: 0.12, blue: 0.12)
            case .vscodeLight:
                return Color(red: 0.98, green: 0.98, blue: 0.98)
            default:
                return isDarkMode ? Color.black.opacity(0.7) : Color.white
            }
        }
        
        /// Returns the appropriate code block background color
        func codeBlockBackgroundColor(isDarkMode: Bool) -> Color {
            switch self {
            case .vscodeDark:
                return Color(red: 0.16, green: 0.16, blue: 0.16)
            case .vscodeLight:
                return Color(red: 0.95, green: 0.95, blue: 0.95)
            default:
                return isDarkMode ? Color.black.opacity(0.6) : Color.gray.opacity(0.1)
            }
        }
        
        /// Returns the appropriate link color
        func linkColor(isDarkMode: Bool) -> Color {
            switch self {
            case .vscodeDark:
                return Color.blue.opacity(0.8)
            case .vscodeLight:
                return Color.blue
            default:
                return isDarkMode ? Color.blue.opacity(0.8) : Color.blue
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
                    enhancedLinkView(text: component.text, url: url)
                case .image(let url, let alt):
                    imageView(url: url, alt: alt)
                case .horizontalRule:
                    Divider()
                        .background(textColor.opacity(0.5))
                        .padding(.vertical, 8)
                case .codeBlock(let language):
                    codeBlockView(text: component.text, language: language)
                case .taskList(let checked):
                    taskListItemView(text: component.text, isChecked: checked)
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
    
    private func enhancedLinkView(text: String, url: URL) -> some View {
        Link(destination: url) {
            Text(text)
                .font(documentStyle.bodyFont(size: fontSize))
                .foregroundColor(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(documentStyle.linkColor(isDarkMode: textColor == .white))
                .cornerRadius(4)
                .multilineTextAlignment(alignment)
        }
    }
    
    private func imageView(url: URL, alt: String) -> some View {
        VStack(alignment: alignment == .leading ? .leading : alignment == .trailing ? .trailing : .center, spacing: 4) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .frame(height: 120)
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .cornerRadius(4)
                        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                case .failure:
                    Image(systemName: "photo")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                        .frame(height: 120)
                @unknown default:
                    EmptyView()
                }
            }
            .frame(maxWidth: .infinity)
            .frame(maxHeight: 320)
            
            if !alt.isEmpty {
                Text(alt)
                    .font(documentStyle.bodyFont(size: fontSize - 2))
                    .foregroundColor(textColor.opacity(0.7))
                    .italic()
            }
        }
        .padding(.vertical, 8)
    }
    
    private func codeBlockView(text: String, language: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if !language.isEmpty {
                Text(language)
                    .font(.system(size: fontSize - 4, weight: .bold, design: .monospaced))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.top, 4)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                Text(text)
                    .font(documentStyle.codeFont(size: fontSize))
                    .padding(12)
                    .multilineTextAlignment(.leading)
                    .lineSpacing(4)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .foregroundColor(textColor)
        .background(documentStyle.codeBlockBackgroundColor(isDarkMode: textColor == .white))
        .cornerRadius(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
        .padding(.vertical, 4)
    }
    
    private func taskListItemView(text: String, isChecked: Bool) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: isChecked ? "checkmark.square.fill" : "square")
                .foregroundColor(isChecked ? .green : .gray)
                .font(.system(size: fontSize))
            
            Text(text)
                .font(documentStyle.bodyFont(size: fontSize))
                .foregroundColor(textColor)
                .strikethrough(isChecked)
                .multilineTextAlignment(alignment)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.leading, documentStyle.sectionPadding)
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
            case image(url: URL, alt: String)
            case horizontalRule
            case codeBlock(language: String)
            case taskList(checked: Bool)
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
        var inCodeBlock = false
        var codeBlockLanguage = ""
        var codeBlockContent = ""
        
        for line in lines {
            // Check for code block start/end
            if line.hasPrefix("```") {
                if inCodeBlock {
                    // End code block
                    components.append(TextComponent(text: codeBlockContent, type: .codeBlock(language: codeBlockLanguage)))
                    inCodeBlock = false
                    codeBlockContent = ""
                    codeBlockLanguage = ""
                    continue
                } else {
                    // Start code block
                    inCodeBlock = true
                    // Get language if specified
                    if line.count > 3 {
                        codeBlockLanguage = String(line.dropFirst(3)).trimmingCharacters(in: .whitespaces)
                    }
                    continue
                }
            }
            
            // If in code block, add to content
            if inCodeBlock {
                if !codeBlockContent.isEmpty {
                    codeBlockContent += "\n"
                }
                codeBlockContent += line
                continue
            }
            
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
            
            // Check for task list
            if line.matches(pattern: "^\\s*- \\[[ x]\\]\\s+") {
                let isChecked = line.contains("- [x]")
                if let range = line.range(of: "^\\s*- \\[[ x]\\]\\s+", options: .regularExpression) {
                    let taskText = line[range.upperBound...].trimmingCharacters(in: .whitespaces)
                    components.append(TextComponent(text: taskText, type: .taskList(checked: isChecked)))
                    continue
                }
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
                
                // Check for image ![alt](url)
                if char == "!" && nextIndex < line.endIndex && line[nextIndex] == "[" {
                    // Start of image alt text
                    if !currentText.isEmpty {
                        components.append(TextComponent(text: currentText, type: .plainText))
                        currentText = ""
                    }
                    
                    // Skip the "!["
                    let altStartIndex = line.index(nextIndex, offsetBy: 1)
                    if let altEndIndex = line[altStartIndex...].firstIndex(of: "]"),
                       altEndIndex < line.endIndex,
                       let urlStartDelimiter = line[altEndIndex...].firstIndex(of: "("),
                       urlStartDelimiter < line.endIndex {
                        
                        let altText = String(line[altStartIndex..<altEndIndex])
                        let urlStartIndex = line.index(after: urlStartDelimiter)
                        
                        if let urlEndIndex = line[urlStartIndex...].firstIndex(of: ")") {
                            let urlString = String(line[urlStartIndex..<urlEndIndex])
                            if let url = URL(string: urlString) {
                                components.append(TextComponent(text: altText, type: .image(url: url, alt: altText)))
                            } else {
                                components.append(TextComponent(text: "![" + altText + "](" + urlString + ")", type: .plainText))
                            }
                            currentIndex = line.index(after: urlEndIndex)
                            continue
                        }
                    }
                }
                
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
        
        // Handle any unclosed code block
        if inCodeBlock && !codeBlockContent.isEmpty {
            components.append(TextComponent(text: codeBlockContent, type: .codeBlock(language: codeBlockLanguage)))
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
    @State private var inputText: String = "# Markdown Text Formatter\n\nThis is a **rich text** formatter that supports various markdown features:\n\n## Formatting Options\n\n- **Bold text** with double asterisks\n- _Italic text_ with underscores\n- `Code blocks` with backticks\n\n### Lists\n\n1. Numbered lists work too\n2. Just start lines with numbers\n\n> This is a blockquote for important notes\n\n---\n\nYou can also include [links](https://www.apple.com) to websites.\n\nUse /n for manual line breaks.\n\n```swift\nfunc example() {\n    print(\"Code blocks with syntax highlighting\")\n}\n```\n\n![SwiftUI Logo](https://devimages-cdn.apple.com/wwdc-services/articles/images/C5082458-76EE-4934-B36B-79597AD18D7C/500_500.jpg)"
    @State private var fontSize: Double = 16
    @State private var darkMode: Bool = false
    @State private var lineSpacing: Double = 6
    @State private var selectedTab: Int = 0
    @State private var selectedDocumentStyle: FormattedTextView.DocumentStyle = .standard
    @State private var documentTheme: DocumentTheme = .standard
    @State private var showLineNumbers: Bool = true
    @State private var activePanel: SidePanel? = nil
    @State private var searchText: String = ""
    @State private var showDocumentation: Bool = false
    @State private var recentFiles: [String] = ["Document1.md", "README.md", "Notes.md"]
    
    enum DocumentTheme: String, CaseIterable, Identifiable {
        case standard = "Standard"
        case vscodeDark = "VS Code Dark"
        case vscodeLight = "VS Code Light"
        case github = "GitHub"
        case academic = "Academic"
        case technical = "Technical"
        
        var id: String { rawValue }
        
        func documentStyle() -> FormattedTextView.DocumentStyle {
            switch self {
            case .standard: return .standard
            case .vscodeDark: return .vscodeDark
            case .vscodeLight: return .vscodeLight
            case .github: return .standard
            case .academic: return .academic
            case .technical: return .technical
            }
        }
        
        func editorBackgroundColor(isDarkMode: Bool) -> Color {
            switch self {
            case .vscodeDark:
                return Color(red: 0.12, green: 0.12, blue: 0.12)
            case .vscodeLight:
                return Color(red: 0.96, green: 0.96, blue: 0.96)
            case .github:
                return isDarkMode ? Color(red: 0.13, green: 0.13, blue: 0.13) : Color.white
            default:
                return isDarkMode ? Color.black.opacity(0.7) : Color.white
            }
        }
        
        func editorTextColor(isDarkMode: Bool) -> Color {
            switch self {
            case .vscodeDark:
                return Color.white
            case .vscodeLight:
                return Color.black
            case .github:
                return isDarkMode ? Color.white : Color.black
            default:
                return isDarkMode ? Color.white : Color.black
            }
        }
        
        func accentColor() -> Color {
            switch self {
            case .vscodeDark, .vscodeLight:
                return Color.blue
            case .github:
                return Color(red: 0.25, green: 0.5, blue: 0.88)
            case .academic:
                return Color(red: 0.6, green: 0.2, blue: 0.2)
            case .technical:
                return Color(red: 0.2, green: 0.6, blue: 0.6)
            case .standard:
                return Color.blue
            }
        }
    }
    
    enum SidePanel: String, Identifiable {
        case explorer = "Explorer"
        case search = "Search"
        case extensions = "Extensions"
        case documentation = "Documentation"
        
        var id: String { rawValue }
        var icon: String {
            switch self {
            case .explorer: return "folder"
            case .search: return "magnifyingglass"
            case .extensions: return "puzzlepiece.extension"
            case .documentation: return "book"
            }
        }
    }
    
    var body: some View {
        ZStack {
            // Main content
            VStack(spacing: 0) {
                // Title bar
                titleBar
                
                // Content area with optional sidebar
                HStack(spacing: 0) {
                    if activePanel != nil {
                        sidePanel
                    }
                    
                    // Main editor area
                    VStack(spacing: 0) {
                        // Tab navigation
                        tabBar
                        
                        // Editor/Preview content based on selected tab
                        if selectedTab == 0 {
                            editorView
                        } else if selectedTab == 1 {
                            previewView
                        } else {
                            splitView
                        }
                    }
                }
                
                // Status bar
                statusBar
            }
            
            // Documentation popover
            if showDocumentation {
                documentationPopover
            }
        }
        .frame(minWidth: 900, minHeight: 600)
        .background(documentTheme.editorBackgroundColor(isDarkMode: darkMode))
        .preferredColorScheme(darkMode ? .dark : .light)
    }
    
    private var titleBar: some View {
        HStack {
            // Application icon
            Image(systemName: "text.format")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(documentTheme.accentColor())
                .padding(6)
                .background(documentTheme.accentColor().opacity(0.1))
                .clipShape(Circle())
            
            // Title
            Text("Streamline Text Editor")
                .font(.headline)
                .foregroundColor(darkMode ? .white : .primary)
            
            Spacer()
            
            // Theme selector
            Picker("Theme", selection: $documentTheme) {
                ForEach(DocumentTheme.allCases) { theme in
                    Text(theme.rawValue).tag(theme)
                }
            }
            .pickerStyle(.menu)
            .frame(width: 160)
            
            // Dark mode toggle
            Toggle("", isOn: $darkMode)
                .toggleStyle(SwitchToggleStyle(tint: documentTheme.accentColor()))
                .padding(.horizontal, 8)
                .help("Toggle Dark Mode")
            
            // Documentation button
            Button(action: { showDocumentation.toggle() }) {
                Image(systemName: "questionmark.circle")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(BorderlessButtonStyle())
            .help("Show Documentation")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(documentTheme.editorBackgroundColor(isDarkMode: darkMode).opacity(0.95))
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    private var tabBar: some View {
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
            
            // Editor options
            HStack(spacing: 8) {
                Toggle("Line Numbers", isOn: $showLineNumbers)
                    .toggleStyle(CheckboxToggleStyle())
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                
                Divider().frame(height: 16)
                
                HStack(spacing: 4) {
                    Text("Font Size:")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    
                    Stepper("\(Int(fontSize))", value: $fontSize, in: 10...24, step: 1)
                        .labelsHidden()
                }
                
                Divider().frame(height: 16)
                
                HStack(spacing: 4) {
                    Text("Spacing:")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    
                    Slider(value: $lineSpacing, in: 2...12, step: 1)
                        .frame(width: 80)
                }
            }
            .padding(.trailing, 12)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(documentTheme.editorBackgroundColor(isDarkMode: darkMode))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color.gray.opacity(0.2)),
            alignment: .bottom
        )
    }
    
    private var sidePanel: some View {
        VStack(spacing: 0) {
            // Panel header
            HStack {
                Text(activePanel?.rawValue ?? "Panel")
                    .font(.headline)
                    .foregroundColor(darkMode ? .white : .primary)
                
                Spacer()
                
                Button(action: { activePanel = nil }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(BorderlessButtonStyle())
            }
            .padding(12)
            .background(documentTheme.editorBackgroundColor(isDarkMode: darkMode))
            
            Divider()
            
            // Panel content based on selected panel
            switch activePanel {
            case .explorer:
                explorerPanel
            case .search:
                searchPanel
            case .documentation:
                documentationPanel
            case .extensions:
                extensionsPanel
            case nil:
                EmptyView()
            }
        }
        .frame(width: 250)
        .background(documentTheme.editorBackgroundColor(isDarkMode: darkMode))
        .overlay(
            Rectangle()
                .frame(width: 1)
                .foregroundColor(Color.gray.opacity(0.3)),
            alignment: .trailing
        )
    }
    
    private var explorerPanel: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("OPEN EDITORS")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.secondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            
            ForEach(recentFiles, id: \.self) { file in
                HStack {
                    Image(systemName: "doc.text")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    
                    Text(file)
                        .font(.system(size: 13))
                        .foregroundColor(darkMode ? .white : .primary)
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .background(Color.blue.opacity(0.1).opacity(file == "Document1.md" ? 1 : 0))
            }
            
            Divider().padding(.vertical, 8)
            
            Text("WORKSPACE")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.secondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            
            // Folder structure
            Group {
                folderRow(name: "Project", isExpanded: true, level: 0)
                folderRow(name: "src", isExpanded: true, level: 1)
                fileRow(name: "Document1.md", isActive: true, level: 2)
                fileRow(name: "README.md", isActive: false, level: 2)
                folderRow(name: "assets", isExpanded: false, level: 1)
                folderRow(name: "docs", isExpanded: false, level: 1)
            }
            
            Spacer()
        }
    }
    
    private func folderRow(name: String, isExpanded: Bool, level: Int) -> some View {
        HStack {
            Text("")
                .frame(width: CGFloat(level * 16))
            
            Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                .font(.system(size: 10))
                .foregroundColor(.secondary)
            
            Image(systemName: "folder.fill")
                .font(.system(size: 12))
                .foregroundColor(Color.blue.opacity(0.7))
            
            Text(name)
                .font(.system(size: 13))
                .foregroundColor(darkMode ? .white : .primary)
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
    }
    
    private func fileRow(name: String, isActive: Bool, level: Int) -> some View {
        HStack {
            Text("")
                .frame(width: CGFloat(level * 16))
            
            Text("")
                .frame(width: 16)
            
            Image(systemName: "doc.text")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
            
            Text(name)
                .font(.system(size: 13))
                .foregroundColor(darkMode ? .white : .primary)
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
        .background(isActive ? Color.blue.opacity(0.1) : Color.clear)
    }
    
    private var searchPanel: some View {
        VStack(spacing: 0) {
            // Search input
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search", text: $searchText)
                    .font(.system(size: 13))
                    .textFieldStyle(PlainTextFieldStyle())
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                            .font(.system(size: 14))
                    }
                    .buttonStyle(BorderlessButtonStyle())
                }
            }
            .padding(8)
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(4)
            .padding(12)
            
            // Search options
            HStack {
                Text("Search Options:")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                
                Toggle("Match Case", isOn: .constant(false))
                    .toggleStyle(CheckboxToggleStyle())
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                
                Toggle("Regex", isOn: .constant(false))
                    .toggleStyle(CheckboxToggleStyle())
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
            
            Divider()
            
            if searchText.isEmpty {
                VStack {
                    Text("Type to search")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .padding(.top, 20)
                }
            } else {
                // Search results
                VStack(alignment: .leading) {
                    Text("SEARCH RESULTS")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                    
                    // Example search results
                    searchResultRow(
                        file: "Document1.md",
                        line: 5,
                        content: "This is a **rich text** formatter that supports"
                    )
                    
                    searchResultRow(
                        file: "README.md",
                        line: 12,
                        content: "Rich formatting options are available"
                    )
                }
            }
            
            Spacer()
        }
    }
    
    private func searchResultRow(file: String, line: Int, content: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: "doc.text")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                
                Text(file)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(documentTheme.accentColor())
                
                Text(":\(line)")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            
            Text(content)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .lineLimit(1)
                .padding(.leading, 20)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .background(Color.clear)
        .contentShape(Rectangle())
    }
    
    private var documentationPanel: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Markdown Guide")
                    .font(.headline)
                    .padding(.bottom, 4)
                
                Group {
                    docSection(title: "Headers", content: "# Header 1\n## Header 2\n### Header 3")
                    docSection(title: "Emphasis", content: "**Bold Text**\n*Italic Text*\n~~Strikethrough~~")
                    docSection(title: "Lists", content: "- Bullet item\n- Another item\n\n1. Numbered item\n2. Second item")
                    docSection(title: "Links", content: "[Link Text](https://example.com)")
                    docSection(title: "Images", content: "![Alt text](https://example.com/image.jpg)")
                    docSection(title: "Code", content: "`Inline code`\n\n```\nCode block\n```")
                    docSection(title: "Blockquotes", content: "> Blockquote text\n> More text")
                    docSection(title: "Horizontal Rule", content: "---")
                    docSection(title: "Task Lists", content: "- [x] Completed task\n- [ ] Incomplete task")
                }
            }
            .padding()
        }
    }
    
    private func docSection(title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(darkMode ? .white : .primary)
            
            Text(content)
                .font(.system(size: 12, design: .monospaced))
                .padding(8)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(4)
                .foregroundColor(darkMode ? .white.opacity(0.9) : .primary.opacity(0.9))
        }
    }
    
    private var extensionsPanel: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Search input
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search Extensions", text: .constant(""))
                    .font(.system(size: 13))
                    .textFieldStyle(PlainTextFieldStyle())
            }
            .padding(8)
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(4)
            .padding(12)
            
            // Categories
            Text("CATEGORIES")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.secondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            
            ForEach(["Installed", "Recommended", "Popular"], id: \.self) { category in
                HStack {
                    Text(category)
                        .font(.system(size: 13))
                        .foregroundColor(darkMode ? .white : .primary)
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .background(category == "Installed" ? Color.blue.opacity(0.1) : Color.clear)
            }
            
            Divider().padding(.vertical, 8)
            
            // Extensions list
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    extensionRow(
                        name: "Markdown All in One",
                        publisher: "Yu Zhang",
                        description: "All you need for Markdown (keyboard shortcuts, TOC, etc.)",
                        installed: true
                    )
                    
                    extensionRow(
                        name: "Code Spell Checker",
                        publisher: "Street Side Software",
                        description: "Spelling checker for source code",
                        installed: true
                    )
                    
                    extensionRow(
                        name: "Prettier - Code formatter",
                        publisher: "Prettier",
                        description: "Code formatter using prettier",
                        installed: false
                    )
                }
                .padding(.horizontal, 16)
            }
            
            Spacer()
        }
    }
    
    private func extensionRow(name: String, publisher: String, description: String, installed: Bool) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(name)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(darkMode ? .white : .primary)
                
                Spacer()
                
                if installed {
                    Text("Installed")
                        .font(.system(size: 11))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.green.opacity(0.2))
                        .foregroundColor(.green)
                        .cornerRadius(4)
                }
            }
            
            Text(publisher)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
            
            Text(description)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .lineLimit(2)
                .padding(.top, 2)
        }
        .padding(.vertical, 8)
    }
    
    private var documentationPopover: some View {
        ZStack {
            Color.black.opacity(0.3)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    withAnimation {
                        showDocumentation = false
                    }
                }
            
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Markdown Documentation")
                            .font(.title2)
                            .bold()
                        
                        Spacer()
                        
                        Button(action: { showDocumentation = false }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title3)
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(BorderlessButtonStyle())
                    }
                    .padding(.bottom, 8)
                    
                    Text("Streamline Text Editor supports standard Markdown syntax as well as some useful extensions.")
                        .font(.body)
                    
                    Group {
                        docSection(title: "Headers", content: "# Header 1\n## Header 2\n### Header 3")
                        docSection(title: "Emphasis", content: "**Bold Text**\n*Italic Text*\n~~Strikethrough~~")
                        docSection(title: "Lists", content: "- Bullet item\n- Another item\n\n1. Numbered item\n2. Second item")
                        docSection(title: "Links", content: "[Link Text](https://example.com)")
                        docSection(title: "Images", content: "![Alt text](https://example.com/image.jpg)")
                        docSection(title: "Code", content: "`Inline code`\n\n```swift\nCode block with language\n```")
                        docSection(title: "Blockquotes", content: "> Blockquote text\n> More text")
                        docSection(title: "Horizontal Rule", content: "---")
                        docSection(title: "Task Lists", content: "- [x] Completed task\n- [ ] Incomplete task")
                    }
                    
                    Text("For more information, visit [Markdown Guide](https://www.markdownguide.org)")
                        .font(.body)
                        .padding(.top, 8)
                }
                .padding(24)
                .background(documentTheme.editorBackgroundColor(isDarkMode: darkMode))
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
                .padding(40)
            }
        }
        .transition(.opacity)
        .zIndex(10)
    }
    
    private var toolbarView: some View {
        VStack(spacing: 0) {
            // Main toolbar
            HStack(spacing: 12) {
                FormatToolbarButton(title: "Bold", icon: "bold", action: { insertTag("**", "**") })
                FormatToolbarButton(title: "Italic", icon: "italic", action: { insertTag("_", "_") })
                FormatToolbarButton(title: "Code", icon: "chevron.left.forwardslash.chevron.right", action: { insertTag("`", "`") })
                FormatToolbarButton(title: "Strikethrough", icon: "strikethrough", action: { insertTag("~~", "~~") })
                
                Divider().frame(height: 20)
                
                FormatToolbarButton(title: "Heading 1", icon: "text.heading", action: { insertPrefix("# ") })
                FormatToolbarButton(title: "Heading 2", icon: "h.square", action: { insertPrefix("## ") })
                FormatToolbarButton(title: "Heading 3", icon: "h.square.on.square", action: { insertPrefix("### ") })
                
                Divider().frame(height: 20)
                
                FormatToolbarButton(title: "Bullet List", icon: "list.bullet", action: { insertPrefix("- ") })
                FormatToolbarButton(title: "Numbered List", icon: "list.number", action: { insertPrefix("1. ") })
                FormatToolbarButton(title: "Task", icon: "checkmark.square", action: { insertPrefix("- [ ] ") })
                FormatToolbarButton(title: "Quote", icon: "text.quote", action: { insertPrefix("> ") })
                
                Divider().frame(height: 20)
                
                FormatToolbarButton(title: "Link", icon: "link", action: { insertTag("[", "](https://example.com)") })
                FormatToolbarButton(title: "Image", icon: "photo", action: { insertText("![Alt text](https://example.com/image.jpg)") })
                FormatToolbarButton(title: "Code Block", icon: "curlybraces", action: { insertText("\n```swift\n// Your code here\n```\n") })
                FormatToolbarButton(title: "Line Break", icon: "arrow.turn.down.right", action: { insertText("/n") })
                FormatToolbarButton(title: "Horizontal Rule", icon: "minus", action: { insertText("\n---\n") })
                
                Spacer()
                
                Menu {
                    Button("Copy as Markdown", action: { copyToClipboard(inputText) })
                    Button("Copy as HTML", action: { copyTextAsHTML() })
                    Divider()
                    Button("Export as PDF", action: {})
                    Button("Export as Image", action: {})
                } label: {
                    Label("Export", systemImage: "square.and.arrow.up")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .background(documentTheme.editorBackgroundColor(isDarkMode: darkMode).opacity(0.95))
            
            // Line separator
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 1)
        }
    }
    
    private var editorView: some View {
        VStack(spacing: 0) {
            toolbarView
            
            ZStack(alignment: .topLeading) {
                // Main text editor
                TextEditor(text: $inputText)
                    .font(.system(size: CGFloat(fontSize), design: .monospaced))
                    .foregroundColor(documentTheme.editorTextColor(isDarkMode: darkMode))
                    .padding(16)
                    .background(documentTheme.editorBackgroundColor(isDarkMode: darkMode))
                    .cornerRadius(4)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                    .padding(12)
                
                // Line numbers if enabled
                if showLineNumbers {
                    VStack(alignment: .trailing, spacing: 0) {
                        ForEach(Array(inputText.components(separatedBy: "\n").indices), id: \.self) { index in
                            Text("\(index + 1)")
                                .font(.system(size: CGFloat(fontSize) - 2, design: .monospaced))
                                .foregroundColor(.gray)
                                .padding(.vertical, 2.4) // Adjust to match line height
                        }
                        Spacer()
                    }
                    .padding(.top, 16)
                    .padding(.leading, 16)
                    .padding(.trailing, 8)
                    .background(
                        documentTheme.editorBackgroundColor(isDarkMode: darkMode)
                            .opacity(0.6)
                    )
                }
            }
        }
    }
    
    private var previewView: some View {
        VStack(spacing: 0) {
            // VS Code style tab bar for output
            HStack {
                Text("Preview")
                    .font(.system(size: 13))
                    .foregroundColor(darkMode ? .white : .primary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.secondary.opacity(0.1))
                
                Spacer()
                
                Button(action: {}) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(BorderlessButtonStyle())
                .padding(.trailing, 12)
                .help("Refresh Preview")
            }
            .background(documentTheme.editorBackgroundColor(isDarkMode: darkMode).opacity(0.95))
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(Color.gray.opacity(0.3)),
                alignment: .bottom
            )
            
            // Preview content
            ScrollView {
                FormattedTextView(
                    inputText,
                    fontSize: CGFloat(fontSize),
                    textColor: documentTheme.editorTextColor(isDarkMode: darkMode),
                    alignment: .leading,
                    lineSpacing: CGFloat(lineSpacing),
                    documentStyle: documentTheme.documentStyle()
                )
                .padding(24)
                .background(documentTheme.editorBackgroundColor(isDarkMode: darkMode).opacity(0.7))
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
    }
    
    private var splitView: some View {
        HStack(spacing: 0) {
            // Editor side
            VStack(spacing: 0) {
                toolbarView
                
                ZStack(alignment: .topLeading) {
                    TextEditor(text: $inputText)
                        .font(.system(size: CGFloat(fontSize), design: .monospaced))
                        .foregroundColor(documentTheme.editorTextColor(isDarkMode: darkMode))
                        .padding(16)
                        .background(documentTheme.editorBackgroundColor(isDarkMode: darkMode))
                        .cornerRadius(4)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                        .padding(12)
                    
                    // Line numbers if enabled
                    if showLineNumbers {
                        VStack(alignment: .trailing, spacing: 0) {
                            ForEach(Array(inputText.components(separatedBy: "\n").indices), id: \.self) { index in
                                Text("\(index + 1)")
                                    .font(.system(size: CGFloat(fontSize) - 2, design: .monospaced))
                                    .foregroundColor(.gray)
                                    .padding(.vertical, 2.4)
                            }
                            Spacer()
                        }
                        .padding(.top, 16)
                        .padding(.leading, 16)
                        .padding(.trailing, 8)
                        .background(
                            documentTheme.editorBackgroundColor(isDarkMode: darkMode)
                                .opacity(0.6)
                        )
                    }
                }
            }
            
            // Divider
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 1)
            
            // Preview side
            VStack(spacing: 0) {
                HStack {
                    Text("Preview")
                        .font(.system(size: 13))
                        .foregroundColor(darkMode ? .white : .primary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.secondary.opacity(0.1))
                    
                    Spacer()
                }
                .background(documentTheme.editorBackgroundColor(isDarkMode: darkMode).opacity(0.95))
                .overlay(
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(Color.gray.opacity(0.3)),
                    alignment: .bottom
                )
                
                ScrollView {
                    FormattedTextView(
                        inputText,
                        fontSize: CGFloat(fontSize),
                        textColor: documentTheme.editorTextColor(isDarkMode: darkMode),
                        alignment: .leading,
                        lineSpacing: CGFloat(lineSpacing),
                        documentStyle: documentTheme.documentStyle()
                    )
                    .padding(24)
                    .background(documentTheme.editorBackgroundColor(isDarkMode: darkMode).opacity(0.7))
                    .cornerRadius(8)
                    .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                    .padding(16)
                }
            }
        }
        .animation(.easeInOut(duration: 0.2), value: inputText)
        .animation(.easeInOut(duration: 0.2), value: fontSize)
        .animation(.easeInOut(duration: 0.2), value: lineSpacing)
        .animation(.easeInOut(duration: 0.2), value: darkMode)
    }
    
    private var statusBar: some View {
        HStack(spacing: 16) {
            // Left sidebar buttons
            HStack(spacing: 2) {
                ForEach([SidePanel.explorer, .search, .extensions, .documentation], id: \.self) { panel in
                    Button(action: {
                        if activePanel == panel {
                            activePanel = nil
                        } else {
                            activePanel = panel
                        }
                    }) {
                        Image(systemName: panel.icon)
                            .frame(width: 40, height: 36)
                            .foregroundColor(activePanel == panel ? documentTheme.accentColor() : .secondary)
                            .background(activePanel == panel ? documentTheme.accentColor().opacity(0.1) : Color.clear)
                    }
                    .buttonStyle(BorderlessButtonStyle())
                    .help(panel.rawValue)
                }
            }
            
            Spacer()
            
            // Status info
            HStack(spacing: 16) {
                // Line and character info
                HStack(spacing: 4) {
                    Text("Line \(inputText.components(separatedBy: "\n").count)")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    
                    Divider().frame(height: 12)
                    
                    Text("\(inputText.count) chars")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                
                // File type indicator
                HStack(spacing: 4) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    
                    Text("Markdown")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                
                // Document status
                Text("Last saved: \(timeString())")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(documentTheme.editorBackgroundColor(isDarkMode: darkMode).opacity(0.95))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color.gray.opacity(0.3)),
            alignment: .top
        )
    }
    
    // MARK: - Helper Methods
    
    private func timeString() -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: Date())
    }
    
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
        var inCodeBlock = false
        var codeBlockLanguage = ""
        var codeBlockContent = ""
        
        for line in lines {
            // Handle code blocks
            if line.hasPrefix("```") {
                if inCodeBlock {
                    // End code block and add formatted content
                    let highlightedCode = codeBlockContent.replacingOccurrences(of: "<", with: "&lt;")
                                                         .replacingOccurrences(of: ">", with: "&gt;")
                    
                    processedLines.append("<pre><code class=\"language-\(codeBlockLanguage)\">\(highlightedCode)</code></pre>")
                    inCodeBlock = false
                    codeBlockContent = ""
                    codeBlockLanguage = ""
                } else {
                    // Start code block
                    inCodeBlock = true
                    if line.count > 3 {
                        codeBlockLanguage = String(line.dropFirst(3)).trimmingCharacters(in: .whitespaces)
                    }
                }
                continue
            }
            
            if inCodeBlock {
                codeBlockContent += line + "\n"
                continue
            }
            
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
            // Convert task lists
            else if let range = processedLine.range(of: #"^- \[([ x])\] (.*?)$"#, options: .regularExpression) {
                let matches = processedLine.matches(for: #"^- \[([ x])\] (.*?)$"#)
                if matches.count >= 2 {
                    let checked = matches[0].contains("x")
                    let taskContent = matches[1]
                    let checkedAttr = checked ? " checked" : ""
                    processedLine = "<div class=\"task-list-item\"><input type=\"checkbox\"\(checkedAttr)> <span>\(taskContent)</span></div>"
                }
            }
            // Convert blockquotes
            else if processedLine.hasPrefix(">") {
                let quoteContent = processedLine.dropFirst().trimmingCharacters(in: .whitespaces)
                processedLine = "<blockquote>\(quoteContent)</blockquote>"
            }
            
            processedLines.append(processedLine)
        }
        
        // Rejoin lines
        html = processedLines.joined(separator: "\n")
        
        // Convert bold and italic (these work across multiple lines)
        html = html.replacingOccurrences(of: #"\*\*(.*?)\*\*"#, with: "<strong>$1</strong>", options: .regularExpression)
        html = html.replacingOccurrences(of: #"_(.*?)_"#, with: "<em>$1</em>", options: .regularExpression)
        html = html.replacingOccurrences(of: #"~~(.*?)~~"#, with: "<del>$1</del>", options: .regularExpression)
        
        // Convert code blocks
        html = html.replacingOccurrences(of: #"`(.*?)`"#, with: "<code>$1</code>", options: .regularExpression)
        
        // Convert links
        html = html.replacingOccurrences(of: #"\[(.*?)\]\((.*?)\)"#, with: "<a href=\"$2\">$1</a>", options: .regularExpression)
        
        // Convert images
        html = html.replacingOccurrences(of: #"!\[(.*?)\]\((.*?)\)"#, with: "<img src=\"$2\" alt=\"$1\">", options: .regularExpression)
        
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

// MARK: - Supporting Views and Extensions

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

extension String {
    func matches(for regex: String) -> [String] {
        do {
            let regex = try NSRegularExpression(pattern: regex)
            let results = regex.matches(in: self, range: NSRange(self.startIndex..., in: self))
            return results.map {
                String(self[Range($0.range, in: self)!])
            }
        } catch {
            return []
        }
    }
}

struct FormattedTextPreviewView_Previews: PreviewProvider {
    static var previews: some View {
        FormattedTextPreviewView()
            .preferredColorScheme(.dark)
    }
} 
