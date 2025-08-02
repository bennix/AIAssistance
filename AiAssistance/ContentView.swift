//
//  ContentView.swift
//  AiAssistance
//
//  Created by Nelle Rtcai on 2025/8/2.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView {
            VoiceChatView()
                .navigationTitle("AI语音助手")
                .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    ContentView()
}
