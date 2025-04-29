import Foundation
import Combine

class AIService {
    private let baseURL = "https://api.openai.com/v1/chat/completions"
    
    func generateResponse(prompt: String, systemPrompt: String, apiKey: String, model: String) -> AnyPublisher<String, Error> {
        guard let url = URL(string: baseURL) else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }
        
        // Create the request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        // Create the message payload
        let messages: [[String: String]] = [
            ["role": "system", "content": systemPrompt],
            ["role": "user", "content": prompt]
        ]
        
        let payload: [String: Any] = [
            "model": model,
            "messages": messages,
            "temperature": 0.7,
            "max_tokens": 1000
        ]
        
        // Convert payload to JSON
        guard let httpBody = try? JSONSerialization.data(withJSONObject: payload) else {
            return Fail(error: URLError(.cannotParseResponse)).eraseToAnyPublisher()
        }
        request.httpBody = httpBody
        
        // Make the API call
        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { data, response -> Data in
                guard let httpResponse = response as? HTTPURLResponse,
                      httpResponse.statusCode == 200 else {
                    let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
                    let responseString = String(data: data, encoding: .utf8) ?? "No response"
                    throw NSError(domain: "AIService", code: statusCode, 
                                 userInfo: [NSLocalizedDescriptionKey: "API Error: \(responseString)"])
                }
                return data
            }
            .decode(type: OpenAIResponse.self, decoder: JSONDecoder())
            .map { response -> String in
                if let message = response.choices.first?.message.content {
                    return message
                } else {
                    return "No response generated."
                }
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    func processWithAction(text: String, action: AIAction, apiKey: String, model: String) -> AnyPublisher<String, Error> {
        // Use the action's system prompt
        return generateResponse(
            prompt: text,
            systemPrompt: action.systemPrompt,
            apiKey: apiKey,
            model: model
        )
    }
    
    // Quick simulated response for when API key isn't set up or for faster preview
    func simulateResponseForAction(text: String, action: AIAction) -> AnyPublisher<String, Error> {
        return Future<String, Error> { promise in
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
                }
                
                promise(.success(response))
            }
        }.eraseToAnyPublisher()
    }
}

// MARK: - Response Models

struct OpenAIResponse: Decodable {
    let id: String
    let choices: [Choice]
    
    struct Choice: Decodable {
        let message: Message
    }
    
    struct Message: Decodable {
        let content: String
    }
} 