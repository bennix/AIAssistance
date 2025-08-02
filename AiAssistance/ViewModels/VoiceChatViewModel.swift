//
//  VoiceChatViewModel.swift
//  AiAssistance
//
//  Created by Kiro on 2025/8/2.
//

import Foundation
import Combine

@MainActor
class VoiceChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var isRecording: Bool = false
    @Published var isProcessing: Bool = false
    @Published var currentStreamingResponse: String = ""
    @Published var errorMessage: String?
    
    // Dependencies
    let speechService: SpeechRecognitionService
    private let apiService: GLMAPIService
    private let conversationManager: ConversationManager
    
    init(speechService: SpeechRecognitionService = SpeechRecognitionService(),
         apiService: GLMAPIService = GLMAPIService(),
         conversationManager: ConversationManager = ConversationManager()) {
        self.speechService = speechService
        self.apiService = apiService
        self.conversationManager = conversationManager
        
        // Setup API configuration
        APIConfiguration.shared.setupDefaultAPIKey()
        
        // Bind conversation manager messages - use publisher to keep in sync
        self.messages = conversationManager.messages
        
        // Monitor conversation manager changes
        conversationManager.$messages
            .receive(on: DispatchQueue.main)
            .assign(to: &$messages)
        
        // Monitor speech service state
        setupSpeechServiceObservers()
    }
    
    private func setupSpeechServiceObservers() {
        // Monitor recording state
        speechService.$isRecording
            .receive(on: DispatchQueue.main)
            .assign(to: &$isRecording)
        
        // Monitor speech service errors
        speechService.$errorMessage
            .receive(on: DispatchQueue.main)
            .compactMap { $0 }
            .assign(to: &$errorMessage)
        
        // Monitor transcribed text changes directly
        speechService.$transcribedText
            .receive(on: DispatchQueue.main)
            .sink { [weak self] transcribedText in
                print("🎤 VoiceChatViewModel: Transcribed text changed to: '\(transcribedText)'")
                // Only process if we have text and recording has stopped
                if !transcribedText.isEmpty && !(self?.speechService.isRecording ?? true) {
                    print("🎤 VoiceChatViewModel: Processing transcribed text immediately")
                    self?.processTranscribedText()
                }
            }
            .store(in: &cancellables)
        
        // Monitor when recording stops to process transcribed text (backup)
        speechService.$isRecording
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isRecording in
                print("🎤 VoiceChatViewModel: Recording state changed to: \(isRecording)")
                // If recording stopped, process transcribed text
                if !isRecording {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        print("🎤 VoiceChatViewModel: Processing transcribed text after recording stopped")
                        self?.processTranscribedText()
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    private func processTranscribedText() {
        let transcribedText = speechService.transcribedText.trimmingCharacters(in: .whitespacesAndNewlines)
        print("🎤 VoiceChatViewModel: Processing transcribed text: '\(transcribedText)'")
        print("🎤 VoiceChatViewModel: Original text: '\(speechService.transcribedText)'")
        print("🎤 VoiceChatViewModel: Text length: \(transcribedText.count)")
        
        if !transcribedText.isEmpty {
            print("✅ VoiceChatViewModel: Sending message with transcribed text")
            sendMessage(transcribedText)
            // Clear the transcribed text after processing
            speechService.clearTranscribedText()
        } else {
            print("⚠️ VoiceChatViewModel: Transcribed text is empty after trimming")
        }
    }
    
    func requestPermissions() {
        Task {
            await speechService.requestPermissions()
            // Refresh permission status after request
            await MainActor.run {
                speechService.refreshPermissionStatus()
            }
        }
    }
    
    func startRecording() {
        guard !isRecording && !isProcessing else { return }
        
        // If permissions are not granted, request them first
        if !speechService.hasAllPermissions {
            requestPermissions()
            return
        }
        
        Task {
            do {
                try await speechService.startRecording()
                errorMessage = nil
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isRecording = false
                }
            }
        }
    }
    
    func stopRecording() {
        guard isRecording else { return }
        
        speechService.stopRecording()
        // Note: processTranscribedText() will be called automatically 
        // when isRecording changes to false in the observer
    }
    
    func sendMessage(_ text: String) {
        print("🎯 VoiceChatViewModel: sendMessage called with text: '\(text)'")
        guard !text.isEmpty else { 
            print("⚠️ VoiceChatViewModel: Empty text, returning")
            return 
        }
        
        // Add user message
        let userMessage = ChatMessage.userMessage(text)
        conversationManager.addMessage(userMessage)
        messages = conversationManager.messages
        print("✅ VoiceChatViewModel: User message added, total messages: \(messages.count)")
        
        // Send to API service
        isProcessing = true
        currentStreamingResponse = ""
        errorMessage = nil
        print("🔄 VoiceChatViewModel: Starting API processing...")
        
        Task {
            do {
                // Set API key from configuration
                let apiKey = APIConfiguration.shared.getAPIKey() ?? ""
                print("🔑 VoiceChatViewModel: API key length: \(apiKey.count)")
                apiService.setAPIKey(apiKey)
                
                // Convert messages for API
                let glmMessages = apiService.convertMessages(conversationManager.messages)
                print("📝 VoiceChatViewModel: Converted \(glmMessages.count) messages for API")
                
                // Create streaming AI message
                let aiMessage = ChatMessage.aiMessage("", isStreaming: true)
                await MainActor.run {
                    conversationManager.addMessage(aiMessage)
                    messages = conversationManager.messages
                    print("🤖 VoiceChatViewModel: AI message placeholder added")
                }
                
                // Start streaming response
                print("🚀 VoiceChatViewModel: Starting streaming request...")
                let stream = try await apiService.sendStreamingRequest(messages: glmMessages)
                var fullResponse = ""
                var chunkCount = 0
                
                for try await chunk in stream {
                    chunkCount += 1
                    fullResponse += chunk
                    print("📦 VoiceChatViewModel: Received chunk \(chunkCount): '\(chunk)'")
                    print("📄 VoiceChatViewModel: Full response so far: '\(fullResponse)'")
                    
                    await MainActor.run {
                        currentStreamingResponse = fullResponse
                        // Update the last message (AI response) with streaming content
                        if let lastIndex = conversationManager.messages.lastIndex(where: { !$0.isFromUser }) {
                            conversationManager.updateMessage(at: lastIndex, content: fullResponse)
                            messages = conversationManager.messages
                            print("🔄 VoiceChatViewModel: Updated AI message at index \(lastIndex)")
                        }
                    }
                }
                
                // Finish streaming
                await MainActor.run {
                    if let lastIndex = conversationManager.messages.lastIndex(where: { !$0.isFromUser }) {
                        let finalMessage = conversationManager.messages[lastIndex].finishStreaming()
                        conversationManager.updateMessage(at: lastIndex, message: finalMessage)
                        messages = conversationManager.messages
                        print("✅ VoiceChatViewModel: Finalized AI message with \(chunkCount) chunks")
                    }
                    isProcessing = false
                    currentStreamingResponse = ""
                    print("🏁 VoiceChatViewModel: Processing completed successfully")
                }
                
            } catch {
                print("❌ VoiceChatViewModel: Error occurred: \(error)")
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isProcessing = false
                    currentStreamingResponse = ""
                    
                    // Remove the empty AI message if API call failed
                    if let lastMessage = conversationManager.messages.last, 
                       !lastMessage.isFromUser && lastMessage.content.isEmpty {
                        conversationManager.removeLastMessage()
                        messages = conversationManager.messages
                        print("🗑️ VoiceChatViewModel: Removed empty AI message due to error")
                    }
                }
            }
        }
    }
    
    func clearConversation() {
        conversationManager.clearMessages()
        messages = conversationManager.messages
    }
    
    func resetSpeechService() {
        speechService.resetService()
        errorMessage = nil
    }
}