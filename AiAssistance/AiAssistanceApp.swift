//
//  AiAssistanceApp.swift
//  AiAssistance
//
//  Created by Nelle Rtcai on 2025/8/2.
//

import SwiftUI

import AVFoundation

@main
struct AiAssistanceApp: App {
    
    init() {
        // Configure audio session at app launch to avoid conflicts
        configureAudioSession()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
    
    private func configureAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            // Set a basic category that can be changed later
            try audioSession.setCategory(.ambient, mode: .default)
        } catch {
            print("Failed to configure initial audio session: \(error)")
        }
    }
}
