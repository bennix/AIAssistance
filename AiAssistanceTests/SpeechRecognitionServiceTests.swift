//
//  SpeechRecognitionServiceTests.swift
//  AiAssistanceTests
//
//  Created by Kiro on 2025/8/2.
//

import XCTest
import Speech
import AVFoundation
@testable import AiAssistance

@MainActor
final class SpeechRecognitionServiceTests: XCTestCase {
    
    var speechService: SpeechRecognitionService!
    
    override func setUp() {
        super.setUp()
        speechService = SpeechRecognitionService()
    }
    
    override func tearDown() {
        speechService?.stopRecording()
        speechService = nil
        super.tearDown()
    }
    
    func testInitialState() {
        XCTAssertFalse(speechService.isRecording)
        XCTAssertTrue(speechService.transcribedText.isEmpty)
        XCTAssertEqual(speechService.speechPermissionStatus, .notDetermined)
        XCTAssertEqual(speechService.microphonePermissionStatus, .undetermined)
    }
    
    func testPermissionStatusMessage() {
        // Test when speech permission is not authorized
        speechService.speechPermissionStatus = .denied
        XCTAssertFalse(speechService.permissionStatusMessage.isEmpty)
        XCTAssertTrue(speechService.permissionStatusMessage.contains("语音识别权限"))
        
        // Test when microphone permission is not granted
        speechService.speechPermissionStatus = .authorized
        speechService.microphonePermissionStatus = .denied
        XCTAssertFalse(speechService.permissionStatusMessage.isEmpty)
        XCTAssertTrue(speechService.permissionStatusMessage.contains("麦克风权限"))
        
        // Test when service is not available
        speechService.speechPermissionStatus = .authorized
        speechService.microphonePermissionStatus = .granted
        speechService.isAvailable = false
        XCTAssertFalse(speechService.permissionStatusMessage.isEmpty)
        XCTAssertTrue(speechService.permissionStatusMessage.contains("不可用"))
        
        // Test when all permissions are granted
        speechService.speechPermissionStatus = .authorized
        speechService.microphonePermissionStatus = .granted
        speechService.isAvailable = true
        XCTAssertTrue(speechService.permissionStatusMessage.isEmpty)
    }
    
    func testHasAllPermissions() {
        // Initially should not have all permissions
        XCTAssertFalse(speechService.hasAllPermissions)
        
        // Set permissions
        speechService.speechPermissionStatus = .authorized
        speechService.microphonePermissionStatus = .granted
        XCTAssertTrue(speechService.hasAllPermissions)
        
        // Remove one permission
        speechService.speechPermissionStatus = .denied
        XCTAssertFalse(speechService.hasAllPermissions)
    }
    
    func testStopRecordingWhenNotRecording() {
        // Should not crash when stopping recording when not recording
        XCTAssertFalse(speechService.isRecording)
        speechService.stopRecording()
        XCTAssertFalse(speechService.isRecording)
    }
    
    func testErrorTypes() {
        let permissionError = SpeechRecognitionError.permissionDenied
        XCTAssertNotNil(permissionError.errorDescription)
        XCTAssertTrue(permissionError.errorDescription!.contains("权限"))
        
        let unavailableError = SpeechRecognitionError.recognizerUnavailable
        XCTAssertNotNil(unavailableError.errorDescription)
        XCTAssertTrue(unavailableError.errorDescription!.contains("不可用"))
        
        let requestError = SpeechRecognitionError.unableToCreateRequest
        XCTAssertNotNil(requestError.errorDescription)
        
        let testError = NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Test error"])
        let recognitionError = SpeechRecognitionError.recognitionFailed(testError)
        XCTAssertNotNil(recognitionError.errorDescription)
        XCTAssertTrue(recognitionError.errorDescription!.contains("Test error"))
    }
}