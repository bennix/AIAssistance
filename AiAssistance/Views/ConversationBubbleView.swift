//
//  ConversationBubbleView.swift
//  AiAssistance
//
//  Created by Kiro on 2025/8/2.
//

import SwiftUI

struct ConversationBubbleView: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.isFromUser {
                Spacer()
                Text(message.content.isEmpty ? "空消息" : message.content)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    if message.content.isEmpty {
                        Text("正在思考...")
                            .padding()
                    } else {
                        MarkdownText(content: message.content)
                            .padding()
                    }
                }
                .background(Color.gray.opacity(0.2))
                .cornerRadius(12)
                Spacer()
            }
        }
        .padding(.horizontal)
        .onAppear {
            print("🎨 ConversationBubbleView: Displaying message - User: \(message.isFromUser), Content: '\(message.content)', Streaming: \(message.isStreaming)")
        }
    }
}

#Preview {
    VStack {
        ConversationBubbleView(message: ChatMessage(content: "Hello, this is a user message", isFromUser: true))
        ConversationBubbleView(message: ChatMessage(content: "Hello, this is an AI response", isFromUser: false))
    }
}