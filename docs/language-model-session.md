# LanguageModelSession

## Overview

`LanguageModelSession` is the core class for interacting with Foundation Models. It manages the AI model lifecycle, handles configuration, and provides interfaces for both simple text generation and structured content creation.

## Creating Sessions

### Basic Session

```swift
import FoundationModels

let session = LanguageModelSession(
    instructions: "You are a helpful assistant."
)
```

### Session with Instructions Closure

For complex or dynamic instructions:

```swift
let session = LanguageModelSession {
    "You are a professional content writer."
    "Always maintain a friendly and informative tone."
    "Provide clear, actionable advice."
}
```

### Session with Tools

Extend AI capabilities with custom tools:

```swift
let weatherTool = WeatherTool()
let calculatorTool = CalculatorTool()

let session = LanguageModelSession(
    tools: [weatherTool, calculatorTool]
) {
    "You are a helpful assistant with access to weather and calculation tools."
    "Use the tools when appropriate to provide accurate information."
}
```

### Session with Sample Data

Provide examples to guide generation:

```swift
let session = LanguageModelSession {
    "You are responsible for creating exams."
    "Here is an example of a sample exam:"
    Exam.sampleExam // Any InstructionsRepresentable type
}
```

## Session Configuration

### Instructions

Instructions define the AI's behavior and persona:

```swift
// Simple string instructions
let session = LanguageModelSession(
    instructions: "You are a text summarizer. Keep responses under 100 words."
)

// Multi-line instructions
let session = LanguageModelSession(
    instructions: """
    You are a travel assistant. Your responsibilities:
    - Create detailed itineraries
    - Suggest local attractions
    - Provide practical travel tips
    - Maintain an enthusiastic tone
    """
)
```

### Dynamic Instructions

Use closures for context-dependent instructions:

```swift
let session = LanguageModelSession { [weak self] in
    "You are a recipe assistant for \(self?.userName ?? "the user")."
    "Consider their dietary preferences: \(self?.dietaryPreferences ?? [])"
    "Always suggest healthy alternatives when possible."
}
```

## Response Generation

### Simple Text Generation

Generate unstructured text responses:

```swift
let stream = session.streamResponse(to: "Write a haiku about programming")

for try await partial in stream {
    print(partial) // Prints progressively complete text
}
```

### Structured Generation

Generate type-safe structured content:

```swift
let stream = session.streamResponse(
    to: "Create a programming exam", 
    generating: Exam.self
)

for try await partial in stream {
    // partial is of type Exam.PartiallyGenerated
    updateUI(with: partial)
}
```

### Collection Generation

Generate arrays of structured content:

```swift
let stream = session.streamResponse(
    to: "Suggest 5 recipes", 
    generating: [Recipe].self
)

for try await recipes in stream {
    // recipes is of type [Recipe.PartiallyGenerated]
    displayRecipes(recipes)
}
```

## Session State Management

### Monitoring Session State

```swift
class AIManager: ObservableObject {
    let session: LanguageModelSession
    
    var isResponding: Bool {
        session.isResponding
    }
    
    init() {
        session = LanguageModelSession(instructions: "...")
    }
}
```

### Session Lifecycle

```swift
class ContentGenerator {
    private let session: LanguageModelSession
    
    init() {
        session = LanguageModelSession(instructions: "...")
        
        // Prewarm for better performance
        session.prewarm()
    }
    
    deinit {
        // Clean up resources
        session.invalidate()
    }
}
```

## Advanced Configuration

### Tool Integration

```swift
class TravelPlanner {
    private let session: LanguageModelSession
    
    init(park: Park) {
        let pointsOfInterestTool = FindNearbyPointsOfInterestTool(park: park)
        
        session = LanguageModelSession(tools: [pointsOfInterestTool]) {
            "You are a helpful travel assistant."
            """
            Use the findNearbyPointsOfInterest tool to find businesses 
            and activities near \(park.name).
            """
            "Here is a description for \(park.name):"
            park.description
            "Here is an example itinerary:"
            Itinerary.exampleTripToNationalPark
        }
    }
}
```

### Conditional Tool Usage

```swift
let session = LanguageModelSession(tools: [recipeTool]) {
    """
    You are a helpful recipe assistant.
    When ingredients include rice, use recipeTool to fetch rice recipes.
    For other ingredients, generate recipes yourself.
    """
    
    "Examples of rice ingredients:"
    [Ingredient(name: "Rice")]
    [Ingredient(name: "Rice"), Ingredient(name: "Chicken")]
}
```

## Error Handling

### Common Error Types

```swift
enum FoundationModelsError: Error {
    case sessionNotReady
    case invalidPrompt
    case generationFailed
    case toolExecutionFailed
    case networkUnavailable
}
```

### Robust Error Handling

```swift
func generateContent() async {
    do {
        let stream = session.streamResponse(to: prompt)
        for try await partial in stream {
            handlePartialResponse(partial)
        }
    } catch FoundationModelsError.sessionNotReady {
        // Session needs initialization
        await initializeSession()
    } catch FoundationModelsError.networkUnavailable {
        // Handle offline mode
        showOfflineMessage()
    } catch {
        // Handle unexpected errors
        showGenericError(error)
    }
}
```

## Performance Optimization

### Session Prewarming

```swift
class AppDelegate: UIApplicationDelegate {
    func application(_ application: UIApplication, 
                    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Prewarm sessions during app launch
        Task {
            await preloadAISessions()
        }
        
        return true
    }
    
    private func preloadAISessions() async {
        let commonSessions = [
            summarizer.session,
            recipeRecommender.session,
            examGenerator.session
        ]
        
        await withTaskGroup(of: Void.self) { group in
            for session in commonSessions {
                group.addTask {
                    session.prewarm()
                }
            }
        }
    }
}
```

### Session Reuse

```swift
// ✅ Good: Reuse sessions
class ContentManager {
    private let session = LanguageModelSession(instructions: "...")
    
    func generateSummary(_ text: String) async throws -> String {
        // Reuse the same session
        let stream = session.streamResponse(to: "Summarize: \(text)")
        // ...
    }
}

// ❌ Bad: Creating new sessions
class ContentManager {
    func generateSummary(_ text: String) async throws -> String {
        // Creates a new session each time - expensive!
        let session = LanguageModelSession(instructions: "...")
        // ...
    }
}
```

## Best Practices

### 1. Clear Instructions

```swift
// ✅ Good: Specific and clear
let session = LanguageModelSession(
    instructions: """
    You are a Swift programming tutor.
    - Explain concepts clearly for beginners
    - Provide practical code examples
    - Use encouraging and supportive language
    - Focus on iOS development best practices
    """
)

// ❌ Bad: Vague and unclear
let session = LanguageModelSession(
    instructions: "Help with programming"
)
```

### 2. Proper Resource Management

```swift
@MainActor
@Observable
class AIService {
    private let session: LanguageModelSession
    
    init() {
        session = LanguageModelSession(instructions: "...")
        session.prewarm() // Prepare for faster responses
    }
    
    deinit {
        session.invalidate() // Clean up resources
    }
}
```

### 3. Environment-Aware Configuration

```swift
struct SessionFactory {
    static func createSummarizer() -> LanguageModelSession {
        #if DEBUG
        return LanguageModelSession(
            instructions: "You are a text summarizer. [DEBUG MODE]"
        )
        #else
        return LanguageModelSession(
            instructions: "You are a text summarizer."
        )
        #endif
    }
}
```

## Common Patterns

### Singleton Session Manager

```swift
class SessionManager {
    static let shared = SessionManager()
    
    private(set) lazy var summarizerSession = LanguageModelSession(
        instructions: "You are a text summarizer."
    )
    
    private(set) lazy var codeGeneratorSession = LanguageModelSession(
        instructions: "You are a Swift code generator."
    )
    
    private init() {}
    
    func preloadSessions() {
        summarizerSession.prewarm()
        codeGeneratorSession.prewarm()
    }
}
```

### Protocol-Based Session Configuration

```swift
protocol SessionConfigurable {
    var instructions: String { get }
    var tools: [Tool] { get }
}

extension SessionConfigurable {
    func createSession() -> LanguageModelSession {
        return LanguageModelSession(tools: tools) {
            instructions
        }
    }
}

struct ExamGeneratorConfig: SessionConfigurable {
    let instructions = "You are responsible for creating exams."
    let tools: [Tool] = []
}
```

## Migration from Beta

If upgrading from beta versions:

```swift
// Old API (Beta)
let session = LanguageModelSession.create(
    withInstructions: "...",
    andTools: [...]
)

// New API (Release)
let session = LanguageModelSession(tools: [...]) {
    "..."
}
```

## Next Steps

- Learn about [structured generation](./generable-protocol.md) with `@Generable`
- Explore [custom tools](./tool-protocol.md) for extending capabilities
- Check out [SwiftUI integration](./swiftui-integration.md) patterns

---

*Master LanguageModelSession to unlock the full potential of Foundation Models in your apps!*