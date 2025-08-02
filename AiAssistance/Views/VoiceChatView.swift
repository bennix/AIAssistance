//
//  VoiceChatView.swift
//  AiAssistance
//
//  Created by Kiro on 2025/8/2.
//

import SwiftUI

struct VoiceChatView: View {
    @StateObject private var viewModel = VoiceChatViewModel()
    @State private var showDebugView = false
    
    var body: some View {
        VStack {
         
            
            // Chat messages
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.messages) { message in
                        ConversationBubbleView(message: message)
                    }
                }
                .padding(.horizontal)
                .onAppear {
                    print("📱 VoiceChatView: Messages count: \(viewModel.messages.count)")
                }
                .onChange(of: viewModel.messages) { _, messages in
                    print("📱 VoiceChatView: Messages updated, count: \(messages.count)")
                    for (index, message) in messages.enumerated() {
                        print("📱 Message \(index): \(message.isFromUser ? "User" : "AI") - '\(message.content)'")
                    }
                }
            }
            
            // Error message display
            if let errorMessage = viewModel.errorMessage {
                VStack(spacing: 8) {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    if errorMessage.contains("取消") || errorMessage.contains("失败") {
                        Button("重置语音服务") {
                            viewModel.resetSpeechService()
                        }
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(6)
                    }
                }
                .padding(.bottom, 8)
            }
            
            // Voice recording button
            VStack {
                if !viewModel.speechService.hasAllPermissions {
                    VStack(spacing: 8) {
                        Text(viewModel.speechService.permissionStatusMessage)
                            .font(.caption)
                            .foregroundColor(.orange)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Button("请求权限") {
                            viewModel.requestPermissions()
                        }
                        .font(.caption)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                }
                
                VoiceRecordingButton(
                    isRecording: viewModel.isRecording,
                    isProcessing: viewModel.isProcessing,
                    hasPermissions: viewModel.speechService.hasAllPermissions,
                    onStartRecording: { viewModel.startRecording() },
                    onStopRecording: { viewModel.stopRecording() }
                )
                
                if viewModel.isRecording {
                    Text("正在录音...")
                        .font(.caption)
                        .foregroundColor(.blue)
                        .padding(.top, 4)
                }
            }
        }
        .padding()
    }
}

#Preview {
    VoiceChatView()
}
