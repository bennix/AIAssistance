//
//  PermissionDebugView.swift
//  AiAssistance
//
//  Created by Kiro on 2025/8/2.
//

import SwiftUI
import Speech
import AVFoundation

struct PermissionDebugView: View {
    @ObservedObject var speechService: SpeechRecognitionService
    
    var body: some View {
        VStack(spacing: 16) {
            
            
            VStack(alignment: .leading, spacing: 8) {
                Text("语音识别权限状态:")
                    .fontWeight(.semibold)
                Text("状态: \(speechPermissionStatusString)")
                    .foregroundColor(speechPermissionColor)
                
                Text("麦克风权限状态:")
                    .fontWeight(.semibold)
                Text("状态: \(microphonePermissionStatusString)")
                    .foregroundColor(microphonePermissionColor)
                
                Text("语音识别可用性:")
                    .fontWeight(.semibold)
                Text("可用: \(speechService.isAvailable ? "是" : "否")")
                    .foregroundColor(speechService.isAvailable ? .green : .red)
                
                Text("综合权限状态:")
                    .fontWeight(.semibold)
                Text("所有权限: \(speechService.hasAllPermissions ? "已授予" : "未授予")")
                    .foregroundColor(speechService.hasAllPermissions ? .green : .red)
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
            
            Button("刷新权限状态") {
                speechService.refreshPermissionStatus()
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
            
            Button("请求权限") {
                Task {
                    await speechService.requestPermissions()
                }
            }
            .padding()
            .background(Color.green)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
        .padding()
    }
    
    private var speechPermissionStatusString: String {
        switch speechService.speechPermissionStatus {
        case .notDetermined:
            return "未确定"
        case .denied:
            return "已拒绝"
        case .restricted:
            return "受限制"
        case .authorized:
            return "已授权"
        @unknown default:
            return "未知"
        }
    }
    
    private var speechPermissionColor: Color {
        switch speechService.speechPermissionStatus {
        case .authorized:
            return .green
        case .denied, .restricted:
            return .red
        case .notDetermined:
            return .orange
        @unknown default:
            return .gray
        }
    }
    
    private var microphonePermissionStatusString: String {
        switch speechService.microphonePermissionStatus {
        case .undetermined:
            return "未确定"
        case .denied:
            return "已拒绝"
        case .granted:
            return "已授权"
        @unknown default:
            return "未知"
        }
    }
    
    private var microphonePermissionColor: Color {
        switch speechService.microphonePermissionStatus {
        case .granted:
            return .green
        case .denied:
            return .red
        case .undetermined:
            return .orange
        @unknown default:
            return .gray
        }
    }
}

#Preview {
    PermissionDebugView(speechService: SpeechRecognitionService())
}
