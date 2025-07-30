# SwiftUI Integration

## Overview

Foundation Models is designed from the ground up for SwiftUI, providing seamless integration with `@Observable`, reactive UI updates, and modern iOS development patterns. This guide covers everything you need to build responsive AI-powered interfaces.

## Basic Integration Patterns

### Observable AI Services

```swift
import FoundationModels
import Observation

@MainActor
@Observable
class ContentGenerator {
    private let session: LanguageModelSession
    private(set) var generatedText: String = ""
    private(set) var isGenerating: Bool = false
    
    init() {
        session = LanguageModelSession(
            instructions: "You are a helpful content generator"
        )
        session.prewarm() // Improve first-response time
    }
    
    func generateContent(prompt: String) async throws {
        isGenerating = true
        generatedText = ""
        
        let stream = session.streamResponse(to: prompt)
        for try await partial in stream {
            generatedText = partial
        }
        
        isGenerating = false
    }
}
```

### Basic SwiftUI View

```swift
struct ContentGeneratorView: View {
    @State private var generator = ContentGenerator()
    @State private var prompt = ""
    
    var body: some View {
        VStack(spacing: 20) {
            TextField("Enter your prompt", text: $prompt)
                .textFieldStyle(.roundedBorder)
                .disabled(generator.isGenerating)
            
            Button("Generate") {
                Task {
                    try await generator.generateContent(prompt: prompt)
                }
            }
            .disabled(generator.isGenerating || prompt.isEmpty)
            .buttonStyle(.bordered)
            
            if generator.isGenerating {
                ProgressView("Generating...")
            }
            
            if !generator.generatedText.isEmpty {
                ScrollView {
                    Text(generator.generatedText)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                }
            }
        }
        .padding()
    }
}
```

## Structured Content with SwiftUI

### Displaying Partial Generation

```swift
@MainActor
@Observable
class RecipeGenerator {
    private let session: LanguageModelSession
    private(set) var currentRecipe: Recipe.PartiallyGenerated?
    
    init() {
        session = LanguageModelSession(
            instructions: "You are a professional chef creating detailed recipes"
        )
    }
    
    func createRecipe(for ingredients: [String]) async throws {
        let prompt = "Create a recipe using: \(ingredients.joined(separator: ", "))"
        let stream = session.streamResponse(to: prompt, generating: Recipe.self)
        
        currentRecipe = nil
        for try await partial in stream {
            currentRecipe = partial
        }
    }
}

struct RecipeView: View {
    @State private var generator = RecipeGenerator()
    @State private var ingredients = ["chicken", "rice", "vegetables"]
    
    var body: some View {
        NavigationView {
            VStack {
                // Input section
                VStack(alignment: .leading) {
                    Text("Ingredients")
                        .font(.headline)
                    
                    ForEach(ingredients.indices, id: \.self) { index in
                        TextField("Ingredient", text: $ingredients[index])
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    Button("Generate Recipe") {
                        Task {
                            try await generator.createRecipe(for: ingredients)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(generator.session.isResponding)
                }
                .padding()
                
                Divider()
                
                // Recipe display
                if let recipe = generator.currentRecipe {
                    RecipeContentView(recipe: recipe)
                } else if generator.session.isResponding {
                    ProgressView("Creating your recipe...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    Text("Enter ingredients and tap Generate Recipe")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle("AI Recipe Generator")
        }
    }
}

struct RecipeContentView: View {
    let recipe: Recipe.PartiallyGenerated
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Recipe name with loading state
                Group {
                    if let name = recipe.name {
                        Text(name)
                            .font(.title2)
                            .fontWeight(.bold)
                    } else {
                        Text("Generating recipe name...")
                            .font(.title2)
                            .fontWeight(.bold)
                            .redacted(reason: .placeholder)
                    }
                }
                
                // Recipe description with loading state
                Group {
                    if let description = recipe.description {
                        Text(description)
                            .font(.body)
                    } else {
                        Text("Generating description...")
                            .font(.body)
                            .redacted(reason: .placeholder)
                    }
                }
                
                // Instructions with partial loading
                if let instructions = recipe.instructions {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Instructions")
                            .font(.headline)
                        
                        ForEach(instructions.indices, id: \.self) { index in
                            if let instruction = instructions[index].text {
                                HStack(alignment: .top) {
                                    Text("\(index + 1).")
                                        .fontWeight(.medium)
                                    Text(instruction)
                                }
                            } else {
                                HStack(alignment: .top) {
                                    Text("\(index + 1).")
                                        .fontWeight(.medium)
                                    Text("Generating step...")
                                        .redacted(reason: .placeholder)
                                }
                            }
                        }
                    }
                }
            }
            .padding()
        }
    }
}
```

## Environment-Based Architecture

### Service Injection

```swift
// App.swift
@main
struct RecipeApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(RecipeGenerator())
                .environment(NutritionAnalyzer())
                .environment(ShoppingListManager())
        }
    }
}

// Using in views
struct RecipeListView: View {
    @Environment(RecipeGenerator.self) private var generator
    @Environment(NutritionAnalyzer.self) private var nutritionAnalyzer
    
    var body: some View {
        // Use injected services
    }
}
```

### Custom Environment Values

```swift
import SwiftUI

extension EnvironmentValues {
    @Entry var aiConfiguration = AIConfiguration.default
}

struct AIConfiguration {
    let modelPreference: ModelPreference
    let streamingEnabled: Bool
    let debugMode: Bool
    
    static let `default` = AIConfiguration(
        modelPreference: .balanced,
        streamingEnabled: true,
        debugMode: false
    )
}

enum ModelPreference {
    case speed
    case balanced
    case quality
}

// Usage in views
struct AISettingsView: View {
    @Environment(\.aiConfiguration) private var config
    
    var body: some View {
        Form {
            Section("AI Preferences") {
                Picker("Model Preference", selection: .constant(config.modelPreference)) {
                    Text("Speed").tag(ModelPreference.speed)
                    Text("Balanced").tag(ModelPreference.balanced)
                    Text("Quality").tag(ModelPreference.quality)
                }
                
                Toggle("Enable Streaming", isOn: .constant(config.streamingEnabled))
            }
        }
    }
}
```

## Advanced UI Patterns

### Streaming Text with Animation

```swift
struct StreamingTextView: View {
    let text: String
    @State private var displayedText = ""
    @State private var currentIndex = 0
    
    var body: some View {
        Text(displayedText)
            .animation(.easeInOut(duration: 0.1), value: displayedText)
            .onChange(of: text) { _, newText in
                updateDisplayedText(newText)
            }
    }
    
    private func updateDisplayedText(_ newText: String) {
        let newLength = newText.count
        
        if newLength > displayedText.count {
            // Text is growing - animate character by character
            let startIndex = newText.index(newText.startIndex, offsetBy: displayedText.count)
            let additionalText = String(newText[startIndex...])
            
            animateTextAddition(additionalText)
        } else {
            // Text was replaced - update immediately
            displayedText = newText
        }
    }
    
    private func animateTextAddition(_ additionalText: String) {
        guard !additionalText.isEmpty else { return }
        
        let characters = Array(additionalText)
        var characterIndex = 0
        
        Timer.scheduledTimer(withTimeInterval: 0.03, repeats: true) { timer in
            if characterIndex < characters.count {
                displayedText.append(characters[characterIndex])
                characterIndex += 1
            } else {
                timer.invalidate()
            }
        }
    }
}
```

### Loading States and Placeholders

```swift
struct ExamQuestionView: View {
    let question: Question.PartiallyGenerated
    let isLoading: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Question text
            Group {
                if let text = question.text {
                    Text(text)
                        .font(.headline)
                } else {
                    Text("Loading question...")
                        .font(.headline)
                        .redacted(reason: .placeholder)
                }
            }
            
            // Choices
            if let choices = question.choices {
                ForEach(choices) { choice in
                    ChoiceRowView(choice: choice, isLoading: isLoading)
                }
            } else {
                ForEach(0..<4, id: \.self) { _ in
                    PlaceholderChoiceView()
                }
            }
        }
    }
}

struct ChoiceRowView: View {
    let choice: Choice.PartiallyGenerated
    let isLoading: Bool
    
    var body: some View {
        HStack {
            Image(systemName: "circle")
                .foregroundColor(.blue)
                .opacity(isLoading ? 0.5 : 1.0)
            
            if let text = choice.text {
                Text(text)
                    .opacity(isLoading ? 0.7 : 1.0)
            } else {
                Text("Loading choice...")
                    .redacted(reason: .placeholder)
            }
            
            Spacer()
        }
        .animation(.easeInOut(duration: 0.3), value: choice.text)
    }
}

struct PlaceholderChoiceView: View {
    var body: some View {
        HStack {
            Image(systemName: "circle")
                .foregroundColor(.gray)
            
            Text("Loading choice...")
                .redacted(reason: .placeholder)
            
            Spacer()
        }
    }
}
```

### Error Handling UI

```swift
@MainActor
@Observable
class AIService {
    private let session: LanguageModelSession
    private(set) var content: String = ""
    private(set) var isLoading: Bool = false
    private(set) var error: AIError?
    
    enum AIError: LocalizedError {
        case networkUnavailable
        case modelUnavailable
        case invalidPrompt
        case rateLimited
        
        var errorDescription: String? {
            switch self {
            case .networkUnavailable:
                return "Network connection unavailable"
            case .modelUnavailable:
                return "AI model temporarily unavailable"
            case .invalidPrompt:
                return "Invalid prompt format"
            case .rateLimited:
                return "Too many requests. Please try again later."
            }
        }
    }
    
    init() {
        session = LanguageModelSession(instructions: "You are a helpful assistant")
    }
    
    func generateContent(prompt: String) async {
        isLoading = true
        error = nil
        
        do {
            let stream = session.streamResponse(to: prompt)
            content = ""
            
            for try await partial in stream {
                content = partial
            }
        } catch {
            self.error = mapError(error)
        }
        
        isLoading = false
    }
    
    private func mapError(_ error: Error) -> AIError {
        // Map system errors to user-friendly errors
        if error.localizedDescription.contains("network") {
            return .networkUnavailable
        }
        return .modelUnavailable
    }
}

struct AIContentView: View {
    @State private var service = AIService()
    @State private var prompt = ""
    @State private var showingError = false
    
    var body: some View {
        VStack {
            TextField("Enter prompt", text: $prompt)
                .textFieldStyle(.roundedBorder)
                .disabled(service.isLoading)
            
            Button("Generate") {
                Task {
                    await service.generateContent(prompt: prompt)
                }
            }
            .disabled(service.isLoading || prompt.isEmpty)
            
            if service.isLoading {
                ProgressView("Generating...")
            } else if !service.content.isEmpty {
                Text(service.content)
                    .padding()
            }
        }
        .alert("Error", isPresented: .constant(service.error != nil)) {
            Button("OK") { service.error = nil }
            Button("Retry") {
                Task {
                    await service.generateContent(prompt: prompt)
                }
            }
        } message: {
            Text(service.error?.localizedDescription ?? "Unknown error")
        }
    }
}
```

## Performance Optimization

### Efficient Updates

```swift
@MainActor
@Observable
class OptimizedGenerator {
    private let session: LanguageModelSession
    private(set) var content: String = ""
    
    // Throttle UI updates for better performance
    private var updateTimer: Timer?
    private var pendingContent: String = ""
    
    init() {
        session = LanguageModelSession(instructions: "...")
    }
    
    func generateContent(prompt: String) async throws {
        let stream = session.streamResponse(to: prompt)
        
        for try await partial in stream {
            pendingContent = partial
            scheduleUpdate()
        }
        
        // Final update
        updateTimer?.invalidate()
        content = pendingContent
    }
    
    private func scheduleUpdate() {
        updateTimer?.invalidate()
        updateTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) { _ in
            self.content = self.pendingContent
        }
    }
}
```

### Lazy Loading Patterns

```swift
struct LazyAIContentView: View {
    @State private var generator = ContentGenerator()
    @State private var hasAppeared = false
    
    var body: some View {
        VStack {
            if hasAppeared {
                // Only show AI content after view appears
                AIGeneratedContent(generator: generator)
            } else {
                ProgressView("Preparing AI...")
            }
        }
        .task {
            if !hasAppeared {
                // Prewarm session in background
                await generator.prewarm()
                hasAppeared = true
            }
        }
    }
}
```

## Accessibility Integration

### Voice Over Support

```swift
struct AccessibleAIView: View {
    let content: GeneratedContent.PartiallyGenerated
    
    var body: some View {
        VStack {
            if let title = content.title {
                Text(title)
                    .font(.title)
                    .accessibilityLabel("AI generated title: \(title)")
                    .accessibilityHint("This title was created by artificial intelligence")
            }
            
            if let description = content.description {
                Text(description)
                    .accessibilityLabel("AI generated description")
                    .accessibilityValue(description)
            } else {
                Text("Generating description...")
                    .accessibilityLabel("AI is currently generating description")
                    .accessibilityValue("Please wait while content is being created")
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("AI Generated Content")
    }
}
```

### Dynamic Type Support

```swift
struct ResponsiveAIView: View {
    let content: String
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    
    var body: some View {
        ScrollView {
            Text(content)
                .font(.body)
                .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 10)
                .padding(.horizontal, dynamicTypeSize.isAccessibilitySize ? 20 : 16)
        }
    }
}
```

## Testing SwiftUI + AI

### Preview Providers

```swift
struct AIContentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Loading state
            AIContentView()
                .environment(MockAIService(state: .loading))
                .previewDisplayName("Loading")
            
            // Content state
            AIContentView()
                .environment(MockAIService(state: .content("Sample AI generated content")))
                .previewDisplayName("With Content")
            
            // Error state
            AIContentView()
                .environment(MockAIService(state: .error))
                .previewDisplayName("Error State")
        }
    }
}

class MockAIService: ObservableObject {
    enum State {
        case loading
        case content(String)
        case error
    }
    
    private let mockState: State
    
    init(state: State) {
        self.mockState = state
    }
    
    var isLoading: Bool {
        if case .loading = mockState { return true }
        return false
    }
    
    var content: String {
        if case .content(let text) = mockState { return text }
        return ""
    }
    
    var hasError: Bool {
        if case .error = mockState { return true }
        return false
    }
}
```

### UI Testing

```swift
import XCTest

class AIContentUITests: XCTestCase {
    func testContentGeneration() throws {
        let app = XCUIApplication()
        app.launch()
        
        let promptField = app.textFields["Enter prompt"]
        let generateButton = app.buttons["Generate"]
        
        promptField.tap()
        promptField.typeText("Write a haiku")
        
        generateButton.tap()
        
        // Wait for loading indicator
        XCTAssertTrue(app.progressIndicators["Generating..."].waitForExistence(timeout: 2))
        
        // Wait for content to appear
        let contentText = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'haiku'")).firstMatch
        XCTAssertTrue(contentText.waitForExistence(timeout: 10))
    }
}
```

## Best Practices

### 1. Proper State Management

```swift
// ✅ Good: Clear separation of concerns
@MainActor
@Observable
class ContentService {
    private let session: LanguageModelSession
    private(set) var state: ContentState = .idle
    
    enum ContentState {
        case idle
        case generating
        case content(String)
        case error(Error)
    }
    
    // Single source of truth for UI state
    var isGenerating: Bool {
        if case .generating = state { return true }
        return false
    }
}

// ❌ Bad: Multiple state variables that can get out of sync
@Observable
class BadContentService {
    var content: String = ""
    var isLoading: Bool = false
    var hasError: Bool = false
    var errorMessage: String = ""
}
```

### 2. Responsive UI Updates

```swift
// ✅ Good: Immediate UI feedback
Button("Generate") {
    Task {
        await service.generateContent(prompt: prompt)
    }
}
.disabled(service.isGenerating)

// ❌ Bad: No immediate feedback
Button("Generate") {
    Task {
        try await service.generateContent(prompt: prompt)
    }
}
```

### 3. Graceful Error Handling

```swift
// ✅ Good: User-friendly error handling
.alert("Generation Failed", isPresented: .constant(service.hasError)) {
    Button("Retry") {
        Task { await service.retry() }
    }
    Button("Cancel", role: .cancel) {
        service.clearError()
    }
} message: {
    Text(service.userFriendlyErrorMessage)
}
```

## Next Steps

- Explore [Observable State Management](./observable-state.md) patterns
- Learn about [UI Performance Optimization](./ui-performance.md)
- Check out [practical examples](./examples/) with full SwiftUI implementations

---

*Build responsive, accessible AI-powered interfaces with SwiftUI and Foundation Models!*