//
//  GLMModels.swift
//  AiAssistance
//
//  Created by Kiro on 2025/8/2.
//

import Foundation

// MARK: - Request Models
struct GLMRequest: Codable {
    let model: String
    let messages: [GLMMessage]
    let stream: Bool
    let temperature: Double
    let maxTokens: Int
    let topP: Double?
    let stop: [String]?
    
    enum CodingKeys: String, CodingKey {
        case model, messages, stream, temperature, stop
        case maxTokens = "max_tokens"
        case topP = "top_p"
    }
    
    init(messages: [GLMMessage], 
         model: String = "glm-4.5-air", 
         stream: Bool = true, 
         temperature: Double = 0.7, 
         maxTokens: Int = 1000,
         topP: Double? = nil,
         stop: [String]? = nil) {
        self.model = model
        self.messages = messages
        self.stream = stream
        self.temperature = temperature
        self.maxTokens = maxTokens
        self.topP = topP
        self.stop = stop
    }
    
    // MARK: - Validation
    var isValid: Bool {
        !messages.isEmpty && 
        temperature >= 0 && temperature <= 2 &&
        maxTokens > 0 && maxTokens <= 4096
    }
    
    // MARK: - Convenience Methods
    static func fromChatMessages(_ chatMessages: [ChatMessage]) -> GLMRequest {
        let glmMessages = chatMessages.compactMap { message -> GLMMessage? in
            guard message.isValid && !message.isStreaming else { return nil }
            return GLMMessage(
                role: message.isFromUser ? "user" : "assistant",
                content: message.content
            )
        }
        return GLMRequest(messages: glmMessages)
    }
}

struct GLMMessage: Codable, Equatable {
    let role: String
    let content: String
    
    init(role: String, content: String) {
        self.role = role
        self.content = content
    }
    
    // MARK: - Role Constants
    static let userRole = "user"
    static let assistantRole = "assistant"
    static let systemRole = "system"
    
    // MARK: - Convenience Initializers
    static func user(_ content: String) -> GLMMessage {
        GLMMessage(role: userRole, content: content)
    }
    
    static func assistant(_ content: String) -> GLMMessage {
        GLMMessage(role: assistantRole, content: content)
    }
    
    static func system(_ content: String) -> GLMMessage {
        GLMMessage(role: systemRole, content: content)
    }
    
    // MARK: - Validation
    var isValid: Bool {
        !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        [GLMMessage.userRole, GLMMessage.assistantRole, GLMMessage.systemRole].contains(role)
    }
}

// MARK: - Response Models
struct GLMStreamResponse: Codable {
    let id: String
    let object: String?  // Make object optional since it might not be present
    let created: Int
    let model: String
    let choices: [GLMChoice]
    let usage: GLMUsage?  // Add usage field that appears in the logs
    
    // MARK: - Convenience Properties
    var firstChoice: GLMChoice? {
        choices.first
    }
    
    var deltaContent: String? {
        firstChoice?.delta.content
    }
    
    var isFinished: Bool {
        firstChoice?.finishReason != nil
    }
}

struct GLMChoice: Codable {
    let index: Int
    let delta: GLMDelta
    let finishReason: String?
    
    enum CodingKeys: String, CodingKey {
        case index, delta
        case finishReason = "finish_reason"
    }
    
    // MARK: - Finish Reason Constants
    static let finishReasonStop = "stop"
    static let finishReasonLength = "length"
    static let finishReasonContentFilter = "content_filter"
}

struct GLMDelta: Codable {
    let content: String?
    let role: String?
    
    // MARK: - Convenience Properties
    var hasContent: Bool {
        content != nil && !content!.isEmpty
    }
}

struct GLMUsage: Codable {
    let promptTokens: Int
    let completionTokens: Int
    let totalTokens: Int
    let promptTokensDetails: GLMPromptTokensDetails?
    
    enum CodingKeys: String, CodingKey {
        case promptTokens = "prompt_tokens"
        case completionTokens = "completion_tokens"
        case totalTokens = "total_tokens"
        case promptTokensDetails = "prompt_tokens_details"
    }
}

struct GLMPromptTokensDetails: Codable {
    let cachedTokens: Int
    
    enum CodingKeys: String, CodingKey {
        case cachedTokens = "cached_tokens"
    }
}

// MARK: - Error Models
struct GLMError: Codable, Error, LocalizedError {
    let error: GLMErrorDetail
    
    var errorDescription: String? {
        error.message
    }
    
    var localizedDescription: String {
        switch error.type {
        case "invalid_request_error":
            return "请求参数错误: \(error.message)"
        case "authentication_error":
            return "认证失败: 请检查API密钥"
        case "permission_error":
            return "权限不足: \(error.message)"
        case "not_found_error":
            return "资源未找到: \(error.message)"
        case "rate_limit_error":
            return "请求频率过高，请稍后再试"
        case "api_error":
            return "API服务错误: \(error.message)"
        case "overloaded_error":
            return "服务器繁忙，请稍后再试"
        default:
            return "未知错误: \(error.message)"
        }
    }
}

struct GLMErrorDetail: Codable {
    let message: String
    let type: String
    let code: String?
}

// MARK: - Network Error Types
enum GLMAPIError: Error, LocalizedError {
    case invalidURL
    case noData
    case invalidResponse
    case decodingError(Error)
    case networkError(Error)
    case invalidAPIKey
    case rateLimitExceeded
    case serverError(Int)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "无效的API地址"
        case .noData:
            return "服务器未返回数据"
        case .invalidResponse:
            return "服务器响应格式错误"
        case .decodingError(let error):
            return "数据解析错误: \(error.localizedDescription)"
        case .networkError(let error):
            return "网络连接错误: \(error.localizedDescription)"
        case .invalidAPIKey:
            return "API密钥无效或已过期"
        case .rateLimitExceeded:
            return "请求频率过高，请稍后再试"
        case .serverError(let code):
            return "服务器错误 (代码: \(code))"
        }
    }
}