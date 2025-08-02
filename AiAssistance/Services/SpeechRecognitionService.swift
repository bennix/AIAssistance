//
//  SpeechRecognitionService.swift
//  AiAssistance
//
//  Created by Kiro on 2025/8/2.
//

import Foundation
import Speech
import AVFoundation

class SpeechRecognitionService: NSObject, ObservableObject {
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "zh-CN"))
    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioSession = AVAudioSession.sharedInstance()
    
    @Published var isRecording = false
    @Published var transcribedText = ""
    @Published var isAvailable = false
    @Published var errorMessage: String?
    
    // Permission states
    @Published var speechPermissionStatus: SFSpeechRecognizerAuthorizationStatus = .notDetermined
    @Published var microphonePermissionStatus: AVAudioSession.RecordPermission = .undetermined
    
    override init() {
        super.init()
        // Delay setup to avoid crashes on init
        DispatchQueue.main.async {
            self.setupSpeechRecognizer()
            self.checkCurrentPermissions()
        }
    }
    
    private func setupSpeechRecognizer() {
        guard let recognizer = speechRecognizer else {
            DispatchQueue.main.async {
                self.isAvailable = false
                self.errorMessage = "语音识别不支持当前语言"
            }
            return
        }
        
        recognizer.delegate = self
        DispatchQueue.main.async {
            self.isAvailable = recognizer.isAvailable
        }
    }
    
    private func checkCurrentPermissions() {
        // Check current speech recognition permission
        speechPermissionStatus = SFSpeechRecognizer.authorizationStatus()
        
        // Check current microphone permission
        microphonePermissionStatus = audioSession.recordPermission
        
        print("Initial permission check - Speech: \(speechPermissionStatus), Microphone: \(microphonePermissionStatus)")
    }
    
    // MARK: - Permission Management
    func requestPermissions() async {
        await requestSpeechPermission()
        await requestMicrophonePermission()
        
        // Debug: Print permission status
        print("Speech permission: \(speechPermissionStatus)")
        print("Microphone permission: \(microphonePermissionStatus)")
        print("Has all permissions: \(hasAllPermissions)")
    }
    
    private func requestSpeechPermission() async {
        speechPermissionStatus = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                DispatchQueue.main.async {
                    self.speechPermissionStatus = status
                    continuation.resume(returning: status)
                }
            }
        }
    }
    
    private func requestMicrophonePermission() async {
        microphonePermissionStatus = await withCheckedContinuation { continuation in
            audioSession.requestRecordPermission { granted in
                DispatchQueue.main.async {
                    self.microphonePermissionStatus = granted ? .granted : .denied
                    continuation.resume(returning: granted ? .granted : .denied)
                }
            }
        }
    }
    
    // MARK: - Recording Control
    func startRecording() async throws {
        print("Starting recording...")
        
        // Clear any previous error
        errorMessage = nil
        
        // Request permissions if not already granted
        if speechPermissionStatus == .notDetermined || microphonePermissionStatus == .undetermined {
            print("Requesting permissions...")
            await requestPermissions()
        }
        
        // Check permissions again after request
        guard speechPermissionStatus == .authorized else {
            print("Speech permission not authorized: \(speechPermissionStatus)")
            throw SpeechRecognitionError.permissionDenied
        }
        
        guard microphonePermissionStatus == .granted else {
            print("Microphone permission not granted: \(microphonePermissionStatus)")
            throw SpeechRecognitionError.permissionDenied
        }
        
        guard let recognizer = speechRecognizer, recognizer.isAvailable else {
            print("Speech recognizer not available")
            throw SpeechRecognitionError.recognizerUnavailable
        }
        
        // Additional check for audio input availability on real devices
        guard audioSession.isInputAvailable else {
            print("Audio input not available on device")
            throw SpeechRecognitionError.audioEngineError
        }
        
        // Cancel any existing task
        stopRecording()
        
        // Add a longer delay to ensure cleanup is complete on real devices
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        // Setup audio session and start recognition
        do {
            try await setupAudioSession()
            try await startSpeechRecognition()
            
            isRecording = true
            transcribedText = ""
            print("Recording started successfully")
        } catch {
            print("Failed to start recording: \(error)")
            // Ensure cleanup on failure
            stopRecording()
            throw error
        }
    }
    
    func stopRecording() {
        print("🛑 Stopping recording (robust cleanup for real device)...")
        isRecording = false
        
        // Step 1: Cancel recognition task
        if let task = recognitionTask {
            task.cancel()
            recognitionTask = nil
            print("✅ Recognition task cancelled")
        }
        
        // Step 2: End recognition request
        if let request = recognitionRequest {
            request.endAudio()
            recognitionRequest = nil
            print("✅ Recognition request ended")
        }
        
        // Step 3: Stop audio engine with comprehensive cleanup
        if audioEngine.isRunning {
            print("Stopping audio engine...")
            
            // Remove tap safely
            do {
                let inputNode = audioEngine.inputNode
                inputNode.removeTap(onBus: 0)
                print("✅ Audio tap removed")
            } catch {
                print("⚠️ Warning: Could not remove audio tap: \(error)")
            }
            
            // Stop engine
            audioEngine.stop()
            print("✅ Audio engine stopped")
            
            // Reset engine
            audioEngine.reset()
            print("✅ Audio engine reset")
        }
        
        // Step 4: Deactivate audio session with retry mechanism
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            var deactivationAttempts = 0
            let maxDeactivationAttempts = 3
            
            func attemptDeactivation() {
                deactivationAttempts += 1
                
                do {
                    try self.audioSession.setActive(false, options: [])
                    print("✅ Audio session deactivated on attempt \(deactivationAttempts)")
                } catch let error as NSError {
                    print("⚠️ Audio session deactivation failed (attempt \(deactivationAttempts)): \(error)")
                    print("Error domain: \(error.domain), code: \(error.code)")
                    
                    if deactivationAttempts < maxDeactivationAttempts {
                        // Try again after a delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            attemptDeactivation()
                        }
                    } else {
                        print("❌ Could not deactivate audio session after \(maxDeactivationAttempts) attempts")
                        // Don't throw error here as this is cleanup
                    }
                }
            }
            
            attemptDeactivation()
        }
        
        print("🏁 Recording stop sequence initiated")
    }
    
    // MARK: - Private Methods
    private var canRecord: Bool {
        let hasPermissions = speechPermissionStatus == .authorized &&
                           microphonePermissionStatus == .granted &&
                           isAvailable
        
        // Additional check for audio input availability
        let hasAudioInput = audioSession.isInputAvailable
        
        print("Can record check - Permissions: \(hasPermissions), Audio input available: \(hasAudioInput)")
        
        return hasPermissions && hasAudioInput
    }
    
    private func setupAudioSession() async throws {
        print("🔧 Setting up audio session with minimal approach for real device...")
        
        // OSStatus -50 indicates invalid parameter, so let's use the most basic approach
        do {
            // Step 1: Try to deactivate any existing session (ignore errors)
            try? audioSession.setActive(false, options: [])
            print("📱 Attempted to deactivate existing audio session")
            
            // Step 2: Wait for system to process
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            
            // Step 3: Use the most basic audio session setup
            print("🎯 Using minimal audio session configuration...")
            
            // Set category without any options or mode - most compatible
            try audioSession.setCategory(.record)
            print("✅ Audio category set to .record (basic)")
            
            // Don't set preferred parameters - let system use defaults
            print("📊 Using system default audio parameters")
            
            // Step 4: Activate session with minimal options
            try audioSession.setActive(true)
            print("✅ Audio session activated successfully")
            
            // Step 5: Verify session is working
            print("🔍 Audio session verification:")
            print("  - Sample rate: \(audioSession.sampleRate)")
            print("  - Input channels: \(audioSession.inputNumberOfChannels)")
            print("  - Buffer duration: \(audioSession.ioBufferDuration)")
            print("  - Input available: \(audioSession.isInputAvailable)")
            print("  - Current route: \(audioSession.currentRoute)")
            
            // Verify we have audio input
            guard audioSession.isInputAvailable else {
                print("❌ Audio input not available")
                throw SpeechRecognitionError.audioEngineError
            }
            
            print("🎉 Audio session setup completed successfully!")
            
        } catch let error as NSError {
            print("❌ Audio session setup failed: \(error)")
            print("   Domain: \(error.domain)")
            print("   Code: \(error.code)")
            print("   Description: \(error.localizedDescription)")
            
            // For OSStatus -50, try one more time with even more basic settings
            if error.code == -50 {
                print("🔄 Attempting recovery with ultra-basic settings...")
                
                do {
                    // Wait longer
                    try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                    
                    // Try the most basic possible setup
                    try audioSession.setCategory(.record, options: [])
                    try audioSession.setActive(true)
                    
                    print("✅ Recovery successful with ultra-basic settings")
                    return
                    
                } catch {
                    print("❌ Recovery failed: \(error)")
                }
            }
            
            throw SpeechRecognitionError.audioEngineError
        }
    }
    
    private func startSpeechRecognition() async throws {
        print("Starting speech recognition...")
        
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            print("Speech recognizer not available")
            throw SpeechRecognitionError.recognizerUnavailable
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            print("Unable to create recognition request")
            throw SpeechRecognitionError.unableToCreateRequest
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        // Add timeout and other configurations
        if #available(iOS 13.0, *) {
            recognitionRequest.requiresOnDeviceRecognition = false
        }
        
        // Configure audio engine with simplified approach for real devices
        print("🎵 Setting up audio engine with minimal configuration...")
        
        do {
            // Step 1: Reset audio engine completely
            if audioEngine.isRunning {
                audioEngine.stop()
            }
            audioEngine.reset()
            print("🔄 Audio engine reset")
            
            // Step 2: Wait for engine to stabilize
            try await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
            
            // Step 3: Get input node and use its native format
            let inputNode = audioEngine.inputNode
            let recordingFormat = inputNode.outputFormat(forBus: 0)
            
            print("🎤 Input format: \(recordingFormat)")
            print("   Sample rate: \(recordingFormat.sampleRate)")
            print("   Channels: \(recordingFormat.channelCount)")
            
            // Validate format
            guard recordingFormat.sampleRate > 0 && recordingFormat.channelCount > 0 else {
                print("❌ Invalid recording format")
                throw SpeechRecognitionError.audioEngineError
            }
            
            // Step 4: Install tap with conservative buffer size
            let bufferSize: AVAudioFrameCount = 1024 // Smaller buffer for better compatibility
            print("🔧 Installing audio tap with buffer size: \(bufferSize)")
            
            inputNode.installTap(onBus: 0, bufferSize: bufferSize, format: recordingFormat) { [weak recognitionRequest] buffer, _ in
                recognitionRequest?.append(buffer)
            }
            print("✅ Audio tap installed")
            
            // Step 5: Prepare and start engine
            audioEngine.prepare()
            print("⚙️ Audio engine prepared")
            
            try audioEngine.start()
            print("🎉 Audio engine started successfully!")
            
        } catch let error as NSError {
            print("❌ Audio engine setup failed: \(error)")
            print("   Domain: \(error.domain)")
            print("   Code: \(error.code)")
            print("   Description: \(error.localizedDescription)")
            
            // Clean up on failure
            if audioEngine.isRunning {
                audioEngine.stop()
            }
            audioEngine.reset()
            
            throw SpeechRecognitionError.audioEngineError
        }
        
        // Start recognition task
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                if let result = result {
                    let newText = result.bestTranscription.formattedString
                    print("Recognition result: \(newText)")
                    print("Recognition result length: \(newText.count)")
                    print("Recognition result characters: \(Array(newText))")
                    print("Is final: \(result.isFinal)")
                    self.transcribedText = newText
                    print("Transcribed text set to: '\(self.transcribedText)'")
                    
                    if result.isFinal {
                        print("Recognition completed")
                        self.stopRecording()
                    }
                } else if let error = error {
                    print("Recognition error: \(error)")
                    self.handleRecognitionError(error)
                    self.stopRecording()
                }
            }
        }
        
        print("Speech recognition task started")
    }
    
    private func handleRecognitionError(_ error: Error) {
        print("Handling recognition error: \(error)")
        
        // Check for specific error types
        if let nsError = error as NSError? {
            print("Error domain: \(nsError.domain), code: \(nsError.code)")
            print("Error description: \(nsError.localizedDescription)")
            
            // Handle specific speech recognition errors - don't show error messages to user
            switch nsError.code {
            case 203: // kSFSpeechRecognitionErrorCodeRequestCancelled
                print("🎤 SpeechRecognitionService: Recognition was cancelled (normal)")
                errorMessage = nil
            case 216: // kSFSpeechRecognitionErrorCodeNoSpeechDetected
                print("🎤 SpeechRecognitionService: No speech detected")
                errorMessage = nil
            case 1100: // kSFSpeechRecognitionErrorCodeAudioReadingFailed
                print("🎤 SpeechRecognitionService: Audio reading failed")
                errorMessage = nil
            default:
                print("🎤 SpeechRecognitionService: Other recognition error: \(nsError.localizedDescription)")
                errorMessage = nil
            }
        } else {
            print("🎤 SpeechRecognitionService: Non-NSError recognition error: \(error.localizedDescription)")
            errorMessage = nil
        }
    }
    
    // MARK: - Public Helpers
    var permissionStatusMessage: String {
        if speechPermissionStatus != .authorized {
            return "需要语音识别权限才能使用语音输入功能"
        }
        if microphonePermissionStatus != .granted {
            return "需要麦克风权限才能录制语音"
        }
        if !isAvailable {
            return "语音识别服务当前不可用"
        }
        return ""
    }
    
    var hasAllPermissions: Bool {
        speechPermissionStatus == .authorized && microphonePermissionStatus == .granted
    }
    
    func refreshPermissionStatus() {
        checkCurrentPermissions()
    }
    
    func clearTranscribedText() {
        transcribedText = ""
    }
    
    func resetService() {
        print("Resetting speech recognition service...")
        
        // Stop any ongoing recording
        stopRecording()
        
        // Clear error message
        errorMessage = nil
        
        // Reset transcribed text
        transcribedText = ""
        
        // Re-check permissions
        checkCurrentPermissions()
        
        // Re-setup speech recognizer
        setupSpeechRecognizer()
        
        print("Speech recognition service reset complete")
    }
}

// MARK: - SFSpeechRecognizerDelegate
extension SpeechRecognitionService: SFSpeechRecognizerDelegate {
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        DispatchQueue.main.async { [weak self] in
            self?.isAvailable = available
            if !available {
                self?.errorMessage = "语音识别服务暂时不可用"
            }
        }
    }
}

// MARK: - Error Types
enum SpeechRecognitionError: Error, LocalizedError {
    case permissionDenied
    case recognizerUnavailable
    case unableToCreateRequest
    case audioEngineError
    case recognitionFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "语音识别权限被拒绝"
        case .recognizerUnavailable:
            return "语音识别服务不可用"
        case .unableToCreateRequest:
            return "无法创建语音识别请求"
        case .audioEngineError:
            return "音频引擎错误"
        case .recognitionFailed(let error):
            return "语音识别失败: \(error.localizedDescription)"
        }
    }
}