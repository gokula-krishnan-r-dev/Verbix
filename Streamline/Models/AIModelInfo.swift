import SwiftUI

struct AIModelInfo: Identifiable, Hashable {
    let id: String
    let name: String
    let provider: String
    let apiIdentifier: String
    let costPerRequest: Double
    let iconName: String
    let iconColor: Color
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: AIModelInfo, rhs: AIModelInfo) -> Bool {
        return lhs.id == rhs.id
    }
    
    // Predefined models with detailed information
    static let allModels: [AIModelInfo] = [
        AIModelInfo(
            id: "gpt-4o",
            name: "GPT-4o",
            provider: "OpenAI",
            apiIdentifier: "gpt-4o",
            costPerRequest: 0.01,
            iconName: "openai",
            iconColor: .green
        ),
        AIModelInfo(
            id: "gpt-4o-mini",
            name: "GPT-4o Mini",
            provider: "OpenAI",
            apiIdentifier: "gpt-4o-mini",
            costPerRequest: 0.001,
            iconName: "openai",
            iconColor: .green
        ),
        AIModelInfo(
            id: "claude-3-opus",
            name: "Claude 3 Opus",
            provider: "Anthropic",
            apiIdentifier: "claude-3-opus-20240229",
            costPerRequest: 0.015,
            iconName: "sparkle",
            iconColor: .purple
        ),
        AIModelInfo(
            id: "claude-3-sonnet",
            name: "Claude 3 Sonnet",
            provider: "Anthropic",
            apiIdentifier: "claude-3-sonnet-20240229",
            costPerRequest: 0.003,
            iconName: "sparkle",
            iconColor: .blue
        ),
        AIModelInfo(
            id: "claude-3-haiku",
            name: "Claude 3 Haiku",
            provider: "Anthropic",
            apiIdentifier: "claude-3-haiku-20240307",
            costPerRequest: 0.00025,
            iconName: "sparkle",
            iconColor: .teal
        ),
        AIModelInfo(
            id: "gemini-pro",
            name: "Gemini Pro",
            provider: "Google",
            apiIdentifier: "gemini-pro",
            costPerRequest: 0.0005,
            iconName: "g.circle",
            iconColor: .orange
        )
    ]
    
    // Helper to get model information by ID
    static func getModelById(_ id: String) -> AIModelInfo {
        return allModels.first { $0.id == id } ?? allModels[0]
    }
} 