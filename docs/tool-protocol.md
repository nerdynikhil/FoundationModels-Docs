# Tool Protocol

## Overview

The `Tool` protocol is Foundation Models' powerful extension system that allows AI to interact with external services, APIs, and device capabilities. Tools transform Foundation Models from a text generator into a capable agent that can perform real-world actions.

## Basic Tool Implementation

### Simple Tool Structure

```swift
import FoundationModels

struct WeatherTool: Tool {
    var name: String = "getWeather"
    var description: String = "Get current weather information for a location"
    
    @Generable
    struct Arguments {
        @Guide(description: "The city name to get weather for")
        let city: String
        
        @Guide(description: "Country code (optional, e.g., 'US', 'UK')")
        let countryCode: String?
    }
    
    func call(arguments: Arguments) async throws -> ToolOutput {
        let weather = try await fetchWeather(city: arguments.city, 
                                           country: arguments.countryCode)
        return ToolOutput("Current weather in \(arguments.city): \(weather.description), \(weather.temperature)°F")
    }
    
    private func fetchWeather(city: String, country: String?) async throws -> WeatherData {
        // Implementation details...
    }
}
```

### Using Tools with Sessions

```swift
let weatherTool = WeatherTool()
let session = LanguageModelSession(tools: [weatherTool]) {
    """
    You are a helpful assistant with access to weather information.
    Use the getWeather tool when users ask about weather conditions.
    Always provide helpful context with the weather data.
    """
}

// The AI can now automatically call the weather tool
let stream = session.streamResponse(to: "What's the weather like in San Francisco?")
for try await response in stream {
    print(response) // "I'll check the weather for you. Current weather in San Francisco: Sunny, 72°F"
}
```

## Advanced Tool Patterns

### MapKit Integration Tool

```swift
import MapKit
import FoundationModels

struct NearbySearchTool: Tool {
    let centerLocation: CLLocationCoordinate2D
    
    var name: String = "findNearbyPlaces"
    var description: String = "Find points of interest near a location"
    
    @Generable
    enum PlaceCategory: String, CaseIterable {
        case restaurant
        case hotel
        case gasStation
        case hospital
        case school
        case shopping
        case entertainment
        
        var mapKitCategory: MKPointOfInterestCategory {
            switch self {
            case .restaurant: return .restaurant
            case .hotel: return .hotel
            case .gasStation: return .gasStation
            case .hospital: return .hospital
            case .school: return .school
            case .shopping: return .store
            case .entertainment: return .movieTheater
            }
        }
    }
    
    @Generable
    struct Arguments {
        @Guide(description: "Type of place to search for")
        let category: PlaceCategory
        
        @Guide(description: "Search query in natural language")
        let query: String
        
        @Guide(description: "Search radius in meters (default: 1000)")
        let radiusMeters: Int?
    }
    
    func call(arguments: Arguments) async throws -> ToolOutput {
        let radius = arguments.radiusMeters ?? 1000
        let places = try await searchNearby(
            category: arguments.category,
            query: arguments.query,
            radius: Double(radius)
        )
        
        let placeNames = places.prefix(5).compactMap { $0.name }
        let result = placeNames.isEmpty 
            ? "No \(arguments.category.rawValue) found nearby"
            : "Found these \(arguments.category.rawValue) options: \(placeNames.formatted())"
            
        return ToolOutput(result)
    }
    
    private func searchNearby(category: PlaceCategory, query: String, radius: Double) async throws -> [MKMapItem] {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.region = MKCoordinateRegion(
            center: centerLocation,
            latitudinalMeters: radius,
            longitudinalMeters: radius
        )
        request.pointOfInterestFilter = .init(including: [category.mapKitCategory])
        
        let search = MKLocalSearch(request: request)
        let response = try await search.start()
        return response.mapItems
    }
}
```

### API Integration Tool

```swift
struct RecipeAPITool: Tool {
    let httpClient: HTTPClient
    
    var name: String = "searchRecipes"
    var description: String = "Search for recipes using an external recipe database"
    
    @Generable
    struct Arguments {
        @Guide(description: "List of ingredients to search with")
        let ingredients: [String]
        
        @Guide(description: "Cuisine type (optional)")
        let cuisine: String?
        
        @Guide(description: "Dietary restrictions (vegetarian, vegan, gluten-free)")
        let dietaryRestrictions: [String]?
    }
    
    nonisolated func call(arguments: Arguments) async throws -> ToolOutput {
        let recipes = try await httpClient.searchRecipes(
            ingredients: arguments.ingredients,
            cuisine: arguments.cuisine,
            dietary: arguments.dietaryRestrictions
        )
        
        let recipeDescriptions = recipes.prefix(3).map { recipe in
            "• \(recipe.name): \(recipe.description) (Cook time: \(recipe.cookTime) min)"
        }.joined(separator: "\n")
        
        return ToolOutput("""
        Found these recipes for your ingredients:
        
        \(recipeDescriptions)
        """)
    }
}
```

### Calculator Tool

```swift
struct CalculatorTool: Tool {
    var name: String = "calculate"
    var description: String = "Perform mathematical calculations"
    
    @Generable
    struct Arguments {
        @Guide(description: "Mathematical expression to evaluate (e.g., '2 + 3 * 4')")
        let expression: String
    }
    
    func call(arguments: Arguments) async throws -> ToolOutput {
        let result = try evaluateExpression(arguments.expression)
        return ToolOutput("The result of \(arguments.expression) is \(result)")
    }
    
    private func evaluateExpression(_ expression: String) throws -> Double {
        let expr = NSExpression(format: expression)
        guard let result = expr.expressionValue(with: nil, context: nil) as? NSNumber else {
            throw CalculatorError.invalidExpression
        }
        return result.doubleValue
    }
}

enum CalculatorError: Error {
    case invalidExpression
}
```

## Tool Integration Patterns

### Conditional Tool Usage

```swift
let session = LanguageModelSession(tools: [weatherTool, calculatorTool]) {
    """
    You are a helpful assistant with access to weather and calculation tools.
    
    Use the weather tool when users ask about:
    - Current weather conditions
    - Temperature in specific cities
    - Weather forecasts
    
    Use the calculator tool when users ask about:
    - Mathematical calculations
    - Number conversions
    - Statistical operations
    
    Always explain what you're doing before using a tool.
    """
}
```

### Tool Chaining

```swift
struct TravelPlannerTool: Tool {
    let nearbySearchTool: NearbySearchTool
    let weatherTool: WeatherTool
    
    var name: String = "planDayTrip"
    var description: String = "Plan a comprehensive day trip including weather and attractions"
    
    @Generable
    struct Arguments {
        @Guide(description: "Destination city")
        let city: String
        
        @Guide(description: "Preferred activities")
        let activities: [String]
    }
    
    func call(arguments: Arguments) async throws -> ToolOutput {
        // Get weather first
        let weatherResult = try await weatherTool.call(
            arguments: WeatherTool.Arguments(city: arguments.city, countryCode: nil)
        )
        
        // Find activities based on weather
        var recommendations: [String] = []
        
        for activity in arguments.activities {
            let searchResult = try await nearbySearchTool.call(
                arguments: NearbySearchTool.Arguments(
                    category: .entertainment,
                    query: activity,
                    radiusMeters: 5000
                )
            )
            recommendations.append(searchResult.content)
        }
        
        return ToolOutput("""
        Day trip plan for \(arguments.city):
        
        Weather: \(weatherResult.content)
        
        Recommended activities:
        \(recommendations.joined(separator: "\n"))
        """)
    }
}
```

### Tool with State Management

```swift
@MainActor
@Observable
class ShoppingListTool: Tool {
    private(set) var items: [String] = []
    
    var name: String = "manageShoppingList"
    var description: String = "Add, remove, or view items in the shopping list"
    
    @Generable
    enum Action: String {
        case add
        case remove
        case view
        case clear
    }
    
    @Generable
    struct Arguments {
        @Guide(description: "Action to perform on the shopping list")
        let action: Action
        
        @Guide(description: "Item name (required for add/remove actions)")
        let itemName: String?
    }
    
    nonisolated func call(arguments: Arguments) async throws -> ToolOutput {
        await MainActor.run {
            handleAction(arguments)
        }
    }
    
    private func handleAction(_ arguments: Arguments) -> ToolOutput {
        switch arguments.action {
        case .add:
            guard let item = arguments.itemName else {
                return ToolOutput("Error: Item name required for adding")
            }
            items.append(item)
            return ToolOutput("Added '\(item)' to shopping list")
            
        case .remove:
            guard let item = arguments.itemName else {
                return ToolOutput("Error: Item name required for removal")
            }
            items.removeAll { $0 == item }
            return ToolOutput("Removed '\(item)' from shopping list")
            
        case .view:
            let list = items.isEmpty ? "Shopping list is empty" : items.joined(separator: "\n• ")
            return ToolOutput("Shopping list:\n• \(list)")
            
        case .clear:
            items.removeAll()
            return ToolOutput("Shopping list cleared")
        }
    }
}
```

## Error Handling

### Robust Tool Error Handling

```swift
struct NetworkTool: Tool {
    var name: String = "fetchData"
    var description: String = "Fetch data from external APIs"
    
    @Generable
    struct Arguments {
        @Guide(description: "URL to fetch data from")
        let url: String
    }
    
    func call(arguments: Arguments) async throws -> ToolOutput {
        do {
            guard let url = URL(string: arguments.url) else {
                return ToolOutput("Error: Invalid URL format")
            }
            
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                return ToolOutput("Error: Invalid response type")
            }
            
            switch httpResponse.statusCode {
            case 200...299:
                let content = String(data: data, encoding: .utf8) ?? "No content"
                return ToolOutput("Successfully fetched data: \(content.prefix(200))...")
                
            case 400...499:
                return ToolOutput("Error: Client error (\(httpResponse.statusCode))")
                
            case 500...599:
                return ToolOutput("Error: Server error (\(httpResponse.statusCode))")
                
            default:
                return ToolOutput("Error: Unexpected status code \(httpResponse.statusCode)")
            }
            
        } catch {
            return ToolOutput("Error: Network request failed - \(error.localizedDescription)")
        }
    }
}
```

### Tool Validation

```swift
struct EmailTool: Tool {
    var name: String = "sendEmail"
    var description: String = "Send email messages"
    
    @Generable
    struct Arguments {
        @Guide(description: "Recipient email address")
        let to: String
        
        @Guide(description: "Email subject line")
        let subject: String
        
        @Guide(description: "Email body content")
        let body: String
    }
    
    func call(arguments: Arguments) async throws -> ToolOutput {
        // Validate email format
        guard isValidEmail(arguments.to) else {
            return ToolOutput("Error: Invalid email address format")
        }
        
        // Validate content
        guard !arguments.subject.isEmpty && !arguments.body.isEmpty else {
            return ToolOutput("Error: Subject and body cannot be empty")
        }
        
        do {
            try await sendEmail(
                to: arguments.to,
                subject: arguments.subject,
                body: arguments.body
            )
            return ToolOutput("Email sent successfully to \(arguments.to)")
        } catch {
            return ToolOutput("Failed to send email: \(error.localizedDescription)")
        }
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
}
```

## Best Practices

### 1. Clear Tool Descriptions

```swift
// ✅ Good: Clear and specific
struct FileTool: Tool {
    var name: String = "readFile"
    var description: String = "Read content from text files in the user's document directory. Supports .txt, .md, and .json formats."
}

// ❌ Bad: Vague description
struct FileTool: Tool {
    var name: String = "readFile"  
    var description: String = "Read files"
}
```

### 2. Comprehensive Argument Validation

```swift
@Generable
struct FileArguments {
    @Guide(description: "File path relative to documents directory (e.g., 'notes/todo.txt')")
    let filePath: String
    
    @Guide(description: "Maximum file size to read in KB (default: 100, max: 1000)")
    let maxSizeKB: Int?
}

func call(arguments: FileArguments) async throws -> ToolOutput {
    let maxSize = min(arguments.maxSizeKB ?? 100, 1000) * 1024
    
    guard !arguments.filePath.contains("..") else {
        return ToolOutput("Error: Invalid file path")
    }
    
    // Continue with validated arguments...
}
```

### 3. Meaningful Tool Output

```swift
// ✅ Good: Structured, informative output
func call(arguments: Arguments) async throws -> ToolOutput {
    let results = try await performSearch(arguments.query)
    
    if results.isEmpty {
        return ToolOutput("No results found for '\(arguments.query)'. Try a different search term.")
    }
    
    let summary = """
    Found \(results.count) results for '\(arguments.query)':
    
    \(results.map { "• \($0.title): \($0.summary)" }.joined(separator: "\n"))
    """
    
    return ToolOutput(summary)
}

// ❌ Bad: Minimal, unhelpful output
func call(arguments: Arguments) async throws -> ToolOutput {
    let results = try await performSearch(arguments.query)
    return ToolOutput(results.isEmpty ? "No results" : "Found results")
}
```

### 4. Async-Safe Tool Implementation

```swift
struct DatabaseTool: Tool {
    private let database: DatabaseManager
    
    var name: String = "queryDatabase"
    var description: String = "Query the application database"
    
    @Generable
    struct Arguments {
        @Guide(description: "SQL query to execute")
        let query: String
    }
    
    // Use nonisolated for thread-safe tools
    nonisolated func call(arguments: Arguments) async throws -> ToolOutput {
        do {
            let results = try await database.execute(query: arguments.query)
            return ToolOutput("Query executed successfully. Found \(results.count) rows.")
        } catch {
            return ToolOutput("Database error: \(error.localizedDescription)")
        }
    }
}
```

## Common Tool Patterns

### Factory Pattern for Tool Creation

```swift
struct ToolFactory {
    static func createLocationTools(for location: CLLocationCoordinate2D) -> [Tool] {
        let nearbyTool = NearbySearchTool(centerLocation: location)
        let weatherTool = WeatherTool()
        let trafficTool = TrafficTool(location: location)
        
        return [nearbyTool, weatherTool, trafficTool]
    }
    
    static func createProductivityTools() -> [Tool] {
        let calculatorTool = CalculatorTool()
        let calendarTool = CalendarTool()
        let reminderTool = ReminderTool()
        
        return [calculatorTool, calendarTool, reminderTool]
    }
}
```

### Protocol-Based Tool Configuration

```swift
protocol ConfigurableTool: Tool {
    associatedtype Configuration
    init(configuration: Configuration)
}

struct APITool: ConfigurableTool {
    struct Configuration {
        let baseURL: URL
        let apiKey: String
        let timeout: TimeInterval
    }
    
    private let config: Configuration
    
    init(configuration: Configuration) {
        self.config = configuration
    }
    
    var name: String = "apiRequest"
    var description: String = "Make requests to external APIs"
    
    // Implementation...
}
```

## Testing Tools

### Unit Testing Tool Logic

```swift
@testable import MyApp
import XCTest

class CalculatorToolTests: XCTestCase {
    var tool: CalculatorTool!
    
    override func setUp() {
        super.setUp()
        tool = CalculatorTool()
    }
    
    func testBasicCalculation() async throws {
        let arguments = CalculatorTool.Arguments(expression: "2 + 3")
        let result = try await tool.call(arguments: arguments)
        
        XCTAssertEqual(result.content, "The result of 2 + 3 is 5.0")
    }
    
    func testInvalidExpression() async throws {
        let arguments = CalculatorTool.Arguments(expression: "invalid")
        let result = try await tool.call(arguments: arguments)
        
        XCTAssertTrue(result.content.contains("Error"))
    }
}
```

### Mock Tools for Testing

```swift
struct MockWeatherTool: Tool {
    var name: String = "getWeather"
    var description: String = "Mock weather tool for testing"
    
    @Generable
    struct Arguments {
        @Guide(description: "City name")
        let city: String
    }
    
    func call(arguments: Arguments) async throws -> ToolOutput {
        return ToolOutput("Mock weather for \(arguments.city): Sunny, 75°F")
    }
}
```

## Migration from Beta

### Tool Protocol Changes

```swift
// Old API (Beta)
struct OldTool: Tool {
    func execute(with arguments: [String: Any]) async throws -> String {
        // Manual argument parsing
    }
}

// New API (Release)
struct NewTool: Tool {
    @Generable
    struct Arguments {
        @Guide(description: "Parameter description")
        let parameter: String
    }
    
    func call(arguments: Arguments) async throws -> ToolOutput {
        // Type-safe arguments
    }
}
```

## Next Steps

- Learn about [Tool Integration Patterns](./tool-integration-patterns.md)
- Explore [SwiftUI integration](./swiftui-integration.md) with tools
- Check out [practical examples](./examples/) using tools

---

*Extend your AI's capabilities beyond text generation with the powerful Tool protocol!*