# Getting Started with Foundation Models

## Overview

Foundation Models is Apple's revolutionary AI framework that brings large language model capabilities directly to iOS, macOS, tvOS, and watchOS applications. Introduced at WWDC 2025, it provides a native Swift API for text generation, structured content creation, and AI-powered tool integration.

## System Requirements

- **iOS 19.0+** / **macOS 15.0+** / **tvOS 19.0+** / **watchOS 11.0+**
- **Xcode 17.0+**
- **Swift 6.0+**

## Installation

### 1. Add the Framework

Foundation Models is included in the iOS SDK. Simply import it in your Swift files:

```swift
import FoundationModels
```

### 2. Configure Entitlements

Add the Foundation Models entitlement to your app's entitlements file:

```xml
<key>com.apple.developer.foundation-models</key>
<true/>
```

### 3. Privacy Configuration

Update your `Info.plist` with usage descriptions:

```xml
<key>NSLanguageModelUsageDescription</key>
<string>This app uses AI to provide intelligent responses and content generation.</string>
```

## Your First Foundation Models App

Let's build a simple text summarizer to understand the core concepts:

### 1. Create the Session

```swift
import FoundationModels
import Observation

@MainActor
@Observable
class TextSummarizer {
    let session: LanguageModelSession
    var summaryText: String = ""
    var isProcessing: Bool = false
    
    init() {
        session = LanguageModelSession(
            instructions: """
            You are a text summarizer. Your job is to summarize 
            the provided text in 5 lines or less.
            """
        )
    }
}
```

### 2. Implement Text Processing

```swift
extension TextSummarizer {
    func summarize(text: String) async throws {
        let prompt = "Summarize the following text:\\n\\(text)"
        let stream = session.streamResponse(to: prompt)
        
        isProcessing = true
        summaryText = ""
        
        for try await partial in stream {
            summaryText = partial
        }
        
        isProcessing = false
    }
}
```

### 3. Create the SwiftUI Interface

```swift
import SwiftUI

struct ContentView: View {
    @State private var inputText = ""
    @State private var summarizer = TextSummarizer()
    
    var body: some View {
        VStack(spacing: 20) {
            TextEditor(text: $inputText)
                .frame(height: 200)
                .border(Color.gray, width: 1)
                .disabled(summarizer.isProcessing)
            
            Button(action: {
                Task {
                    try await summarizer.summarize(text: inputText)
                }
            }) {
                HStack {
                    if summarizer.isProcessing {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                    Text(summarizer.isProcessing ? "Summarizing..." : "Summarize")
                }
            }
            .disabled(summarizer.isProcessing || inputText.isEmpty)
            .buttonStyle(.bordered)
            
            if !summarizer.summaryText.isEmpty {
                Text(summarizer.summaryText)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
            }
        }
        .padding()
    }
}
```

## Core Concepts Explained

### LanguageModelSession

The `LanguageModelSession` is the primary interface for interacting with Foundation Models:

```swift
let session = LanguageModelSession(
    instructions: "System instructions for the AI",
    tools: [/* Optional tools */]
)
```

**Key Properties:**
- `instructions`: System-level instructions that guide the AI's behavior
- `tools`: Array of custom tools the AI can use
- `isResponding`: Boolean indicating if the session is currently processing

### Streaming Responses

Foundation Models is designed for real-time experiences. All responses are streamed:

```swift
let stream = session.streamResponse(to: "Your prompt")
for try await partial in stream {
    // Update UI with partial response
    updateUI(with: partial)
}
```

### Error Handling

Always wrap AI operations in proper error handling:

```swift
do {
    let stream = session.streamResponse(to: prompt)
    for try await partial in stream {
        // Process partial response
    }
} catch {
    // Handle specific error types
    handleError(error)
}
```

## Next Steps

Now that you understand the basics, explore these advanced topics:

1. **[Structured Generation](./generable-protocol.md)** - Learn to generate type-safe structured content
2. **[Tools](./tool-protocol.md)** - Extend AI capabilities with custom tools
3. **[SwiftUI Integration](./swiftui-integration.md)** - Build responsive AI-powered interfaces

## Common Patterns

### Session Prewarming

Improve first-response time by prewarming sessions:

```swift
override func viewDidLoad() {
    super.viewDidLoad()
    session.prewarm() // Prepares the model for faster responses
}
```

### Environment Integration

Use SwiftUI's environment system for dependency injection:

```swift
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(TextSummarizer())
        }
    }
}
```

### Memory Management

Foundation Models automatically manages memory, but consider:

```swift
// Release sessions when no longer needed
deinit {
    session.invalidate()
}
```

## Performance Tips

1. **Reuse Sessions**: Create sessions once and reuse them
2. **Prewarm When Possible**: Call `prewarm()` during app initialization
3. **Handle Cancellation**: Support user cancellation of long operations
4. **Batch Operations**: Group related requests when possible

## Debugging

Enable Foundation Models logging for development:

```swift
#if DEBUG
FoundationModels.enableLogging()
#endif
```

## What's Next?

- Explore [structured generation](./generable-protocol.md) for type-safe AI outputs
- Learn about [custom tools](./tool-protocol.md) for extending AI capabilities
- Check out [practical examples](./examples/) for real-world implementations

---

*Ready to build something amazing? Let's dive deeper into the powerful features of Foundation Models!*