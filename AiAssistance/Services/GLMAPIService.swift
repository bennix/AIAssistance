//
//  GLMAPIService.swift
//  AiAssistance
//
//  Created by Kiro on 2025/8/2.
//

import Foundation

class GLMAPIService: ObservableObject {
    private let baseURL = "https://open.bigmodel.cn/api/paas/v4/chat/completions"
    private let session = URLSession.shared
    private var apiKey: String = ""
    
    init(apiKey: String = "") {
        self.apiKey = apiKey
        if apiKey.isEmpty {
            self.apiKey = APIConfiguration.shared.getAPIKey() ?? ""
        }
    }
    
    func setAPIKey(_ key: String) {
        self.apiKey = key
    }
    
    func sendStreamingRequest(messages: [GLMMessage]) async throws -> AsyncThrowingStream<String, Error> {
        print("🚀 Starting API request...")
        print("📝 Messages count: \(messages.count)")
        for (index, message) in messages.enumerated() {
            print("📝 Message \(index): \(message.role) - \(message.content)")
        }
        
        guard !apiKey.isEmpty else {
            print("❌ API key is empty")
            throw GLMAPIError.invalidAPIKey
        }
        print("🔑 API key available: \(apiKey.prefix(10))...")
        
        guard let url = URL(string: baseURL) else {
            print("❌ Invalid URL: \(baseURL)")
            throw GLMAPIError.invalidURL
        }
        print("🌐 URL: \(url)")
        
        let request = GLMRequest(messages: messages)
        print("📦 Request created: \(request)")
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("text/event-stream", forHTTPHeaderField: "Accept")
        
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            urlRequest.httpBody = try encoder.encode(request)
            if let bodyString = String(data: urlRequest.httpBody!, encoding: .utf8) {
                print("📤 Request body: \(bodyString)")
            }
        } catch {
            print("❌ Failed to encode request: \(error)")
            throw GLMAPIError.decodingError(error)
        }
        
        return AsyncThrowingStream { continuation in
            Task {
                do {
                    print("📡 Sending request...")
                    let (data, response) = try await session.data(for: urlRequest)
                    print("📥 Received response")
                    
                    guard let httpResponse = response as? HTTPURLResponse else {
                        print("❌ Invalid HTTP response")
                        continuation.finish(throwing: GLMAPIError.invalidResponse)
                        return
                    }
                    
                    print("📊 Status code: \(httpResponse.statusCode)")
                    print("📋 Headers: \(httpResponse.allHeaderFields)")
                    
                    guard httpResponse.statusCode == 200 else {
                        let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                        print("❌ API Error (\(httpResponse.statusCode)): \(errorMessage)")
                        continuation.finish(throwing: GLMAPIError.serverError(httpResponse.statusCode))
                        return
                    }
                    
                    let responseString = String(data: data, encoding: .utf8) ?? ""
                    print("📄 Raw response: \(responseString)")
                    
                    let lines = responseString.components(separatedBy: .newlines)
                    print("📝 Response lines count: \(lines.count)")
                    
                    var chunkCount = 0
                    for line in lines {
                        if line.hasPrefix("data: ") {
                            let jsonString = String(line.dropFirst(6))
                            print("🔍 Processing chunk \(chunkCount): \(jsonString)")
                            
                            if jsonString.trimmingCharacters(in: .whitespacesAndNewlines) == "[DONE]" {
                                print("✅ Stream finished with [DONE]")
                                continuation.finish()
                                return
                            }
                            
                            if let jsonData = jsonString.data(using: .utf8) {
                                do {
                                    let streamResponse = try JSONDecoder().decode(GLMStreamResponse.self, from: jsonData)
                                    if let content = streamResponse.deltaContent {
                                        print("💬 Content chunk: '\(content)'")
                                        continuation.yield(content)
                                        chunkCount += 1
                                    } else {
                                        print("⚠️ No content in chunk")
                                    }
                                } catch {
                                    print("⚠️ Failed to decode chunk: \(error)")
                                    continue
                                }
                            }
                        }
                    }
                    
                    print("✅ Stream finished naturally")
                    continuation.finish()
                } catch {
                    print("❌ Network error: \(error)")
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    // Convert ChatMessage to GLMMessage
    func convertMessages(_ chatMessages: [ChatMessage]) -> [GLMMessage] {
        return chatMessages.map { message in
            GLMMessage(
                role: message.isFromUser ? "user" : "assistant",
                content: message.content
            )
        }
    }
}

