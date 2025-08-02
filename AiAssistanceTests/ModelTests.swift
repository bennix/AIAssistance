//
//  ModelTests.swift
//  AiAssistanceTests
//
//  Created by Kiro on 2025/8/2.
//

import XCTest
@testable import AiAssistance

final class ModelTests: XCTestCase {
    
    // MARK: - ChatMessage Tests
    func testChatMessageCreation() {
        let message = ChatMessage(content: "Test message", isFromUser: true)
        
        XCTAssertEqual(message.content, "Test message")
        XCTAssertTrue(message.isFromUser)
        XCTAssertFalse(message.isStreaming)
        XCTAssertNotNil(message.id)
        XCTAssertTrue(message.isValid)
    }
    
    func testChatMessageConvenienceInitializers() {
        let userMessage = ChatMessage.userMessage("Hello")
        let aiMessage = ChatMessage.aiMessage("Hi there", isStreaming: true)
        
        XCTAssertTrue(userMessage.isFromUser)
        XCTAssertEqual(userMessage.content, "Hello")
        XCTAssertFalse(userMessage.isStreaming)
        
        XCTAssertFalse(aiMessage.isFromUser)
        XCTAssertEqual(aiMessage.content, "Hi there")
        XCTAssertTrue(aiMessage.isStreaming)
    }
    
    func testChatMessageValidation() {
        let validMessage = ChatMessage(content: "Valid content", isFromUser: true)
        let invalidMessage = ChatMessage(content: "   ", isFromUser: true)
        let emptyMessage = ChatMessage(content: "", isFromUser: true)
        
        XCTAssertTrue(validMessage.isValid)
        XCTAssertFalse(invalidMessage.isValid)
        XCTAssertFalse(emptyMessage.isValid)
    }
    
    func testChatMessageUpdating() {
        let originalMessage = ChatMessage.aiMessage("Original", isStreaming: true)
        let updatedMessage = originalMessage.updatingContent("Updated content")
        let finishedMessage = originalMessage.finishStreaming()
        
        XCTAssertEqual(originalMessage.id, updatedMessage.id)
        XCTAssertEqual(updatedMessage.content, "Updated content")
        XCTAssertTrue(updatedMessage.isStreaming)
        
        XCTAssertEqual(originalMessage.id, finishedMessage.id)
        XCTAssertFalse(finishedMessage.isStreaming)
    }
    
    func testChatMessageCodable() throws {
        let originalMessage = ChatMessage(content: "Test", isFromUser: true)
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(originalMessage)
        
        let decoder = JSONDecoder()
        let decodedMessage = try decoder.decode(ChatMessage.self, from: data)
        
        XCTAssertEqual(originalMessage.id, decodedMessage.id)
        XCTAssertEqual(originalMessage.content, decodedMessage.content)
        XCTAssertEqual(originalMessage.isFromUser, decodedMessage.isFromUser)
    }
    
    // MARK: - GLMMessage Tests
    func testGLMMessageCreation() {
        let message = GLMMessage(role: "user", content: "Hello")
        
        XCTAssertEqual(message.role, "user")
        XCTAssertEqual(message.content, "Hello")
        XCTAssertTrue(message.isValid)
    }
    
    func testGLMMessageConvenienceInitializers() {
        let userMessage = GLMMessage.user("User message")
        let assistantMessage = GLMMessage.assistant("Assistant message")
        let systemMessage = GLMMessage.system("System message")
        
        XCTAssertEqual(userMessage.role, GLMMessage.userRole)
        XCTAssertEqual(assistantMessage.role, GLMMessage.assistantRole)
        XCTAssertEqual(systemMessage.role, GLMMessage.systemRole)
    }
    
    func testGLMMessageValidation() {
        let validMessage = GLMMessage.user("Valid content")
        let invalidRoleMessage = GLMMessage(role: "invalid", content: "Content")
        let emptyContentMessage = GLMMessage.user("")
        
        XCTAssertTrue(validMessage.isValid)
        XCTAssertFalse(invalidRoleMessage.isValid)
        XCTAssertFalse(emptyContentMessage.isValid)
    }
    
    // MARK: - GLMRequest Tests
    func testGLMRequestCreation() {
        let messages = [GLMMessage.user("Hello")]
        let request = GLMRequest(messages: messages)
        
        XCTAssertEqual(request.model, "glm-4.5-air")
        XCTAssertTrue(request.stream)
        XCTAssertEqual(request.messages.count, 1)
        XCTAssertEqual(request.messages.first?.content, "Hello")
        XCTAssertTrue(request.isValid)
    }
    
    func testGLMRequestValidation() {
        let validRequest = GLMRequest(messages: [GLMMessage.user("Hello")])
        let emptyMessagesRequest = GLMRequest(messages: [])
        let invalidTemperatureRequest = GLMRequest(messages: [GLMMessage.user("Hello")], temperature: 3.0)
        
        XCTAssertTrue(validRequest.isValid)
        XCTAssertFalse(emptyMessagesRequest.isValid)
        XCTAssertFalse(invalidTemperatureRequest.isValid)
    }
    
    func testGLMRequestFromChatMessages() {
        let chatMessages = [
            ChatMessage.userMessage("Hello"),
            ChatMessage.aiMessage("Hi there"),
            ChatMessage.userMessage("How are you?"),
            ChatMessage.aiMessage("", isStreaming: true) // Should be filtered out
        ]
        
        let request = GLMRequest.fromChatMessages(chatMessages)
        
        XCTAssertEqual(request.messages.count, 3) // Streaming message should be filtered
        XCTAssertEqual(request.messages[0].role, "user")
        XCTAssertEqual(request.messages[1].role, "assistant")
        XCTAssertEqual(request.messages[2].role, "user")
    }
    
    // MARK: - GLMStreamResponse Tests
    func testGLMStreamResponseParsing() throws {
        let jsonString = """
        {
            "id": "test-id",
            "object": "chat.completion.chunk",
            "created": 1234567890,
            "model": "glm-4.5-air",
            "choices": [{
                "index": 0,
                "delta": {
                    "content": "Hello"
                },
                "finish_reason": null
            }]
        }
        """
        
        let data = jsonString.data(using: .utf8)!
        let response = try JSONDecoder().decode(GLMStreamResponse.self, from: data)
        
        XCTAssertEqual(response.id, "test-id")
        XCTAssertEqual(response.deltaContent, "Hello")
        XCTAssertFalse(response.isFinished)
        XCTAssertNotNil(response.firstChoice)
    }
    
    func testGLMStreamResponseFinished() throws {
        let jsonString = """
        {
            "id": "test-id",
            "object": "chat.completion.chunk",
            "created": 1234567890,
            "model": "glm-4.5-air",
            "choices": [{
                "index": 0,
                "delta": {},
                "finish_reason": "stop"
            }]
        }
        """
        
        let data = jsonString.data(using: .utf8)!
        let response = try JSONDecoder().decode(GLMStreamResponse.self, from: data)
        
        XCTAssertTrue(response.isFinished)
        XCTAssertEqual(response.firstChoice?.finishReason, GLMChoice.finishReasonStop)
    }
    
    // MARK: - Error Handling Tests
    func testGLMErrorParsing() throws {
        let jsonString = """
        {
            "error": {
                "message": "Invalid API key",
                "type": "authentication_error",
                "code": "invalid_api_key"
            }
        }
        """
        
        let data = jsonString.data(using: .utf8)!
        let error = try JSONDecoder().decode(GLMError.self, from: data)
        
        XCTAssertEqual(error.error.message, "Invalid API key")
        XCTAssertEqual(error.error.type, "authentication_error")
        XCTAssertTrue(error.localizedDescription.contains("认证失败"))
    }
}