import Foundation

enum AIAction: String, CaseIterable, Hashable {
    case fixSpellingGrammar
    case improveWriting
    case translate
    case makeShorter
    
    var title: String {
        switch self {
        case .fixSpellingGrammar: return "Fix spelling and grammar"
        case .improveWriting: return "Improve writing"
        case .translate: return "Translate"
        case .makeShorter: return "Make shorter"
        }
    }
    
    var icon: String {
        switch self {
        case .fixSpellingGrammar: return "checkmark.circle"
        case .improveWriting: return "pencil.line"
        case .translate: return "globe"
        case .makeShorter: return "scissors"
        }
    }
    
    var systemPrompt: String {
        switch self {
        case .fixSpellingGrammar: return "Fix the spelling and grammar in the following text, without changing the meaning:"
        case .improveWriting: return "Improve the writing quality of the following text, making it clearer and more engaging:"
        case .translate: return "Translate the following text to English (or if it's already in English, translate to French):"
        case .makeShorter: return "Make the following text shorter and more concise, without losing the key points:"
        }
    }
    
    // Get the appropriate instruction for each action
    var instruction: String {
        switch self {
        case .fixSpellingGrammar: 
            return "I'll fix any spelling and grammar issues while keeping the original meaning."
        case .improveWriting:
            return "I'll enhance the writing to be clearer, more engaging, and more professional."
        case .translate:
            return "I'll translate this text to the most appropriate language."
        case .makeShorter:
            return "I'll make this text more concise while preserving the key points."
        }
    }
} 