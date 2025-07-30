# Foundation Models API Documentation

## 🚀 Complete Guide to Apple's Foundation Models API

Welcome to the most comprehensive documentation for Apple's Foundation Models API, introduced at WWDC 2025. This guide provides everything you need to build AI-powered iOS applications with Apple's cutting-edge language model capabilities.

## 📖 Table of Contents

### Core Framework
- [**Getting Started**](./getting-started.md) - Quick setup and first steps
- [**LanguageModelSession**](./language-model-session.md) - Core session management and configuration
- [**Streaming Responses**](./streaming-responses.md) - Real-time text generation patterns

### Structured Generation
- [**@Generable Protocol**](./generable-protocol.md) - Creating structured AI outputs
- [**@Guide Attributes**](./guide-attributes.md) - Controlling generation behavior
- [**PartiallyGenerated Types**](./partially-generated-types.md) - Working with streaming structured data

### Tools & Extensions
- [**Tool Protocol**](./tool-protocol.md) - Extending AI capabilities with custom tools
- [**Tool Implementation Guide**](./tool-implementation.md) - Building powerful AI tools
- [**Tool Integration Patterns**](./tool-integration-patterns.md) - Best practices for tool usage

### SwiftUI Integration
- [**SwiftUI Patterns**](./swiftui-integration.md) - UI integration with Foundation Models
- [**Observable State Management**](./observable-state.md) - Managing AI state in SwiftUI
- [**UI Performance Optimization**](./ui-performance.md) - Best practices for responsive UIs

### Advanced Topics
- [**Error Handling**](./error-handling.md) - Robust error management strategies
- [**Session Management**](./session-management.md) - Lifecycle and performance optimization
- [**Testing Strategies**](./testing.md) - Testing AI-powered applications

### Practical Examples
- [**Text Summarization**](./examples/text-summarization.md) - Building a summarizer like HelloWorld
- [**Content Generation**](./examples/content-generation.md) - Creating exams, jokes, and recipes
- [**Travel Planning**](./examples/travel-planning.md) - Complex AI-powered planning applications
- [**Recipe Recommendations**](./examples/recipe-recommendations.md) - Multi-modal AI applications

### Reference
- [**API Reference**](./api-reference.md) - Complete API documentation
- [**Common Patterns**](./common-patterns.md) - Reusable code patterns and best practices
- [**Migration Guide**](./migration-guide.md) - Upgrading from beta versions
- [**Troubleshooting**](./troubleshooting.md) - Common issues and solutions

## 🌟 Key Features

- **Native Swift Integration** - First-class Swift API with async/await support
- **Structured Generation** - Type-safe AI outputs with compile-time validation  
- **Real-time Streaming** - Responsive UIs with live content generation
- **Extensible Tools** - Custom AI capabilities through the Tool protocol
- **SwiftUI Ready** - Built for modern iOS development patterns
- **Privacy-First** - On-device processing with optional cloud fallback

## 🎯 What Makes This API Special

Apple's Foundation Models API represents a paradigm shift in mobile AI development:

1. **Type Safety**: Unlike traditional text-based APIs, Foundation Models provides compile-time validation for AI-generated content
2. **Streaming Architecture**: Built from the ground up for real-time, responsive user experiences
3. **Declarative Syntax**: Uses Swift's powerful type system and attributes for intuitive AI configuration
4. **Tool Ecosystem**: Extensible architecture allowing custom AI capabilities
5. **Privacy-Focused**: Designed with Apple's privacy principles at its core

## 🚀 Quick Start

```swift
import FoundationModels

// Create a language model session
let session = LanguageModelSession(
    instructions: "You are a helpful assistant"
)

// Generate streaming text
let stream = session.streamResponse(to: "Write a haiku about Swift")
for try await partial in stream {
    print(partial)
}
```

## 📱 Example Applications

This documentation is based on real-world examples from Apple's sample projects:

- **HelloWorld** - Text summarization with streaming updates
- **SwiftExams** - Structured exam generation and grading
- **Travel** - AI-powered itinerary planning with external tools
- **Yummy** - Recipe recommendations with API integration
- **Jokes** - Simple content generation with tool usage

## 🤝 Contributing

Found an error or want to improve the documentation? This guide is continuously updated based on the latest API developments and community feedback.

## ⚡ Performance Tips

- Use `session.prewarm()` for faster initial responses
- Implement proper error handling for production apps
- Leverage `@Observable` for efficient SwiftUI updates
- Use structured generation for type-safe outputs

## 🔒 Privacy & Security

Foundation Models is designed with privacy at its core:
- On-device processing by default
- No data collection without explicit consent
- Full control over external API calls
- Transparent tool usage logging

---

*Last updated: Based on WWDC 2025 samples and API documentation*