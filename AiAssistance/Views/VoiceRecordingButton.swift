//
//  VoiceRecordingButton.swift
//  AiAssistance
//
//  Created by Kiro on 2025/8/2.
//

import SwiftUI

struct VoiceRecordingButton: View {
    let isRecording: Bool
    let isProcessing: Bool
    let hasPermissions: Bool
    let onStartRecording: () -> Void
    let onStopRecording: () -> Void
    
    var body: some View {
        Button(action: {
            if isRecording {
                onStopRecording()
            } else {
                onStartRecording()
            }
        }) {
            ZStack {
                Circle()
                    .fill(buttonColor)
                    .frame(width: 80, height: 80)
                
                if isProcessing {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Image(systemName: buttonIcon)
                        .font(.title)
                        .foregroundColor(.white)
                }
            }
        }
        .disabled(isProcessing || !hasPermissions)
        .opacity(hasPermissions ? 1.0 : 0.5)
        .scaleEffect(isRecording ? 1.1 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isRecording)
    }
    
    private var buttonColor: Color {
        if !hasPermissions {
            return .gray
        }
        return isRecording ? .red : .blue
    }
    
    private var buttonIcon: String {
        if !hasPermissions {
            return "mic.slash.fill"
        }
        return isRecording ? "stop.fill" : "mic.fill"
    }
}

#Preview {
    VStack(spacing: 20) {
        VoiceRecordingButton(
            isRecording: false,
            isProcessing: false,
            hasPermissions: true,
            onStartRecording: {},
            onStopRecording: {}
        )
        
        VoiceRecordingButton(
            isRecording: true,
            isProcessing: false,
            hasPermissions: true,
            onStartRecording: {},
            onStopRecording: {}
        )
        
        VoiceRecordingButton(
            isRecording: false,
            isProcessing: true,
            hasPermissions: true,
            onStartRecording: {},
            onStopRecording: {}
        )
        
        VoiceRecordingButton(
            isRecording: false,
            isProcessing: false,
            hasPermissions: false,
            onStartRecording: {},
            onStopRecording: {}
        )
    }
}