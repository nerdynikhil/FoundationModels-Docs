# Text Summarization Example

## Overview

Learn how to build a text summarization app using Foundation Models, based on the HelloWorld sample project. This example demonstrates streaming text generation, SwiftUI integration, and user-friendly interfaces.

## Complete Implementation

### 1. The Summarizer Service

```swift
//  Summarizer.swift
import Foundation
import FoundationModels
import Observation

@MainActor
@Observable
class Summarizer {
    
    let session: LanguageModelSession
    var summarizedText: String = ""
    var isSummarizing: Bool = false
    
    init() {
        session = LanguageModelSession(
            instructions: """
            You are a text summarizer. Your job is to summarize the text 
            provided to you in 5 lines or less. Focus on the key points 
            and main ideas while maintaining clarity and readability.
            """
        )
    }
    
    func summarize(text: String) async throws {
        let prompt = "Summarize the following text:\\n\\(text)"
        let stream = session.streamResponse(to: prompt)
        
        print("Summarization begins!")
        isSummarizing = true
        summarizedText = ""
        
        for try await partial in stream {
            summarizedText = partial
        }
        
        print("Summarization completed!")
        isSummarizing = false 
    }
    
    func clearSummary() {
        summarizedText = ""
    }
}
```

### 2. SwiftUI Interface

```swift
//  ContentView.swift
import SwiftUI
import FoundationModels

struct ContentView: View {
    
    @State private var inputText: String = ""
    @State private var summarizer = Summarizer()
    @FocusState private var isTextFieldFocused: Bool
    
    private func loadSampleText() -> String {
        guard let url = Bundle.main.url(forResource: "transcript", withExtension: "txt"),
              let contents = try? String(contentsOf: url, encoding: .utf8) else {
            return """
            Sample text for summarization. This could be any long-form content 
            that you want to condense into key points. The AI will analyze the 
            content and provide a concise summary highlighting the main ideas 
            and important details.
            """
        }
        return contents
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Input Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Text to Summarize")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    TextEditor(text: $inputText)
                        .frame(minHeight: 200, maxHeight: 300)
                        .padding(8)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                        .focused($isTextFieldFocused)
                        .disabled(summarizer.isSummarizing)
                }
                
                // Action Buttons
                HStack(spacing: 16) {
                    Button("Load Sample") {
                        inputText = loadSampleText()
                        isTextFieldFocused = false
                    }
                    .buttonStyle(.bordered)
                    .disabled(summarizer.isSummarizing)
                    
                    Spacer()
                    
                    Button("Clear") {
                        inputText = ""
                        summarizer.clearSummary()
                    }
                    .buttonStyle(.bordered)
                    .disabled(summarizer.isSummarizing)
                    
                    Button {
                        Task {
                            isTextFieldFocused = false
                            try await summarizer.summarize(text: inputText)
                        }
                    } label: {
                        HStack {
                            if summarizer.isSummarizing {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                            Text(summarizer.isSummarizing ? "Summarizing..." : "Summarize")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(summarizer.isSummarizing || inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                
                // Output Section
                if !summarizer.summarizedText.isEmpty || summarizer.isSummarizing {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Summary")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        ScrollView {
                            Text(summarizer.summarizedText.isEmpty ? "Generating summary..." : summarizer.summarizedText)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(8)
                                .redacted(reason: summarizer.summarizedText.isEmpty ? .placeholder : [])
                        }
                        .frame(maxHeight: 200)
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Text Summarizer")
            .navigationBarTitleDisplayMode(.large)
        }
        .onAppear {
            inputText = loadSampleText()
        }
    }
}
```

### 3. App Entry Point

```swift
//  HelloWorldApp.swift
import SwiftUI

@main
struct HelloWorldApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

## Advanced Features

### Enhanced Summarizer with Options

```swift
@MainActor
@Observable
class AdvancedSummarizer {
    
    let session: LanguageModelSession
    var summarizedText: String = ""
    var isSummarizing: Bool = false
    var summaryStyle: SummaryStyle = .bullets
    var summaryLength: SummaryLength = .medium
    
    enum SummaryStyle: String, CaseIterable {
        case bullets = "bullet points"
        case paragraph = "paragraph form"
        case outline = "structured outline"
        
        var displayName: String {
            switch self {
            case .bullets: return "Bullet Points"
            case .paragraph: return "Paragraph"
            case .outline: return "Outline"
            }
        }
    }
    
    enum SummaryLength: String, CaseIterable {
        case short = "2-3 lines"
        case medium = "4-5 lines"
        case long = "6-8 lines"
        
        var displayName: String {
            switch self {
            case .short: return "Short"
            case .medium: return "Medium"
            case .long: return "Detailed"
            }
        }
    }
    
    init() {
        session = LanguageModelSession(
            instructions: """
            You are an expert text summarizer. Create clear, concise summaries 
            that capture the essential information while maintaining readability.
            """
        )
    }
    
    func summarize(text: String) async throws {
        let prompt = """
        Summarize the following text in \(summaryStyle.rawValue) format, 
        keeping it to \(summaryLength.rawValue):
        
        \(text)
        """
        
        let stream = session.streamResponse(to: prompt)
        
        isSummarizing = true
        summarizedText = ""
        
        for try await partial in stream {
            summarizedText = partial
        }
        
        isSummarizing = false
    }
}
```

### Advanced UI with Options

```swift
struct AdvancedSummarizerView: View {
    @State private var summarizer = AdvancedSummarizer()
    @State private var inputText = ""
    @State private var showingOptions = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Options Section
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Summary Options")
                            .font(.headline)
                        
                        Spacer()
                        
                        Button("Options") {
                            showingOptions.toggle()
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    if showingOptions {
                        VStack(alignment: .leading, spacing: 8) {
                            Picker("Style", selection: $summarizer.summaryStyle) {
                                ForEach(AdvancedSummarizer.SummaryStyle.allCases, id: \\.self) { style in
                                    Text(style.displayName).tag(style)
                                }
                            }
                            .pickerStyle(.segmented)
                            
                            Picker("Length", selection: $summarizer.summaryLength) {
                                ForEach(AdvancedSummarizer.SummaryLength.allCases, id: \\.self) { length in
                                    Text(length.displayName).tag(length)
                                }
                            }
                            .pickerStyle(.segmented)
                        }
                        .transition(.opacity.combined(with: .scale))
                    }
                }
                .animation(.easeInOut(duration: 0.3), value: showingOptions)
                
                // Input Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Text to Summarize")
                        .font(.headline)
                    
                    TextEditor(text: $inputText)
                        .frame(height: 200)
                        .padding(8)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                        .disabled(summarizer.isSummarizing)
                }
                
                // Generate Button
                Button {
                    Task {
                        try await summarizer.summarize(text: inputText)
                    }
                } label: {
                    HStack {
                        if summarizer.isSummarizing {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                        Text(summarizer.isSummarizing ? "Summarizing..." : "Generate Summary")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(summarizer.isSummarizing || inputText.isEmpty)
                
                // Results Section
                if !summarizer.summarizedText.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Summary")
                                .font(.headline)
                            
                            Spacer()
                            
                            Button(action: {
                                UIPasteboard.general.string = summarizer.summarizedText
                            }) {
                                Image(systemName: "doc.on.doc")
                            }
                            .buttonStyle(.bordered)
                        }
                        
                        ScrollView {
                            Text(summarizer.summarizedText)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Advanced Summarizer")
        }
    }
}
```

## Error Handling

### Robust Error Management

```swift
extension Summarizer {
    enum SummarizerError: LocalizedError {
        case emptyInput
        case textTooLong
        case networkError
        case modelUnavailable
        
        var errorDescription: String? {
            switch self {
            case .emptyInput:
                return "Please provide text to summarize"
            case .textTooLong:
                return "Text is too long. Please provide a shorter text."
            case .networkError:
                return "Network connection unavailable"
            case .modelUnavailable:
                return "AI model temporarily unavailable"
            }
        }
        
        var recoverySuggestion: String? {
            switch self {
            case .emptyInput:
                return "Enter some text in the input field"
            case .textTooLong:
                return "Try breaking the text into smaller sections"
            case .networkError:
                return "Check your internet connection and try again"
            case .modelUnavailable:
                return "Please try again in a few moments"
            }
        }
    }
    
    func summarizeWithErrorHandling(text: String) async throws {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw SummarizerError.emptyInput
        }
        
        guard text.count < 10000 else {
            throw SummarizerError.textTooLong
        }
        
        do {
            try await summarize(text: text)
        } catch {
            if error.localizedDescription.contains("network") {
                throw SummarizerError.networkError
            } else {
                throw SummarizerError.modelUnavailable
            }
        }
    }
}
```

### Error Handling UI

```swift
struct SummarizerWithErrorHandling: View {
    @State private var summarizer = Summarizer()
    @State private var inputText = ""
    @State private var errorMessage: String?
    @State private var showingError = false
    
    var body: some View {
        VStack {
            // ... existing UI code ...
            
            Button("Summarize") {
                Task {
                    do {
                        try await summarizer.summarizeWithErrorHandling(text: inputText)
                        errorMessage = nil
                    } catch let error as Summarizer.SummarizerError {
                        errorMessage = error.localizedDescription
                        showingError = true
                    } catch {
                        errorMessage = "An unexpected error occurred"
                        showingError = true
                    }
                }
            }
        }
        .alert("Summarization Error", isPresented: $showingError) {
            Button("OK") {
                showingError = false
                errorMessage = nil
            }
            
            if let error = errorMessage,
               let summarizerError = Summarizer.SummarizerError.allCases.first(where: { $0.localizedDescription == error }) {
                Button("Help") {
                    showHelp(for: summarizerError)
                }
            }
        } message: {
            if let error = errorMessage {
                Text(error)
            }
        }
    }
    
    private func showHelp(for error: Summarizer.SummarizerError) {
        // Show contextual help based on error type
    }
}
```

## Performance Tips

### 1. Session Prewarming

```swift
class SummarizerManager {
    static let shared = SummarizerManager()
    
    private let summarizer = Summarizer()
    
    private init() {
        // Prewarm the session for faster first response
        summarizer.session.prewarm()
    }
    
    func getSummarizer() -> Summarizer {
        return summarizer
    }
}
```

### 2. Input Validation

```swift
extension Summarizer {
    func canSummarize(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && trimmed.count >= 50 && trimmed.count <= 10000
    }
    
    func estimatedSummaryTime(for text: String) -> TimeInterval {
        let wordCount = text.components(separatedBy: .whitespacesAndNewlines).count
        return TimeInterval(wordCount) * 0.1 // Rough estimate
    }
}
```

### 3. Memory Management

```swift
@MainActor
@Observable
class MemoryEfficientSummarizer {
    private let session: LanguageModelSession
    var summarizedText: String = ""
    var isSummarizing: Bool = false
    
    init() {
        session = LanguageModelSession(instructions: "...")
    }
    
    deinit {
        // Clean up session resources
        session.invalidate()
    }
    
    func clearMemory() {
        summarizedText = ""
        // Additional cleanup if needed
    }
}
```

## Testing

### Unit Tests

```swift
import XCTest
@testable import HelloWorld

class SummarizerTests: XCTestCase {
    var summarizer: Summarizer!
    
    override func setUp() {
        super.setUp()
        summarizer = Summarizer()
    }
    
    func testSummarizeValidText() async throws {
        let sampleText = "This is a sample text that needs to be summarized..."
        
        try await summarizer.summarize(text: sampleText)
        
        XCTAssertFalse(summarizer.isSummarizing)
        XCTAssertFalse(summarizer.summarizedText.isEmpty)
        XCTAssertLessThan(summarizer.summarizedText.count, sampleText.count)
    }
    
    func testCanSummarize() {
        XCTAssertFalse(summarizer.canSummarize(""))
        XCTAssertFalse(summarizer.canSummarize("Too short"))
        XCTAssertTrue(summarizer.canSummarize(String(repeating: "word ", count: 20)))
    }
}
```

### UI Tests

```swift
import XCTest

class SummarizerUITests: XCTestCase {
    func testSummarizationFlow() throws {
        let app = XCUIApplication()
        app.launch()
        
        let textEditor = app.textViews.firstMatch
        textEditor.tap()
        textEditor.typeText("Sample text for summarization...")
        
        let summarizeButton = app.buttons["Summarize"]
        XCTAssertTrue(summarizeButton.exists)
        
        summarizeButton.tap()
        
        // Wait for summarization to complete
        let summaryText = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Summary'")).firstMatch
        XCTAssertTrue(summaryText.waitForExistence(timeout: 10))
    }
}
```

## Next Steps

1. **Explore Structured Generation**: Learn about [`@Generable`](../generable-protocol.md) for type-safe outputs
2. **Add Custom Tools**: Integrate [custom tools](../tool-protocol.md) for enhanced functionality
3. **Advanced UI Patterns**: Check out [SwiftUI integration](../swiftui-integration.md) techniques

## Key Takeaways

- Use `@Observable` for reactive UI updates
- Implement proper error handling for production apps
- Prewarm sessions for better performance
- Provide clear loading states and user feedback
- Validate input to prevent unnecessary API calls

---

*Master text summarization as your foundation for more complex AI-powered features!*