//
//  APIConfigurationTests.swift
//  AiAssistanceTests
//
//  Created by Kiro on 2025/8/2.
//

import XCTest
@testable import AiAssistance

final class APIConfigurationTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Clean up keychain before each test
        APIConfiguration.shared.setAPIKey("")
    }
    
    func testAPIURL() {
        let config = APIConfiguration.shared
        XCTAssertNotNil(config.apiURL)
        XCTAssertEqual(config.apiURL?.absoluteString, "https://open.bigmodel.cn/api/paas/v4/chat/completions")
    }
    
    func testAPIKeyStorage() {
        let config = APIConfiguration.shared
        let testKey = "test-api-key-12345"
        
        // Initially should have no key
        XCTAssertFalse(config.hasValidAPIKey())
        
        // Set key
        config.setAPIKey(testKey)
        
        // Should now have valid key
        XCTAssertTrue(config.hasValidAPIKey())
        XCTAssertEqual(config.getAPIKey(), testKey)
    }
    
    func testAuthHeaders() {
        let config = APIConfiguration.shared
        let testKey = "test-api-key-12345"
        
        // Without API key
        let emptyHeaders = config.authHeaders()
        XCTAssertTrue(emptyHeaders.isEmpty)
        
        // With API key
        config.setAPIKey(testKey)
        let headers = config.authHeaders()
        
        XCTAssertEqual(headers["Authorization"], "Bearer \(testKey)")
        XCTAssertEqual(headers["Content-Type"], "application/json")
        XCTAssertEqual(headers["Accept"], "text/event-stream")
    }
    
    func testDefaultAPIKeySetup() {
        let config = APIConfiguration.shared
        
        config.setupDefaultAPIKey()
        
        XCTAssertTrue(config.hasValidAPIKey())
        XCTAssertNotNil(config.getAPIKey())
        XCTAssertTrue(config.getAPIKey()!.contains("."))
    }
}