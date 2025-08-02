# AI语音助手 (AI Voice Assistant)

一个基于SwiftUI开发的iOS语音助手应用，支持语音识别和AI对话功能。

## 功能特性

### 🎤 语音识别
- 实时语音转文字
- 支持中文语音识别
- 智能音频会话管理
- 自动权限请求和管理

### 🤖 AI对话
- 集成GLM API进行智能对话
- 支持流式响应，实时显示AI回复
- Markdown格式渲染支持
- 对话历史管理

### 🎨 用户界面
- 现代化SwiftUI界面设计
- 支持Markdown文本渲染（标题、粗体、列表等）
- 响应式布局适配
- 直观的语音录制按钮

### 🔧 技术特性
- MVVM架构模式
- Combine框架进行响应式编程
- 异步/等待模式处理网络请求
- 完善的错误处理机制

## 系统要求

- iOS 18.5+
- Xcode 16.0+
- Swift 5.0+

## 安装和运行

1. 克隆项目到本地：
```bash
git clone https://github.com/bennix/AIAssistance.git
cd AIAssistance
```

2. 使用Xcode打开项目：
```bash
open AiAssistance.xcodeproj
```

3. 配置API密钥：
   - 在 `APIConfiguration.swift` 中设置你的GLM API密钥
   - 或在应用运行时通过设置界面配置

4. 选择目标设备或模拟器，点击运行按钮

## 项目结构

```
AiAssistance/
├── Models/                 # 数据模型
│   ├── ChatMessage.swift   # 聊天消息模型
│   ├── GLMModels.swift     # GLM API模型
│   └── APIConfiguration.swift # API配置
├── Views/                  # 视图组件
│   ├── VoiceChatView.swift # 主聊天界面
│   ├── ConversationBubbleView.swift # 对话气泡
│   ├── MarkdownText.swift  # Markdown渲染组件
│   └── VoiceRecordingButton.swift # 录音按钮
├── ViewModels/             # 视图模型
│   └── VoiceChatViewModel.swift # 主视图模型
├── Services/               # 服务层
│   ├── SpeechRecognitionService.swift # 语音识别服务
│   ├── GLMAPIService.swift # GLM API服务
│   └── ConversationManager.swift # 对话管理
└── AiAssistanceApp.swift   # 应用入口
```

## 核心功能实现

### 语音识别
- 使用 `Speech` 框架进行语音识别
- 支持实时语音转文字
- 智能处理音频会话和权限

### AI对话
- 集成智谱AI GLM API
- 支持流式响应处理
- 完整的对话上下文管理

### Markdown渲染
- 自定义Markdown解析器
- 支持标题、粗体、列表等格式
- 优化的文本显示效果

## 配置说明

### API Key 配置和申请

#### 如何申请 GLM API Key
1. 访问智谱AI开放平台：https://open.bigmodel.cn/
2. 注册或登录账号。
3. 在控制台中创建应用并生成 API Key。
4. 注意：API Key 格式通常为类似 `xxxxxxxx.xxxxxxxxxxxx` 的字符串。
5. 请妥善保管您的 API Key，不要在代码中硬编码或公开分享。

#### 如何添加 API Key
本应用使用 Keychain 安全存储 API Key。您有两种方式配置：

1. **通过代码设置**（推荐用于开发）：
   - 打开 `Models/APIConfiguration.swift` 文件。
   - 在适当位置调用 `APIConfiguration.shared.setAPIKey("your-api-key-here")`。
   - 注意：不要将实际 Key 提交到 Git 仓库。

2. **运行时配置**（如果应用支持设置界面）：
   - 运行应用后，在设置界面输入您的 API Key。
   - 应用会安全存储在 Keychain 中。

示例代码（在应用初始化时设置，如果需要）：
```swift
struct APIConfiguration {
    static let shared = APIConfiguration()
    
    private let baseURL = "https://open.bigmodel.cn/api/paas/v4/"
    
    // ... 其他配置
}

// 在 AiAssistanceApp.swift 或其他初始化处
APIConfiguration.shared.setAPIKey("your-api-key-here")
```

### 权限配置
应用需要以下权限：
- 麦克风权限：用于语音录制
- 语音识别权限：用于语音转文字

这些权限会在应用首次使用时自动请求。

## 开发指南

### 添加新功能
1. 在相应的文件夹中创建新的Swift文件
2. 遵循MVVM架构模式
3. 使用Combine进行数据绑定
4. 添加适当的错误处理

### 自定义UI
- 所有UI组件都使用SwiftUI构建
- 支持Dark Mode和Light Mode
- 响应式设计适配不同屏幕尺寸

### API集成
- 使用URLSession进行网络请求
- 支持异步/等待模式
- 完整的错误处理和重试机制

## 故障排除

### 常见问题

**语音识别不工作**
- 检查麦克风权限是否已授权
- 确保设备支持语音识别
- 检查网络连接

**AI回复异常**
- 验证API密钥是否正确
- 检查网络连接
- 查看控制台日志获取详细错误信息

**构建失败**
- 确保使用Xcode 16.0+
- 检查iOS部署目标设置
- 清理构建缓存后重新构建

## 贡献指南

欢迎提交Issue和Pull Request来改进这个项目！

1. Fork这个项目
2. 创建你的功能分支 (`git checkout -b feature/AmazingFeature`)
3. 提交你的更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 打开一个Pull Request

## 许可证

本项目采用MIT许可证 - 查看 [LICENSE](LICENSE) 文件了解详情。

## 联系方式

如果你有任何问题或建议，请通过以下方式联系：

- 创建GitHub Issue
- 发送邮件到项目维护者

## 致谢

- 感谢智谱AI提供的GLM API服务
- 感谢Apple提供的Speech框架
- 感谢SwiftUI社区的支持和贡献

---

**注意**: 使用本应用前请确保你有合法的API访问权限，并遵守相关服务条款。