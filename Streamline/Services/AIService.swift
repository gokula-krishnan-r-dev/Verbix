import Foundation
import Combine
import SwiftUI
import os.log

// Import specific model files as needed
// This approach allows us to access the AIAction type that's defined in the project
// without causing redeclaration issues

// Simple Logger utility
class Logger {
    enum LogLevel: String {
        case debug = "DEBUG"
        case info = "INFO"
        case warning = "WARNING"
        case error = "ERROR"
        case critical = "CRITICAL"
    }
    
    static let shared = Logger()
    private let osLog = OSLog(subsystem: Bundle.main.bundleIdentifier ?? "com.streamline", category: "AIService")
    private var isDebugEnabled = true
    
    func log(_ message: String, level: LogLevel = .info, file: String = #file, function: String = #function, line: Int = #line) {
        let fileName = (file as NSString).lastPathComponent
        let logMessage = "[\(level.rawValue)] [\(fileName):\(line) \(function)] \(message)"
        
        if isDebugEnabled || level != .debug {
            switch level {
            case .debug:
                os_log("%{public}@", log: osLog, type: .debug, logMessage)
            case .info:
                os_log("%{public}@", log: osLog, type: .info, logMessage)
            case .warning:
                os_log("%{public}@", log: osLog, type: .default, logMessage)
            case .error, .critical:
                os_log("%{public}@", log: osLog, type: .error, logMessage)
            }
            
            #if DEBUG
            print(logMessage)
            #endif
        }
    }
}

// Remove unneeded typealias that references AIAction
#if !IMPORTED_AIACTION
private enum AIActionTemp {
    case fixSpellingGrammar
    case improveWriting
    case translate
    case makeShorter
    
    var systemPrompt: String {
        switch self {
        case .fixSpellingGrammar: return "Fix the spelling and grammar errors"
        case .improveWriting: return "Improve the writing quality"
        case .translate: return "Translate the text appropriately"
        case .makeShorter: return "Make the text more concise"
        }
    }
}
#endif

class AIService {
    private let baseURL = "http://localhost:8080/api/v1/ai/generate" // Update with your actual API URL
    private let logger = Logger.shared
      @EnvironmentObject var appState: AppState
    
    // Define actions directly in this class to avoid conflicts
    enum ActionType: String {
        case fixSpellingGrammar = "fixSpellingGrammar"
        case improveWriting = "improveWriting"
        case translate = "translate"
        case makeShorter = "makeShorter"
        case summarize = "summarize"
        
        // Default case for when the conversion fails
        static var defaultAction: ActionType {
            return .improveWriting
        }
        
        var systemPrompt: String {
            switch self {
            case .fixSpellingGrammar:
                return "Fix the spelling and grammar in the following text, without changing the meaning:"
            case .improveWriting:
                return "Improve the writing quality of the following text, making it clearer and more engaging:"
            case .translate:
                return "Translate the following text to English (or if it's already in English, translate to French):"
            case .makeShorter:
                return "Make the following text shorter and more concise, without losing the key points:"
            case .summarize:
                return "Summarize the following text, capturing the key points:"
            }
        }
    }
    
    func generateResponse(prompt: String, systemPrompt: String, model: String) -> AnyPublisher<String, Error> {
        logger.log("Generating response with \(systemPrompt) model: \(model)", level: .info)
        
        guard let url = URL(string: baseURL) else {
            logger.log("Invalid URL: \(baseURL)", level: .error)
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }
        
        // Create the request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let payload: [String: Any] = [
            "model": UserDefaults.standard.string(forKey: "aiModel") ?? "@cf/meta/llama-3.3-70b-instruct-fp8-fast",
            "text": prompt,
            "instruction": "You are a helpful assistant that can help with a variety of tasks. You are given a text and a task. You need to help the user with the task using the text. You can use the text to help you complete the task.",
        ]
        
        logger.log("Payload prepared: \(payload)", level: .debug)
        
        // Convert payload to JSON
        guard let httpBody = try? JSONSerialization.data(withJSONObject: payload) else {
            logger.log("Failed to serialize payload to JSON", level: .error)
            return Fail(error: URLError(.cannotParseResponse)).eraseToAnyPublisher()
        }
        request.httpBody = httpBody
        
        // Make the API call
        logger.log("Making API request to: \(url.absoluteString)", level: .debug)
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { [weak self] data, response -> Data in
                guard let self = self else { throw APIError.invalidResponse }
                guard let httpResponse = response as? HTTPURLResponse else {
                    self.logger.log("Invalid HTTP response", level: .error)
                    throw APIError.invalidResponse
                }
                
                let responseData = String(data: data, encoding: .utf8) ?? "Unable to decode response"
                self.logger.log("Received API response with status code: \(httpResponse.statusCode)", level: .debug)
                self.logger.log("Response body: \(responseData)", level: .debug)
                
                if !(200...299).contains(httpResponse.statusCode) {
                    self.logger.log("API error: Status \(httpResponse.statusCode) - \(responseData)", level: .error)
                    throw APIError.serverError(statusCode: httpResponse.statusCode, message: responseData)
                }
                
                return data
            }
            .decode(type: AIResponse.self, decoder: JSONDecoder())
            .map { [weak self] response in
                self?.logger.log("Successfully decoded response with \(response.usage?.totalTokens ?? 0) tokens", level: .info)
                if let toolCalls = response.toolCalls, !toolCalls.isEmpty {
                    self?.logger.log("Response includes tool calls", level: .debug)
                }
                return response.response
            }
            .catch { [weak self] error -> AnyPublisher<String, Error> in
                self?.logger.log("API Error: \(error.localizedDescription)", level: .error)
                if let apiError = error as? APIError {
                    self?.logger.log("Detailed API error: \(apiError.errorDescription ?? "Unknown error")", level: .error)
                }
                return Fail(error: error).eraseToAnyPublisher()
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    // Modified to use our internal ActionType
    func processWithAction(text: String, action: ActionType, apiKey: String, model: String) -> AnyPublisher<String, Error> {
        logger.log("Processing text with action", level: .info)
        
        return generateResponse(
            prompt: text,
            systemPrompt: action.systemPrompt,
            model: model
        )
    }
    
    // Quick simulated response for when API key isn't set up
    func simulateResponseForAction(text: String, action: ActionType) -> AnyPublisher<String, Error> {
        logger.log("Simulating response for action", level: .info)
        
        return Future<String, Error> { [weak self] promise in
            // Add a short delay to simulate processing
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                let response: String
                
                switch action {
                case .fixSpellingGrammar:
                    response = "I've fixed the spelling and grammar issues in your text:\n\n\(text.trimmingCharacters(in: .whitespacesAndNewlines))"
                    
                case .improveWriting:
                    response = "Here's an improved version of your text with better clarity and engagement:\n\n\(text.trimmingCharacters(in: .whitespacesAndNewlines))"
                    
                case .translate:
                    let isEnglish = text.range(of: "[^a-zA-Z0-9\\s.,?!]", options: .regularExpression) == nil
                    if isEnglish {
                        response = "Voici la traduction en français:\n\n\(text.trimmingCharacters(in: .whitespacesAndNewlines))"
                    } else {
                        response = "Here's the English translation:\n\n\(text.trimmingCharacters(in: .whitespacesAndNewlines))"
                    }
                    
                case .makeShorter:
                    let words = text.split(separator: " ")
                    let shortenedCount = max(3, Int(Double(words.count) * 0.6))
                    response = "Here's a more concise version:\n\n" + words.prefix(shortenedCount).joined(separator: " ")
                case .summarize:
                    response = "Here's a summary of your text:\n\n\(text.trimmingCharacters(in: .whitespacesAndNewlines))"
                }
                
                self?.logger.log("Generated simulated response", level: .debug)
                promise(.success(response))
            }
        }.eraseToAnyPublisher()
    }
    
    // Adapter method to convert from AIAction to our internal ActionType
    // This allows the existing code to keep working with AIAction
    func processWithAIAction(text: String, action: String, apiKey: String, model: String) -> AnyPublisher<String, Error> {
        // Convert string action to our internal action type
        let actionType: ActionType
        switch action.lowercased() {
        case "fixspellinggrammar":
            actionType = .fixSpellingGrammar
        case "improvewriting":
            actionType = .improveWriting
        case "translate":
            actionType = .translate
        case "makeshorter":
            actionType = .makeShorter
        default:
            actionType = .improveWriting // Default action
        }
        
        return processWithAction(text: text, action: actionType, apiKey: apiKey, model: model)
    }
    
    // Adapter for simulate method
    func simulateResponseForAIAction(text: String, action: String) -> AnyPublisher<String, Error> {
        // Convert string action to our internal action type
        let actionType: ActionType
        switch action.lowercased() {
        case "fixspellinggrammar":
            actionType = .fixSpellingGrammar
        case "improvewriting":
            actionType = .improveWriting
        case "translate":
            actionType = .translate
        case "makeshorter":
            actionType = .makeShorter
        default:
            actionType = .improveWriting // Default action
        }
        
        return simulateResponseForAction(text: text, action: actionType)
    }
}

// MARK: - Response Models

struct AIResponse: Decodable {
    let response: String
    let toolCalls: [ToolCall]?
    let usage: Usage?
    
    enum CodingKeys: String, CodingKey {
        case response
        case toolCalls = "tool_calls"
        case usage
    }
    
    struct ToolCall: Decodable {
        // Add properties as needed based on your API response
    }
    
    struct Usage: Decodable {
        let promptTokens: Int
        let completionTokens: Int
        let totalTokens: Int
        
        enum CodingKeys: String, CodingKey {
            case promptTokens = "prompt_tokens"
            case completionTokens = "completion_tokens"
            case totalTokens = "total_tokens"
        }
    }
}

// MARK: - Error Handling

enum APIError: Error, LocalizedError {
    case invalidResponse
    case serverError(statusCode: Int, message: String)
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from server"
        case .serverError(let statusCode, let message):
            return "Server error (code \(statusCode)): \(message)"
        }
    }
} 
