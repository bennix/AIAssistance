//
//  ValidationUtils.swift
//  AiAssistance
//
//  Created by Kiro on 2025/8/2.
//

import Foundation

struct ValidationUtils {
    
    // MARK: - Text Validation
    static func isValidText(_ text: String) -> Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    static func sanitizeText(_ text: String) -> String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // MARK: - API Parameter Validation
    static func isValidTemperature(_ temperature: Double) -> Bool {
        temperature >= 0.0 && temperature <= 2.0
    }
    
    static func isValidMaxTokens(_ maxTokens: Int) -> Bool {
        maxTokens > 0 && maxTokens <= 4096
    }
    
    static func isValidTopP(_ topP: Double?) -> Bool {
        guard let topP = topP else { return true }
        return topP > 0.0 && topP <= 1.0
    }
    
    // MARK: - Message Validation
    static func validateChatMessages(_ messages: [ChatMessage]) -> [ChatMessage] {
        return messages.filter { message in
            message.isValid && !message.content.isEmpty
        }
    }
    
    static func validateGLMMessages(_ messages: [GLMMessage]) -> [GLMMessage] {
        return messages.filter { message in
            message.isValid
        }
    }
    
    // MARK: - API Key Validation
    static func isValidAPIKeyFormat(_ apiKey: String) -> Bool {
        let trimmed = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        // GLM API keys typically have a specific format
        return trimmed.count > 20 && trimmed.contains(".")
    }
    
    // MARK: - Content Filtering
    static func containsInappropriateContent(_ text: String) -> Bool {
        // Basic content filtering - can be expanded
        let inappropriateWords = ["spam", "abuse"] // Add more as needed
        let lowercaseText = text.lowercased()
        
        return inappropriateWords.contains { word in
            lowercaseText.contains(word)
        }
    }
    
    // MARK: - Rate Limiting Helpers
    static func shouldAllowRequest(lastRequestTime: Date, minimumInterval: TimeInterval = 1.0) -> Bool {
        Date().timeIntervalSince(lastRequestTime) >= minimumInterval
    }
}

// MARK: - String Extensions for Validation
extension String {
    var isValidChatContent: Bool {
        ValidationUtils.isValidText(self)
    }
    
    var sanitized: String {
        ValidationUtils.sanitizeText(self)
    }
    
    var isValidAPIKey: Bool {
        ValidationUtils.isValidAPIKeyFormat(self)
    }
}