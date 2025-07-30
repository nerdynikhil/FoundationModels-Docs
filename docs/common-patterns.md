# Common Patterns & Best Practices

## Overview

This guide consolidates proven patterns and best practices for building robust AI-powered applications with Foundation Models. Learn from real-world examples and avoid common pitfalls.

## Session Management Patterns

### 1. Singleton Session Manager

Centralize session management for better resource utilization:

```swift
@MainActor
class SessionManager {
    static let shared = SessionManager()
    
    private(set) lazy var summarizer = LanguageModelSession(
        instructions: "You are a text summarizer. Keep responses under 5 lines."
    )
    
    private(set) lazy var codeGenerator = LanguageModelSession(
        instructions: "You are a Swift code generator. Write clean, documented code."
    )
    
    private(set) lazy var contentWriter = LanguageModelSession(
        instructions: "You are a professional content writer. Write engaging, clear content."
    )
    
    private init() {}
    
    func preloadSessions() {
        Task {
            await withTaskGroup(of: Void.self) { group in
                group.addTask { self.summarizer.prewarm() }
                group.addTask { self.codeGenerator.prewarm() }
                group.addTask { self.contentWriter.prewarm() }
            }
        }
    }
}

// Usage in App Delegate
class AppDelegate: UIApplicationDelegate {
    func application(_ application: UIApplication, 
                    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        SessionManager.shared.preloadSessions()
        return true
    }
}
```

### 2. Protocol-Based Session Configuration

Create reusable session configurations:

```swift
protocol SessionConfigurable {
    var instructions: String { get }
    var tools: [Tool] { get }
    var modelPreference: ModelPreference { get }
}

extension SessionConfigurable {
    var tools: [Tool] { [] }
    var modelPreference: ModelPreference { .balanced }
    
    func createSession() -> LanguageModelSession {
        let session = LanguageModelSession(tools: tools) { instructions }
        session.setModelPreference(modelPreference)
        return session
    }
}

struct SummarizerConfig: SessionConfigurable {
    let instructions = """
        You are a professional text summarizer. Create concise, 
        accurate summaries that capture key points and main ideas.
        """
}

struct CodeGeneratorConfig: SessionConfigurable {
    let instructions = """
        You are a Swift programming assistant. Generate clean, 
        well-documented code following Apple's style guidelines.
        """
    let modelPreference: ModelPreference = .quality
}

struct ContentWriterConfig: SessionConfigurable {
    let instructions = """
        You are a content writer specializing in technical documentation. 
        Write clear, engaging content for developers.
        """
    let tools: [Tool] = [ResearchTool(), FactCheckTool()]
}
```

### 3. Environment-Aware Sessions

Adapt behavior based on runtime environment:

```swift
struct SessionFactory {
    static func createSession(for purpose: SessionPurpose) -> LanguageModelSession {
        let baseInstructions = purpose.baseInstructions
        
        #if DEBUG
        let debugInstructions = """
        \(baseInstructions)
        
        [DEBUG MODE: Provide detailed explanations and verbose output]
        """
        return LanguageModelSession(instructions: debugInstructions)
        #else
        return LanguageModelSession(instructions: baseInstructions)
        #endif
    }
}

enum SessionPurpose {
    case summarization
    case codeGeneration
    case contentWriting
    
    var baseInstructions: String {
        switch self {
        case .summarization:
            return "You are a text summarizer..."
        case .codeGeneration:
            return "You are a code generator..."
        case .contentWriting:
            return "You are a content writer..."
        }
    }
}
```

## State Management Patterns

### 1. Centralized State with Observable

```swift
@MainActor
@Observable
class AIContentService {
    private let session: LanguageModelSession
    
    // Single source of truth for UI state
    private(set) var state: ContentState = .idle
    
    enum ContentState {
        case idle
        case generating
        case content(String)
        case error(AIError)
    }
    
    init() {
        session = LanguageModelSession(instructions: "...")
        session.prewarm()
    }
    
    // Computed properties for UI convenience
    var isGenerating: Bool {
        if case .generating = state { return true }
        return false
    }
    
    var content: String? {
        if case .content(let text) = state { return text }
        return nil
    }
    
    var error: AIError? {
        if case .error(let error) = state { return error }
        return nil
    }
    
    func generateContent(prompt: String) async {
        state = .generating
        
        do {
            let stream = session.streamResponse(to: prompt)
            var accumulatedContent = ""
            
            for try await partial in stream {
                accumulatedContent = partial
                state = .content(accumulatedContent)
            }
        } catch {
            state = .error(AIError.from(error))
        }
    }
    
    func reset() {
        state = .idle
    }
}
```

### 2. Structured Content State Management

```swift
@MainActor
@Observable
class StructuredContentService<T: Generable> {
    private let session: LanguageModelSession
    private(set) var partialContent: T.PartiallyGenerated?
    private(set) var isGenerating = false
    private(set) var error: Error?
    
    init(session: LanguageModelSession) {
        self.session = session
    }
    
    func generate(prompt: String, type: T.Type) async {
        isGenerating = true
        error = nil
        partialContent = nil
        
        do {
            let stream = session.streamResponse(to: prompt, generating: type)
            for try await partial in stream {
                partialContent = partial
            }
        } catch {
            self.error = error
        }
        
        isGenerating = false
    }
    
    var isComplete: Bool {
        partialContent?.isComplete() ?? false
    }
    
    func finalize() throws -> T? {
        try partialContent?.finalize()
    }
}
```

## Error Handling Patterns

### 1. Comprehensive Error Management

```swift
enum AIError: LocalizedError {
    case sessionNotReady
    case invalidPrompt(String)
    case generationFailed(underlying: Error)
    case networkUnavailable
    case rateLimited(retryAfter: TimeInterval)
    case contentFiltered(reason: String)
    case modelUnavailable
    
    var errorDescription: String? {
        switch self {
        case .sessionNotReady:
            return "AI session is not ready"
        case .invalidPrompt(let prompt):
            return "Invalid prompt: \(prompt)"
        case .generationFailed(let error):
            return "Generation failed: \(error.localizedDescription)"
        case .networkUnavailable:
            return "Network connection unavailable"
        case .rateLimited(let retryAfter):
            return "Rate limited. Try again in \(Int(retryAfter)) seconds"
        case .contentFiltered(let reason):
            return "Content filtered: \(reason)"
        case .modelUnavailable:
            return "AI model temporarily unavailable"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .sessionNotReady:
            return "Wait for the session to initialize"
        case .invalidPrompt:
            return "Modify your prompt and try again"
        case .networkUnavailable:
            return "Check your internet connection"
        case .rateLimited:
            return "Wait before making another request"
        case .contentFiltered:
            return "Modify your prompt to avoid filtered content"
        case .modelUnavailable:
            return "Try again in a few moments"
        default:
            return "Please try again"
        }
    }
    
    static func from(_ error: Error) -> AIError {
        if let aiError = error as? AIError {
            return aiError
        }
        
        let description = error.localizedDescription.lowercased()
        
        if description.contains("network") || description.contains("connection") {
            return .networkUnavailable
        } else if description.contains("rate") || description.contains("limit") {
            return .rateLimited(retryAfter: 60)
        } else if description.contains("filter") || description.contains("inappropriate") {
            return .contentFiltered(reason: "Content policy violation")
        } else {
            return .generationFailed(underlying: error)
        }
    }
}
```

### 2. Retry Logic Pattern

```swift
actor RetryManager {
    private var retryAttempts: [String: Int] = [:]
    private var lastAttempt: [String: Date] = [:]
    
    func shouldRetry(for operation: String, maxAttempts: Int = 3, backoffInterval: TimeInterval = 2.0) -> Bool {
        let attempts = retryAttempts[operation, default: 0]
        let lastTime = lastAttempt[operation] ?? Date.distantPast
        let timeSinceLastAttempt = Date().timeIntervalSince(lastTime)
        
        return attempts < maxAttempts && timeSinceLastAttempt >= backoffInterval
    }
    
    func recordAttempt(for operation: String) {
        retryAttempts[operation, default: 0] += 1
        lastAttempt[operation] = Date()
    }
    
    func resetAttempts(for operation: String) {
        retryAttempts[operation] = 0
        lastAttempt[operation] = nil
    }
}

extension AIContentService {
    func generateContentWithRetry(prompt: String) async {
        let operationId = "generate_\(prompt.hashValue)"
        
        while await retryManager.shouldRetry(for: operationId) {
            await retryManager.recordAttempt(for: operationId)
            
            do {
                try await generateContent(prompt: prompt)
                await retryManager.resetAttempts(for: operationId)
                return
            } catch {
                let aiError = AIError.from(error)
                
                // Don't retry certain errors
                if case .contentFiltered = aiError {
                    state = .error(aiError)
                    return
                }
                
                // Continue retry loop for other errors
                state = .error(aiError)
            }
        }
    }
}
```

## UI Integration Patterns

### 1. Responsive UI Updates

```swift
struct ResponsiveAIView: View {
    @State private var service = AIContentService()
    @State private var prompt = ""
    
    var body: some View {
        VStack(spacing: 20) {
            // Input Section
            VStack(alignment: .leading) {
                Text("Enter your prompt")
                    .font(.headline)
                
                TextField("Describe what you want...", text: $prompt, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(3...6)
                    .disabled(service.isGenerating)
            }
            
            // Action Button with State
            Button(action: {
                Task {
                    await service.generateContent(prompt: prompt)
                }
            }) {
                HStack {
                    if service.isGenerating {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                    
                    Text(buttonTitle)
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(!canGenerate)
            .animation(.easeInOut(duration: 0.2), value: service.isGenerating)
            
            // Content Display
            ContentDisplayView(service: service)
        }
        .padding()
        .alert("Error", isPresented: .constant(service.error != nil)) {
            AlertButtonsView(service: service, prompt: prompt)
        } message: {
            if let error = service.error {
                Text(error.localizedDescription)
            }
        }
    }
    
    private var buttonTitle: String {
        service.isGenerating ? "Generating..." : "Generate"
    }
    
    private var canGenerate: Bool {
        !service.isGenerating && !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

struct ContentDisplayView: View {
    let service: AIContentService
    
    var body: some View {
        Group {
            switch service.state {
            case .idle:
                EmptyStateView()
            case .generating:
                LoadingStateView()
            case .content(let text):
                ContentStateView(content: text)
            case .error(let error):
                ErrorStateView(error: error)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: service.state)
    }
}
```

### 2. Streaming Content Display

```swift
struct StreamingTextView: View {
    let content: String
    @State private var displayedContent = ""
    @State private var isAnimating = false
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Text(displayedContent)
                        .font(.body)
                        .textSelection(.enabled)
                        .id("content")
                    
                    if isAnimating {
                        Text("▎")
                            .foregroundColor(.blue)
                            .animation(.opacity.repeatForever(autoreverses: true), value: isAnimating)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
            }
        }
        .onChange(of: content) { _, newContent in
            animateContentUpdate(to: newContent)
        }
    }
    
    private func animateContentUpdate(to newContent: String) {
        isAnimating = true
        
        // Smooth character-by-character animation
        let newCharacters = Array(newContent.dropFirst(displayedContent.count))
        
        guard !newCharacters.isEmpty else {
            isAnimating = false
            return
        }
        
        var characterIndex = 0
        let timer = Timer.scheduledTimer(withTimeInterval: 0.02, repeats: true) { timer in
            if characterIndex < newCharacters.count {
                displayedContent.append(newCharacters[characterIndex])
                characterIndex += 1
            } else {
                timer.invalidate()
                isAnimating = false
            }
        }
    }
}
```

### 3. Partial Content Rendering

```swift
struct PartialRecipeView: View {
    let recipe: Recipe.PartiallyGenerated
    
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                // Recipe Name
                PartialContentView(
                    content: recipe.name,
                    placeholder: "Generating recipe name...",
                    style: .title
                )
                
                // Description
                PartialContentView(
                    content: recipe.description,
                    placeholder: "Generating description...",
                    style: .body
                )
                
                // Ingredients
                if let ingredients = recipe.ingredients {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Ingredients")
                            .font(.headline)
                        
                        ForEach(ingredients.indices, id: \.self) { index in
                            PartialContentView(
                                content: ingredients[index].name,
                                placeholder: "Loading ingredient...",
                                style: .listItem
                            )
                        }
                    }
                } else {
                    PlaceholderSection(title: "Ingredients", itemCount: 5)
                }
                
                // Instructions
                if let instructions = recipe.instructions {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Instructions")
                            .font(.headline)
                        
                        ForEach(instructions.indices, id: \.self) { index in
                            HStack(alignment: .top) {
                                Text("\(index + 1).")
                                    .fontWeight(.medium)
                                
                                PartialContentView(
                                    content: instructions[index].text,
                                    placeholder: "Generating step...",
                                    style: .body
                                )
                            }
                        }
                    }
                } else {
                    PlaceholderSection(title: "Instructions", itemCount: 6)
                }
            }
            .padding()
        }
    }
}

struct PartialContentView: View {
    let content: String?
    let placeholder: String
    let style: ContentStyle
    
    enum ContentStyle {
        case title
        case body
        case listItem
        
        var font: Font {
            switch self {
            case .title: return .title2.bold()
            case .body: return .body
            case .listItem: return .body
            }
        }
    }
    
    var body: some View {
        if let content = content {
            Text(content)
                .font(style.font)
                .transition(.opacity.combined(with: .scale))
        } else {
            Text(placeholder)
                .font(style.font)
                .redacted(reason: .placeholder)
        }
    }
}

struct PlaceholderSection: View {
    let title: String
    let itemCount: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            
            ForEach(0..<itemCount, id: \.self) { _ in
                Text("Loading...")
                    .redacted(reason: .placeholder)
            }
        }
    }
}
```

## Tool Integration Patterns

### 1. Tool Factory Pattern

```swift
protocol ToolFactory {
    static func createTools(for context: ToolContext) -> [Tool]
}

struct ToolContext {
    let userLocation: CLLocationCoordinate2D?
    let preferences: UserPreferences
    let capabilities: DeviceCapabilities
}

struct TravelToolFactory: ToolFactory {
    static func createTools(for context: ToolContext) -> [Tool] {
        var tools: [Tool] = []
        
        if let location = context.userLocation {
            tools.append(NearbySearchTool(location: location))
            tools.append(WeatherTool(location: location))
        }
        
        if context.capabilities.hasMapAccess {
            tools.append(DirectionsTool())
        }
        
        if context.preferences.includeRecommendations {
            tools.append(RecommendationTool())
        }
        
        return tools
    }
}
```

### 2. Tool Chaining Pattern

```swift
actor ToolChain {
    private let tools: [String: Tool]
    
    init(tools: [Tool]) {
        self.tools = Dictionary(uniqueKeysWithValues: tools.map { ($0.name, $0) })
    }
    
    func execute(toolName: String, arguments: [String: Any]) async throws -> ToolOutput {
        guard let tool = tools[toolName] else {
            throw ToolError.toolNotFound(toolName)
        }
        
        return try await tool.call(arguments: arguments)
    }
    
    func executeChain(_ chain: [ToolCall]) async throws -> [ToolOutput] {
        var results: [ToolOutput] = []
        
        for toolCall in chain {
            let result = try await execute(toolName: toolCall.name, arguments: toolCall.arguments)
            results.append(result)
            
            // Pass result to next tool if needed
            if let nextCall = chain.next(after: toolCall) {
                nextCall.addInput(from: result)
            }
        }
        
        return results
    }
}
```

### 3. Conditional Tool Usage

```swift
class SmartSessionManager {
    private let baseSessions: [String: LanguageModelSession] = [:]
    private let toolRegistry = ToolRegistry()
    
    func createSession(for task: AITask, context: TaskContext) -> LanguageModelSession {
        let relevantTools = selectTools(for: task, context: context)
        let instructions = generateInstructions(for: task, tools: relevantTools)
        
        return LanguageModelSession(tools: relevantTools) {
            instructions
        }
    }
    
    private func selectTools(for task: AITask, context: TaskContext) -> [Tool] {
        switch task {
        case .textSummarization:
            return [] // No tools needed
            
        case .travelPlanning:
            return [
                toolRegistry.weatherTool,
                toolRegistry.nearbySearchTool,
                toolRegistry.directionsTools
            ].compactMap { $0 }
            
        case .recipeGeneration:
            var tools: [Tool] = []
            if context.hasNetworkAccess {
                tools.append(toolRegistry.recipeAPITool)
            }
            if context.hasNutritionData {
                tools.append(toolRegistry.nutritionTool)
            }
            return tools
            
        case .codeGeneration:
            return [
                toolRegistry.documentationTool,
                toolRegistry.codeAnalysisTool
            ].compactMap { $0 }
        }
    }
}
```

## Performance Optimization Patterns

### 1. Lazy Session Initialization

```swift
class LazySessionManager {
    private var sessions: [SessionType: LanguageModelSession] = [:]
    private let sessionQueue = DispatchQueue(label: "session.queue", qos: .userInitiated)
    
    func session(for type: SessionType) -> LanguageModelSession {
        if let existingSession = sessions[type] {
            return existingSession
        }
        
        let newSession = createSession(for: type)
        sessions[type] = newSession
        
        // Prewarm in background
        Task {
            newSession.prewarm()
        }
        
        return newSession
    }
    
    private func createSession(for type: SessionType) -> LanguageModelSession {
        switch type {
        case .summarization:
            return LanguageModelSession(instructions: "You are a text summarizer...")
        case .codeGeneration:
            return LanguageModelSession(instructions: "You are a code generator...")
        // ... other cases
        }
    }
}
```

### 2. Response Caching Pattern

```swift
actor ResponseCache {
    private var cache: [String: CachedResponse] = [:]
    private let maxCacheSize = 100
    private let cacheExpiration: TimeInterval = 3600 // 1 hour
    
    struct CachedResponse {
        let content: String
        let timestamp: Date
        let hitCount: Int
    }
    
    func getCachedResponse(for prompt: String) -> String? {
        let key = prompt.sha256
        
        guard let cached = cache[key],
              Date().timeIntervalSince(cached.timestamp) < cacheExpiration else {
            cache.removeValue(forKey: key)
            return nil
        }
        
        // Update hit count
        cache[key] = CachedResponse(
            content: cached.content,
            timestamp: cached.timestamp,
            hitCount: cached.hitCount + 1
        )
        
        return cached.content
    }
    
    func cacheResponse(_ content: String, for prompt: String) {
        let key = prompt.sha256
        
        cache[key] = CachedResponse(
            content: content,
            timestamp: Date(),
            hitCount: 1
        )
        
        // Evict old entries if cache is full
        if cache.count > maxCacheSize {
            evictLeastUsed()
        }
    }
    
    private func evictLeastUsed() {
        let sorted = cache.sorted { $0.value.hitCount < $1.value.hitCount }
        if let leastUsed = sorted.first {
            cache.removeValue(forKey: leastUsed.key)
        }
    }
}
```

### 3. Batch Processing Pattern

```swift
class BatchProcessor {
    private let session: LanguageModelSession
    private var batchQueue: [BatchItem] = []
    private let batchSize = 5
    private let batchInterval: TimeInterval = 2.0
    
    struct BatchItem {
        let id: UUID
        let prompt: String
        let completion: (Result<String, Error>) -> Void
    }
    
    init(session: LanguageModelSession) {
        self.session = session
        startBatchTimer()
    }
    
    func process(prompt: String) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            let item = BatchItem(
                id: UUID(),
                prompt: prompt,
                completion: { result in
                    continuation.resume(with: result)
                }
            )
            
            batchQueue.append(item)
            
            if batchQueue.count >= batchSize {
                processBatch()
            }
        }
    }
    
    private func startBatchTimer() {
        Timer.scheduledTimer(withTimeInterval: batchInterval, repeats: true) { _ in
            if !self.batchQueue.isEmpty {
                self.processBatch()
            }
        }
    }
    
    private func processBatch() {
        let currentBatch = batchQueue
        batchQueue.removeAll()
        
        Task {
            await processBatchItems(currentBatch)
        }
    }
    
    private func processBatchItems(_ items: [BatchItem]) async {
        let combinedPrompt = items.map(\.prompt).joined(separator: "\n---\n")
        
        do {
            let stream = session.streamResponse(to: combinedPrompt)
            var response = ""
            
            for try await partial in stream {
                response = partial
            }
            
            let responses = response.components(separatedBy: "\n---\n")
            
            for (index, item) in items.enumerated() {
                let individualResponse = responses.indices.contains(index) ? responses[index] : ""
                item.completion(.success(individualResponse))
            }
        } catch {
            for item in items {
                item.completion(.failure(error))
            }
        }
    }
}
```

## Testing Patterns

### 1. Mock Session Pattern

```swift
protocol SessionProtocol {
    func streamResponse(to prompt: String) -> AsyncThrowingStream<String, Error>
    func streamResponse<T: Generable>(to prompt: String, generating type: T.Type) -> AsyncThrowingStream<T.PartiallyGenerated, Error>
}

extension LanguageModelSession: SessionProtocol {}

class MockSession: SessionProtocol {
    var responses: [String] = []
    var shouldThrow = false
    var throwError: Error = MockError.testError
    
    func streamResponse(to prompt: String) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            if shouldThrow {
                continuation.finish(throwing: throwError)
                return
            }
            
            let response = responses.first ?? "Mock response for: \(prompt)"
            
            Task {
                // Simulate streaming
                let chunks = response.components(separatedBy: " ")
                var accumulated = ""
                
                for chunk in chunks {
                    accumulated += (accumulated.isEmpty ? "" : " ") + chunk
                    continuation.yield(accumulated)
                    try await Task.sleep(nanoseconds: 50_000_000) // 50ms
                }
                
                continuation.finish()
            }
        }
    }
    
    func streamResponse<T: Generable>(to prompt: String, generating type: T.Type) -> AsyncThrowingStream<T.PartiallyGenerated, Error> {
        // Mock implementation for structured content
        AsyncThrowingStream { continuation in
            // Implementation would create mock partial content
            continuation.finish()
        }
    }
}

enum MockError: Error {
    case testError
}
```

### 2. Test Utilities

```swift
class AITestUtilities {
    static func createMockSession(responses: [String] = [], shouldFail: Bool = false) -> MockSession {
        let session = MockSession()
        session.responses = responses
        session.shouldThrow = shouldFail
        return session
    }
    
    static func waitForGeneration<T: Observable>(
        from service: T,
        keyPath: KeyPath<T, Bool>,
        timeout: TimeInterval = 5.0
    ) async throws {
        let startTime = Date()
        
        while service[keyPath: keyPath] {
            if Date().timeIntervalSince(startTime) > timeout {
                throw TestError.timeout
            }
            try await Task.sleep(nanoseconds: 100_000_000) // 100ms
        }
    }
    
    static func expectPartialContent<T: Generable>(
        _ partial: T.PartiallyGenerated,
        toContain properties: [PartialKeyPath<T.PartiallyGenerated>]
    ) -> Bool {
        for property in properties {
            // Check if property is non-nil (simplified)
            if partial[keyPath: property] == nil {
                return false
            }
        }
        return true
    }
}

enum TestError: Error {
    case timeout
    case unexpectedState
}
```

## Security and Privacy Patterns

### 1. Input Sanitization

```swift
struct PromptSanitizer {
    static func sanitize(_ prompt: String) -> String {
        var sanitized = prompt
        
        // Remove potential injection attempts
        sanitized = sanitized.replacingOccurrences(of: "IGNORE PREVIOUS INSTRUCTIONS", with: "")
        sanitized = sanitized.replacingOccurrences(of: "\\n\\n", with: " ")
        
        // Limit length
        if sanitized.count > GenerationLimits.maxPromptLength {
            sanitized = String(sanitized.prefix(GenerationLimits.maxPromptLength))
        }
        
        // Remove sensitive patterns
        sanitized = removeSensitivePatterns(from: sanitized)
        
        return sanitized.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private static func removeSensitivePatterns(from text: String) -> String {
        let patterns = [
            "\\b\\d{4}[\\s-]?\\d{4}[\\s-]?\\d{4}[\\s-]?\\d{4}\\b", // Credit card
            "\\b\\d{3}-\\d{2}-\\d{4}\\b", // SSN
            "\\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Z|a-z]{2,}\\b" // Email
        ]
        
        var sanitized = text
        for pattern in patterns {
            sanitized = sanitized.replacingOccurrences(
                of: pattern,
                with: "[REDACTED]",
                options: .regularExpression
            )
        }
        
        return sanitized
    }
}
```

### 2. Privacy-Aware Configuration

```swift
struct PrivacyManager {
    static func configureSession(_ session: LanguageModelSession, for privacyLevel: PrivacyLevel) {
        switch privacyLevel {
        case .strict:
            session.allowCloudProcessing = false
            session.allowTelemetry = false
            session.dataRetentionDays = 0
            
        case .balanced:
            session.allowCloudProcessing = false
            session.allowTelemetry = true
            session.dataRetentionDays = 1
            
        case .relaxed:
            session.allowCloudProcessing = true
            session.allowTelemetry = true
            session.dataRetentionDays = 7
        }
    }
}

enum PrivacyLevel: CaseIterable {
    case strict
    case balanced
    case relaxed
    
    var description: String {
        switch self {
        case .strict:
            return "Maximum privacy - On-device only"
        case .balanced:
            return "Balanced - Limited data sharing"
        case .relaxed:
            return "Enhanced features - Cloud processing allowed"
        }
    }
}
```

## Migration and Compatibility

### 1. Version-Safe API Usage

```swift
struct VersionCompatibility {
    static func createSession(instructions: String, tools: [Tool] = []) -> LanguageModelSession {
        if #available(iOS 19.1, *) {
            // Use new enhanced initializer
            return LanguageModelSession(tools: tools, configuration: .enhanced) {
                instructions
            }
        } else {
            // Fallback to basic initializer
            return LanguageModelSession(tools: tools) {
                instructions
            }
        }
    }
    
    static func enableAdvancedFeatures(_ session: LanguageModelSession) {
        if #available(iOS 19.2, *) {
            session.enableToolChaining = true
            session.enableAdvancedReasoning = true
        }
    }
}
```

### 2. Feature Detection

```swift
struct FeatureDetection {
    static var supportsToolChaining: Bool {
        if #available(iOS 19.2, *) {
            return true
        }
        return false
    }
    
    static var supportsBackgroundProcessing: Bool {
        if #available(iOS 19.1, *) {
            return true
        }
        return false
    }
    
    static var supportsCloudProcessing: Bool {
        // Check both OS version and entitlements
        guard #available(iOS 19.0, *) else { return false }
        return Bundle.main.object(forInfoDictionaryKey: "com.apple.developer.foundation-models.cloud") != nil
    }
}
```

---

*These patterns represent battle-tested approaches from real-world Foundation Models implementations. Adapt them to your specific use cases and requirements.*