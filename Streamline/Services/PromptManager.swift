import Foundation

/// A structured approach to generating AI prompts based on different scenarios and needs
class PromptManager {
    
    // MARK: - Prompt Template Model
    
    /// Represents a single prompt template with conditions for when to apply it
    struct PromptTemplate {
        let name: String
        let systemPrompt: String
        let promptBuilder: (String, String?) -> String
        let matcher: (String, String?) -> Bool
        
        init(
            name: String,
            systemPrompt: String,
            matcher: @escaping (String, String?) -> Bool,
            promptBuilder: @escaping (String, String?) -> String
        ) {
            self.name = name
            self.systemPrompt = systemPrompt
            self.matcher = matcher
            self.promptBuilder = promptBuilder
        }
    }
    
    // MARK: - Properties
    
    /// Collection of available prompt templates
    private let templates: [PromptTemplate]
    
    // MARK: - Initialization
    
    init() {
        // Register all available prompt templates
        self.templates = [
            // Rewriting template
            PromptTemplate(
                name: "Text Rewriting",
                systemPrompt: """
                You are a precise text optimization tool. Your only job is to rewrite the provided text to be clearer and more concise while preserving all meaning. 
                Output ONLY the rewritten text - no explanations, no labels, no variations, no extra information. 
                Return exactly ONE optimized version with no markup unless it appeared in the original.
                """,
                matcher: { query, _ in
                    query.lowercased().contains("rewrite") ||
                    query.lowercased().contains("revise") ||
                    query.lowercased().contains("improve") ||
                    query.lowercased().contains("better") ||
                    query.lowercased().contains("enhance")
                },
                promptBuilder: { query, selectedText in
                    if let text = selectedText, !text.isEmpty {
                        return """
                        INSTRUCTION: \(query)
                        
                        TEXT TO REWRITE:
                        \(text)
                        """
                    } else {
                        return "REWRITE: \(query)"
                    }
                }
            ),
            
            // Code modification template
            PromptTemplate(
                name: "Code Editing",
                systemPrompt: """
                You are a code expert. Return ONLY the modified code or solution without any explanations or comments outside the code. 
                Format the code properly but don't include any text before or after the code block.
                """,
                matcher: { query, selectedText in
                    let codePatterns = ["code", "function", "api", "import", "class", "method", "bug", "fix"]
                    let codeKeywords = ["import ", "func ", "class ", "struct ", "enum ", "protocol ", "extension ",
                                       "def ", "function ", "var ", "let ", "const ", "public ", "private "]
                    
                    // Check if query contains code-related terms
                    let queryHasCodeTerms = codePatterns.contains { query.lowercased().contains($0) }
                    
                    // Check if selected text contains code patterns
                    let textHasCodePatterns = if let text = selectedText {
                        codeKeywords.contains { keyword in
                            text.contains(keyword)
                        }
                    } else {
                        false
                    }
                    
                    return queryHasCodeTerms || textHasCodePatterns
                },
                promptBuilder: { query, selectedText in
                    if let text = selectedText, !text.isEmpty {
                        return """
                        INSTRUCTION: \(query)
                        
                        CODE:
                        ```
                        \(text)
                        ```
                        """
                    } else {
                        return "CODE TASK: \(query)"
                    }
                }
            ),
            
            // Translation template
            PromptTemplate(
                name: "Translation",
                systemPrompt: """
                You are a language translation tool. Translate the provided text accurately and nothing else.
                Output ONLY the translated text without any explanations, notes, or clarifications.
                """,
                matcher: { query, _ in
                    query.lowercased().contains("translate") ||
                    query.lowercased().contains("translation") ||
                    query.lowercased().contains("in spanish") ||
                    query.lowercased().contains("in french") ||
                    query.lowercased().contains("in german") ||
                    query.lowercased().contains("in japanese") ||
                    query.lowercased().contains("in chinese")
                },
                promptBuilder: { query, selectedText in
                    if let text = selectedText, !text.isEmpty {
                        return """
                        INSTRUCTION: \(query)
                        
                        TEXT TO TRANSLATE:
                        \(text)
                        """
                    } else {
                        return "TRANSLATE: \(query)"
                    }
                }
            ),
            
            // Writing template
            PromptTemplate(
                name: "Writing",
                systemPrompt: """
                You are a professional writing assistant. Create well-written content exactly as requested.
                Provide ONLY the requested text without explanations, introductions, or additional commentary.
                """,
                matcher: { query, _ in
                    query.lowercased().contains("write") ||
                    query.lowercased().contains("compose") ||
                    query.lowercased().contains("draft") ||
                    query.lowercased().contains("create") ||
                    query.lowercased().contains("generate text")
                },
                promptBuilder: { query, selectedText in
                    if let text = selectedText, !text.isEmpty {
                        return """
                        INSTRUCTION: \(query)
                        
                        CONTEXT:
                        \(text)
                        """
                    } else {
                        return "WRITING TASK: \(query)"
                    }
                }
            ),
            
            // Summarization template
            PromptTemplate(
                name: "Summarization",
                systemPrompt: """
                You are a summarization tool. Provide only a concise summary of the given text.
                The summary should be clear, accurate, and contain only the key points.
                Output ONLY the summary without any explanations or additional text.
                """,
                matcher: { query, _ in
                    query.lowercased().contains("summarize") ||
                    query.lowercased().contains("summary") ||
                    query.lowercased().contains("tldr") ||
                    query.lowercased().contains("shorten")
                },
                promptBuilder: { query, selectedText in
                    if let text = selectedText, !text.isEmpty {
                        return """
                        INSTRUCTION: \(query)
                        
                        TEXT TO SUMMARIZE:
                        \(text)
                        """
                    } else {
                        return "SUMMARIZE: \(query)"
                    }
                }
            ),
            
            // Default fallback template
            PromptTemplate(
                name: "General",
                systemPrompt: """
                You are a direct assistant that provides only answers with no explanations.
                Do not begin with acknowledgments or end with pleasantries.
                Respond with ONLY the exact output requested.
                """,
                matcher: { _, _ in
                    // This is a catch-all that always matches
                    return true
                },
                promptBuilder: { query, selectedText in
                    if let text = selectedText, !text.isEmpty {
                        return """
                        INSTRUCTION: \(query)
                        
                        CONTENT:
                        \(text)
                        """
                    } else {
                        return query
                    }
                }
            )
        ]
    }
    
    // MARK: - Public Methods
    
    /// Generate a prompt based on the query and optional selected text
    /// - Parameters:
    ///   - query: The user's query or instruction
    ///   - selectedText: Optional text that the user has selected
    /// - Returns: A tuple containing the system prompt and the content prompt
    func generatePrompt(for query: String, selectedText: String? = nil) -> (systemPrompt: String, promptContent: String) {
        // Find the first matching template
        let matchedTemplate = templates.first { template in
            template.matcher(query, selectedText)
        } ?? templates.last! // Fallback to the last template (which is our catch-all)
        
        // Generate the prompt using the template
        let promptContent = matchedTemplate.promptBuilder(query, selectedText)
        let systemPrompt = matchedTemplate.systemPrompt
        
        // Log what template was selected for debugging
        print("Using prompt template: \(matchedTemplate.name)")
        
        return (systemPrompt, promptContent)
    }
    
    /// Add a response format directive to ensure AI responds correctly
    /// - Parameter promptContent: The original prompt content
    /// - Returns: Prompt content with the response format directive
    func addResponseFormat(to promptContent: String, type: String = "general") -> String {
        // Remove any existing response format directives
        let cleaned = promptContent.replacingOccurrences(
            of: "<response_format>.*?</response_format>",
            with: "",
            options: [.regularExpression]
        )
        
        // Response format directive based on type
        let formatDirective: String
        
        switch type.lowercased() {
        case "rewrite", "revision", "improve":
            formatDirective = "<response_format>Provide only the rewritten text without any explanations, introductions, conclusions, or repetitions.</response_format>"
        case "code", "function", "api":
            formatDirective = "<response_format>Provide only the code solution without any explanations, introductions, conclusions, or discussion.</response_format>"
        case "translate", "translation":
            formatDirective = "<response_format>Provide only the translated text without any explanations, introductions, or additional text.</response_format>"
        case "summary", "summarize":
            formatDirective = "<response_format>Provide only the summary without any explanations, introductions, or additional text.</response_format>"
        case "write", "compose", "create":
            formatDirective = "<response_format>Provide only the requested text without any explanations, introductions, or additional commentary.</response_format>"
        default:
            formatDirective = "<response_format>Provide only the direct answer without any explanations, introductions, conclusions, or repetitions.</response_format>"
        }
        
        return formatDirective + "\n\n" + cleaned
    }
} 