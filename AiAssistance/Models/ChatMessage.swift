//
//  ChatMessage.swift
//  AiAssistance
//
//  Created by Kiro on 2025/8/2.
//

import Foundation

struct ChatMessage: Identifiable, Codable, Equatable {
    let id: UUID
    let content: String
    let isFromUser: Bool
    let timestamp: Date
    let isStreaming: Bool
    
    init(id: UUID = UUID(), content: String, isFromUser: Bool, timestamp: Date = Date(), isStreaming: Bool = false) {
        self.id = id
        self.content = content
        self.isFromUser = isFromUser
        self.timestamp = timestamp
        self.isStreaming = isStreaming
    }
    
    // MARK: - Convenience Initializers
    static func userMessage(_ content: String) -> ChatMessage {
        ChatMessage(content: content, isFromUser: true)
    }
    
    static func aiMessage(_ content: String, isStreaming: Bool = false) -> ChatMessage {
        ChatMessage(content: content, isFromUser: false, isStreaming: isStreaming)
    }
    
    // MARK: - Validation
    var isValid: Bool {
        !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    // MARK: - Formatting
    var formattedTimestamp: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }
    
    // MARK: - Update Methods
    func updatingContent(_ newContent: String) -> ChatMessage {
        ChatMessage(
            id: self.id,
            content: newContent,
            isFromUser: self.isFromUser,
            timestamp: self.timestamp,
            isStreaming: self.isStreaming
        )
    }
    
    func finishStreaming() -> ChatMessage {
        ChatMessage(
            id: self.id,
            content: self.content,
            isFromUser: self.isFromUser,
            timestamp: self.timestamp,
            isStreaming: false
        )
    }
}