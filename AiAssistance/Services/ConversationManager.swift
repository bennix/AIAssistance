//
//  ConversationManager.swift
//  AiAssistance
//
//  Created by Kiro on 2025/8/2.
//

import Foundation

class ConversationManager: ObservableObject {
    @Published var messages: [ChatMessage] = []
    private let userDefaults = UserDefaults.standard
    private let messagesKey = "saved_messages"
    
    init() {
        loadMessages()
    }
    
    func addMessage(_ message: ChatMessage) {
        messages.append(message)
        saveMessages()
    }
    
    func updateMessage(id: UUID, content: String) {
        if let index = messages.firstIndex(where: { $0.id == id }) {
            let updatedMessage = ChatMessage(
                id: id,
                content: content,
                isFromUser: messages[index].isFromUser,
                timestamp: messages[index].timestamp,
                isStreaming: messages[index].isStreaming
            )
            messages[index] = updatedMessage
            saveMessages()
        }
    }
    
    func updateMessage(at index: Int, content: String) {
        guard index >= 0 && index < messages.count else { return }
        let currentMessage = messages[index]
        let updatedMessage = ChatMessage(
            id: currentMessage.id,
            content: content,
            isFromUser: currentMessage.isFromUser,
            timestamp: currentMessage.timestamp,
            isStreaming: currentMessage.isStreaming
        )
        messages[index] = updatedMessage
        saveMessages()
    }
    
    func updateMessage(at index: Int, message: ChatMessage) {
        guard index >= 0 && index < messages.count else { return }
        messages[index] = message
        saveMessages()
    }
    
    func removeLastMessage() {
        if !messages.isEmpty {
            messages.removeLast()
            saveMessages()
        }
    }
    
    func clearMessages() {
        messages.removeAll()
        saveMessages()
    }
    
    private func loadMessages() {
        // This will be implemented in task 5
    }
    
    private func saveMessages() {
        // This will be implemented in task 5
    }
}