import Foundation

enum ResponseStyle: Int, Codable, CaseIterable {
    case concise
    case balanced
    case detailed
    case professional
    case casual
    
    var title: String {
        switch self {
        case .concise: return "Concise"
        case .balanced: return "Balanced"
        case .detailed: return "Detailed"
        case .professional: return "Professional"
        case .casual: return "Casual"
        }
    }
    
    var description: String {
        switch self {
        case .concise: return "Short and to the point"
        case .balanced: return "Default balanced response"
        case .detailed: return "Comprehensive with examples"
        case .professional: return "Formal business style"
        case .casual: return "Friendly conversational tone"
        }
    }
    
    var systemPrompt: String {
        switch self {
        case .concise:
            return "Provide very concise and brief responses, focusing only on essential information."
        case .balanced:
            return "Provide balanced responses with sufficient detail without being overly verbose."
        case .detailed:
            return "Provide detailed and comprehensive responses with examples where helpful."
        case .professional:
            return "Respond in a formal, professional tone suitable for business communication."
        case .casual:
            return "Respond in a casual, friendly, and conversational tone."
        }
    }
}

struct ChatInteraction: Identifiable, Codable {
    var id = UUID()
    let prompt: String
    let response: String
    let responseStyle: ResponseStyle
    let timestamp: Date
    
    enum CodingKeys: String, CodingKey {
        case id, prompt, response, responseStyle, timestamp
    }
} 