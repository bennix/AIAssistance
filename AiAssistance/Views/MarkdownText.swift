//
//  MarkdownText.swift
//  AiAssistance
//
//  Created by Kiro on 2025/8/2.
//

import SwiftUI

struct MarkdownText: View {
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            let lines = content.components(separatedBy: .newlines)
            ForEach(Array(lines.enumerated()), id: \.offset) { index, line in
                renderLine(line.trimmingCharacters(in: .whitespaces))
            }
        }
    }
    
    @ViewBuilder
    private func renderLine(_ line: String) -> some View {
        if line.isEmpty {
            // Empty line for spacing
            Text(" ")
                .font(.caption)
        } else if line.hasPrefix("# ") {
            // H1 heading
            HStack {
                Text(String(line.dropFirst(2)))
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Spacer()
            }
            .padding(.vertical, 4)
        } else if line.hasPrefix("## ") {
            // H2 heading
            HStack {
                Text(String(line.dropFirst(3)))
                    .font(.title)
                    .fontWeight(.bold)
                Spacer()
            }
            .padding(.vertical, 3)
        } else if line.hasPrefix("### ") {
            // H3 heading
            HStack {
                Text(String(line.dropFirst(4)))
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
            }
            .padding(.vertical, 2)
        } else if line.hasPrefix("```") {
            // Code block marker - skip for now
            EmptyView()
        } else if line == "---" || line.hasPrefix("---") {
            // Horizontal rule - skip to avoid gray line
            EmptyView()
        } else if line.hasPrefix("- ") || line.hasPrefix("* ") {
            // Unordered list item
            HStack(alignment: .top, spacing: 8) {
                Text("•")
                    .fontWeight(.bold)
                renderInlineText(String(line.dropFirst(2)))
                Spacer()
            }
        } else if line.range(of: #"^\d+\. "#, options: .regularExpression) != nil {
            // Ordered list item
            if let match = line.range(of: #"^\d+\. "#, options: .regularExpression) {
                let number = String(line[match])
                let content = String(line[match.upperBound...])
                HStack(alignment: .top, spacing: 8) {
                    Text(number)
                        .fontWeight(.bold)
                    renderInlineText(content)
                    Spacer()
                }
            }
        } else {
            // Regular paragraph
            HStack {
                renderInlineText(line)
                Spacer()
            }
        }
    }
    
    @ViewBuilder
    private func renderInlineText(_ text: String) -> some View {
        Text(parseInlineMarkdown(text))
    }
    
    private func parseInlineMarkdown(_ text: String) -> AttributedString {
        // For now, just return plain text with basic formatting
        // This is a simplified version to avoid complex AttributedString manipulation
        var result = AttributedString(text)
        
        // Simple bold text replacement
        let boldPattern = #"\*\*(.*?)\*\*"#
        if let regex = try? NSRegularExpression(pattern: boldPattern) {
            let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
            var processedText = text
            
            // Process matches in reverse order to maintain indices
            for match in matches.reversed() {
                if let range = Range(match.range, in: text),
                   let contentRange = Range(match.range(at: 1), in: text) {
                    let boldContent = String(text[contentRange])
                    processedText.replaceSubrange(range, with: boldContent)
                }
            }
            
            result = AttributedString(processedText)
            // Apply bold formatting to the entire result for simplicity
            if matches.count > 0 {
                result.font = .body.bold()
            }
        }
        
        return result
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 16) {
        MarkdownText(content: """
        # 标题 1
        
        这是一个**粗体**文本和*斜体*文本的示例。
        
        ## 代码示例
        
        这是内联代码：`print("Hello, World!")`
        
        ```swift
        func greet() {
            print("Hello, World!")
        }
        ```
        
        ## 列表示例
        
        - 项目 1
        - 项目 2
        - 项目 3
        
        1. 有序项目 1
        2. 有序项目 2
        3. 有序项目 3
        """)
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    .padding()
}