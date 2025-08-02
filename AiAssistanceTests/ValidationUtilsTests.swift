//
//  ValidationUtilsTests.swift
//  AiAssistanceTests
//
//  Created by Kiro on 2025/8/2.
//

import XCTest
@testable import AiAssistance

final class ValidationUtilsTests: XCTestCase {
    
    func testTextValidation() {
        XCTAssertTrue(ValidationUtils.isValidText("Valid text"))
        XCTAssertTrue(ValidationUtils.isValidText("  Valid with spaces  "))
        XCTAssertFalse(ValidationUtils.isValidText(""))
        XCTAssertFalse(ValidationUtils.isValidText("   "))
        XCTAssertFalse(ValidationUtils.isValidText("\n\t"))
    }
    
    func testTextSanitization() {
        XCTAssertEqual(ValidationUtils.sanitizeText("  Hello World  "), "Hello World")
        XCTAssertEqual(ValidationUtils.sanitizeText("\n\tTest\n"), "Test")
        XCTAssertEqual(ValidationUtils.sanitizeText("NoSpaces"), "NoSpaces")
    }
    
    func testTemperatureValidation() {
        XCTAssertTrue(ValidationUtils.isValidTemperature(0.0))
        XCTAssertTrue(ValidationUtils.isValidTemperature(0.7))
        XCTAssertTrue(ValidationUtils.isValidTemperature(2.0))
        XCTAssertFalse(ValidationUtils.isValidTemperature(-0.1))
        XCTAssertFalse(ValidationUtils.isValidTemperature(2.1))
    }
    
    func testMaxTokensValidation() {
        XCTAssertTrue(ValidationUtils.isValidMaxTokens(1))
        XCTAssertTrue(ValidationUtils.isValidMaxTokens(1000))
        XCTAssertTrue(ValidationUtils.isValidMaxTokens(4096))
        XCTAssertFalse(ValidationUtils.isValidMaxTokens(0))
        XCTAssertFalse(ValidationUtils.isValidMaxTokens(-1))
        XCTAssertFalse(ValidationUtils.isValidMaxTokens(4097))
    }
    
    func testTopPValidation() {
        XCTAssertTrue(ValidationUtils.isValidTopP(nil))
        XCTAssertTrue(ValidationUtils.isValidTopP(0.1))
        XCTAssertTrue(ValidationUtils.isValidTopP(1.0))
        XCTAssertFalse(ValidationUtils.isValidTopP(0.0))
        XCTAssertFalse(ValidationUtils.isValidTopP(1.1))
    }
    
    func testChatMessageValidation() {
        let messages = [
            ChatMessage.userMessage("Valid message"),
            ChatMessage.userMessage(""),
            ChatMessage.userMessage("   "),
            ChatMessage.aiMessage("Another valid message")
        ]
        
        let validMessages = ValidationUtils.validateChatMessages(messages)
        XCTAssertEqual(validMessages.count, 2)
        XCTAssertEqual(validMessages[0].content, "Valid message")
        XCTAssertEqual(validMessages[1].content, "Another valid message")
    }
    
    func testGLMMessageValidation() {
        let messages = [
            GLMMessage.user("Valid message"),
            GLMMessage.user(""),
            GLMMessage(role: "invalid", content: "Invalid role"),
            GLMMessage.assistant("Valid assistant message")
        ]
        
        let validMessages = ValidationUtils.validateGLMMessages(messages)
        XCTAssertEqual(validMessages.count, 2)
        XCTAssertEqual(validMessages[0].content, "Valid message")
        XCTAssertEqual(validMessages[1].content, "Valid assistant message")
    }
    
    func testAPIKeyValidation() {
        XCTAssertTrue(ValidationUtils.isValidAPIKeyFormat("5ad89a67b59f45d2a51c9dca6971ffe4.RlnsgxsvEw0wRhLk"))
        XCTAssertTrue(ValidationUtils.isValidAPIKeyFormat("valid.api.key.with.dots"))
        XCTAssertFalse(ValidationUtils.isValidAPIKeyFormat("short"))
        XCTAssertFalse(ValidationUtils.isValidAPIKeyFormat(""))
        XCTAssertFalse(ValidationUtils.isValidAPIKeyFormat("nodots"))
    }
    
    func testRateLimiting() {
        let now = Date()
        let oneSecondAgo = now.addingTimeInterval(-1.0)
        let halfSecondAgo = now.addingTimeInterval(-0.5)
        
        XCTAssertTrue(ValidationUtils.shouldAllowRequest(lastRequestTime: oneSecondAgo))
        XCTAssertFalse(ValidationUtils.shouldAllowRequest(lastRequestTime: halfSecondAgo))
    }
    
    func testStringExtensions() {
        XCTAssertTrue("Valid content".isValidChatContent)
        XCTAssertFalse("   ".isValidChatContent)
        
        XCTAssertEqual("  Hello World  ".sanitized, "Hello World")
        
        XCTAssertTrue("5ad89a67b59f45d2a51c9dca6971ffe4.RlnsgxsvEw0wRhLk".isValidAPIKey)
        XCTAssertFalse("invalid".isValidAPIKey)
    }
}