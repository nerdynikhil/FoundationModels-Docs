# @Generable Protocol

## Overview

The `@Generable` protocol is Foundation Models' revolutionary approach to structured content generation. Unlike traditional text-based AI APIs, `@Generable` enables type-safe, compile-time validated AI outputs that integrate seamlessly with Swift's type system.

## Basic Usage

### Simple Generable Struct

```swift
import FoundationModels

@Generable
struct Recipe {
    @Guide(description: "The name of the recipe")
    let name: String
    
    @Guide(description: "A brief description of the dish")
    let description: String
}
```

### Generating Content

```swift
let session = LanguageModelSession(instructions: "You are a recipe assistant")
let stream = session.streamResponse(to: "Create a pasta recipe", generating: Recipe.self)

for try await partialRecipe in stream {
    // partialRecipe is of type Recipe.PartiallyGenerated
    if let name = partialRecipe.name {
        updateUI(recipeName: name)
    }
    if let description = partialRecipe.description {
        updateUI(recipeDescription: description)
    }
}
```

## The @Guide Attribute

The `@Guide` attribute provides instructions to the AI about how to generate specific properties:

### Basic Descriptions

```swift
@Generable
struct BlogPost {
    @Guide(description: "A compelling title that captures the main topic")
    let title: String
    
    @Guide(description: "The main content of the blog post, written in a conversational tone")
    let content: String
    
    @Guide(description: "Tags that categorize this post for discovery")
    let tags: [String]
}
```

### Count Constraints

Control the number of elements in collections:

```swift
@Generable
struct Exam {
    @Guide(description: "The exam title")
    let name: String
    
    @Guide(description: "List of exam questions", .count(5))
    let questions: [Question]
}

@Generable
struct Question {
    @Guide(description: "The question text")
    let text: String
    
    @Guide(description: "Multiple choice answers", .count(4))
    let choices: [Choice]
}
```

### Advanced Guide Options

```swift
@Generable
struct Product {
    @Guide(description: "Product name, keep it under 50 characters")
    let name: String
    
    @Guide(description: "Price in USD, between $10-$1000")
    let price: Double
    
    @Guide(description: "Product categories", .count(3))
    let categories: [String]
    
    @Guide(description: "Availability status - true if in stock")
    let inStock: Bool
}
```

## Complex Structures

### Nested Generable Types

```swift
@Generable
struct TravelItinerary {
    @Guide(description: "Trip title")
    let title: String
    
    @Guide(description: "Trip description")
    let description: String
    
    @Guide(description: "Daily plans for the trip", .count(3))
    let days: [DayPlan]
}

@Generable
struct DayPlan {
    @Guide(description: "Day number (1, 2, 3, etc.)")
    let day: Int
    
    @Guide(description: "Overview of the day's activities")
    let plan: String
    
    @Guide(description: "Specific activities for the day", .count(3))
    let activities: [Activity]
}

@Generable
struct Activity {
    @Guide(description: "Type of activity")
    let type: ActivityType
    
    @Guide(description: "Activity title")
    let title: String
    
    @Guide(description: "Detailed activity description")
    let description: String
}
```

### Generable Enums

```swift
@Generable
enum ActivityType: String {
    case hiking
    case sightseeing
    case dining
    case shopping
    case cultural
    case adventure
}

@Generable
enum SkillLevel: String, CaseIterable {
    case beginner
    case intermediate
    case advanced
    
    var displayName: String {
        switch self {
        case .beginner: return "Beginner"
        case .intermediate: return "Intermediate" 
        case .advanced: return "Advanced"
        }
    }
}
```

## PartiallyGenerated Types

When streaming structured content, Foundation Models provides `PartiallyGenerated` wrapper types:

### Understanding Partial Types

```swift
// Original type
@Generable
struct Article {
    @Guide(description: "Article title")
    let title: String
    
    @Guide(description: "Article content")
    let content: String
    
    @Guide(description: "Publication date")
    let publishDate: Date
}

// During streaming, you receive Article.PartiallyGenerated
let stream = session.streamResponse(to: "Write a tech article", generating: Article.self)

for try await partial in stream {
    // partial is Article.PartiallyGenerated
    
    // Properties are optionals that get populated as generation progresses
    if let title = partial.title {
        print("Title: \(title)")
    }
    
    if let content = partial.content {
        print("Content: \(content)")
    }
    
    // Check if generation is complete
    if partial.isComplete {
        let finalArticle = try partial.finalize()
        // finalArticle is now Article (not PartiallyGenerated)
    }
}
```

### Working with Partial Collections

```swift
@Generable
struct ShoppingList {
    @Guide(description: "Shopping list items", .count(5))
    let items: [Item]
}

let stream = session.streamResponse(to: "Create a grocery list", generating: ShoppingList.self)

for try await partialList in stream {
    if let items = partialList.items {
        print("Current items: \(items.count)")
        
        // Each item in the array is also partial
        for item in items {
            if let name = item.name {
                print("- \(name)")
            }
        }
    }
}
```

## SwiftUI Integration

### Displaying Partial Content

```swift
struct RecipeView: View {
    let recipe: Recipe.PartiallyGenerated
    
    var body: some View {
        VStack(alignment: .leading) {
            // Show title when available
            if let title = recipe.name {
                Text(title)
                    .font(.title)
            } else {
                Text("Generating title...")
                    .font(.title)
                    .redacted(reason: .placeholder)
            }
            
            // Show description when available
            if let description = recipe.description {
                Text(description)
                    .font(.body)
            } else {
                Text("Generating description...")
                    .redacted(reason: .placeholder)
            }
        }
    }
}
```

### Observable Partial State

```swift
@MainActor
@Observable
class RecipeGenerator {
    private(set) var currentRecipe: Recipe.PartiallyGenerated?
    private let session: LanguageModelSession
    
    init() {
        session = LanguageModelSession(instructions: "You are a chef")
    }
    
    func generateRecipe(for ingredients: [String]) async throws {
        let prompt = "Create a recipe using: \(ingredients.joined(separator: ", "))"
        let stream = session.streamResponse(to: prompt, generating: Recipe.self)
        
        for try await partial in stream {
            currentRecipe = partial
        }
    }
}
```

## Advanced Patterns

### Initialized Properties

Properties with default values are excluded from generation:

```swift
@Generable
struct Task {
    // This will NOT be generated (has default value)
    let id = UUID()
    
    // This WILL be generated
    @Guide(description: "Task title")
    let title: String
    
    // This will NOT be generated (computed property)
    var displayTitle: String {
        "Task: \(title)"
    }
}
```

### Optional Properties

```swift
@Generable
struct Event {
    @Guide(description: "Event name")
    let name: String
    
    @Guide(description: "Event description")
    let description: String?
    
    @Guide(description: "Optional venue information")
    let venue: String?
}
```

### Custom Types

```swift
@Generable
struct Coordinate {
    @Guide(description: "Latitude coordinate")
    let latitude: Double
    
    @Guide(description: "Longitude coordinate") 
    let longitude: Double
}

@Generable
struct Location {
    @Guide(description: "Location name")
    let name: String
    
    @Guide(description: "Geographic coordinates")
    let coordinates: Coordinate
}
```

## InstructionsRepresentable Protocol

Provide examples to guide generation:

```swift
extension Recipe: InstructionsRepresentable {
    static var sampleRecipe: Recipe {
        Recipe(
            name: "Classic Spaghetti Carbonara",
            description: "A traditional Italian pasta dish with eggs, cheese, and pancetta"
        )
    }
}

// Use in session instructions
let session = LanguageModelSession {
    "You are a recipe generator."
    "Here's an example of a good recipe:"
    Recipe.sampleRecipe
}
```

## Best Practices

### 1. Clear and Specific Guides

```swift
// ✅ Good: Specific and actionable
@Generable
struct Product {
    @Guide(description: "Product name, maximum 50 characters, should be catchy and descriptive")
    let name: String
    
    @Guide(description: "Price in USD, between $1.00 and $999.99, format as decimal")
    let price: Double
}

// ❌ Bad: Vague descriptions
@Generable
struct Product {
    @Guide(description: "Name")
    let name: String
    
    @Guide(description: "Cost")
    let price: Double
}
```

### 2. Appropriate Collection Sizes

```swift
// ✅ Good: Reasonable count constraints
@Generable
struct Quiz {
    @Guide(description: "Quiz questions", .count(5))
    let questions: [Question]
}

// ❌ Potentially problematic: Too many items
@Generable
struct MassiveQuiz {
    @Guide(description: "Quiz questions", .count(100)) // May be slow/expensive
    let questions: [Question]
}
```

### 3. Proper Type Choices

```swift
// ✅ Good: Appropriate types
@Generable
struct Event {
    @Guide(description: "Event title")
    let title: String
    
    @Guide(description: "Maximum attendees (positive integer)")
    let maxAttendees: Int
    
    @Guide(description: "Is the event free?")
    let isFree: Bool
    
    @Guide(description: "Event categories")
    let categories: [EventCategory] // Enum for type safety
}
```

### 4. Handle Partial States Gracefully

```swift
struct EventView: View {
    let event: Event.PartiallyGenerated
    
    var body: some View {
        VStack {
            Text(event.title ?? "Loading...")
                .font(.title)
                .redacted(reason: event.title == nil ? .placeholder : [])
            
            if let maxAttendees = event.maxAttendees {
                Text("Max attendees: \(maxAttendees)")
            }
            
            if let isFree = event.isFree {
                Label(isFree ? "Free Event" : "Paid Event", 
                      systemImage: isFree ? "gift" : "creditcard")
            }
        }
    }
}
```

## Common Patterns

### Result Builder Style

```swift
@Generable
struct Course {
    @Guide(description: "Course title")
    let title: String
    
    @Guide(description: "Course modules", .count(5))
    let modules: [Module]
}

@Generable  
struct Module {
    @Guide(description: "Module name")
    let name: String
    
    @Guide(description: "Learning objectives", .count(3))
    let objectives: [String]
}
```

### Factory Pattern

```swift
struct GenerableFactory {
    static func createExam(difficulty: SkillLevel) -> LanguageModelSession {
        return LanguageModelSession {
            "You are an exam generator for \(difficulty.rawValue) level."
            "Here's an example exam:"
            Exam.sampleForLevel(difficulty)
        }
    }
}
```

## Migration Guide

### From String-Based to Structured

```swift
// Old approach: Parse text manually
let response = await session.generateText("Create a recipe")
let recipe = try JSONDecoder().decode(Recipe.self, from: response.data(using: .utf8)!)

// New approach: Type-safe generation
let stream = session.streamResponse(to: "Create a recipe", generating: Recipe.self)
for try await recipe in stream {
    // recipe is already typed as Recipe.PartiallyGenerated
}
```

## Next Steps

- Learn about [Guide attributes](./guide-attributes.md) for advanced generation control
- Explore [Tool integration](./tool-protocol.md) with structured types
- Check out [SwiftUI patterns](./swiftui-integration.md) for partial content

---

*Transform your AI outputs from unstructured text to type-safe, streaming data with @Generable!*