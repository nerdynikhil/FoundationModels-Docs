# Travel Planning Example

## Overview

Build an AI-powered travel planning application using Foundation Models' tool integration and structured generation. This example demonstrates how to combine external APIs, location services, and AI reasoning to create comprehensive travel itineraries.

## Complete Implementation

### 1. Data Models

```swift
//  Itinerary.swift
import Foundation
import FoundationModels

@Generable
struct Itinerary: Equatable {
    
    @Guide(description: "A descriptive title for the itinerary, such as the destination or theme of the trip.")
    let title: String
    
    @Guide(description: "A general description providing context, tone, or highlights of the trip.")
    let description: String
    
    @Guide(description: "Detailed plan for each day of the itinerary, including the day number and a description of planned activities.", .count(3))
    var days: [DayPlan]
    
    @Guide(description: "This will serve as the summary of the 3-day travel itinerary.")
    var summary: String
}

@Generable
struct DayPlan: Equatable {
    @Guide(description: "The day number within the itinerary (e.g., 1 for Day 1).")
    let day: Int
    
    @Guide(description: "A detailed description of the planned activities, locations, and experiences for this day.")
    let plan: String
    
    @Guide(description: "List of specific activities for this day", .count(3))
    let activities: [Activity]
}

@Generable
struct Activity: Equatable {
    
    @Guide(description: "The category or kind of the activity, such as hiking or camping.")
    let type: ActivityKind
    
    @Guide(description: "A short, descriptive title for the activity, like 'Sunset Hike at Canyon Trail'.")
    let title: String
    
    @Guide(description: "A detailed description of the activity, including what to expect and any important notes.")
    let description: String
    
    @Guide(description: "Estimated duration in minutes")
    let durationMinutes: Int?
    
    @Guide(description: "Best time of day for this activity")
    let timeOfDay: String?
}

@Generable
enum ActivityKind: String, Equatable, CaseIterable {
    case hiking
    case camping
    case wildlifeViewing
    case scenicDrive
    case photography
    case sightseeing
    case nature
    case walking
    case dining
    case shopping
    case cultural
    case adventure
    case relaxation
}
```

### 2. Park Data Model

```swift
//  Park.swift
import Foundation
import CoreLocation

struct Park: Identifiable, Codable {
    let id: UUID
    let name: String
    let description: String
    let location: CLLocationCoordinate2D
    let state: String
    let area: String
    let activities: [String]
    let imageURL: String?
    
    enum CodingKeys: String, CodingKey {
        case id, name, description, state, area, activities, imageURL
        case latitude, longitude
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decode(String.self, forKey: .description)
        state = try container.decode(String.self, forKey: .state)
        area = try container.decode(String.self, forKey: .area)
        activities = try container.decode([String].self, forKey: .activities)
        imageURL = try container.decodeIfPresent(String.self, forKey: .imageURL)
        
        let latitude = try container.decode(Double.self, forKey: .latitude)
        let longitude = try container.decode(Double.self, forKey: .longitude)
        location = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(description, forKey: .description)
        try container.encode(state, forKey: .state)
        try container.encode(area, forKey: .area)
        try container.encode(activities, forKey: .activities)
        try container.encodeIfPresent(imageURL, forKey: .imageURL)
        try container.encode(location.latitude, forKey: .latitude)
        try container.encode(location.longitude, forKey: .longitude)
    }
}

// Sample park data
extension Park {
    static let sampleParks = [
        Park(
            id: UUID(),
            name: "Yellowstone National Park",
            description: "America's first national park, famous for geysers, hot springs, and diverse wildlife including bison, wolves, and bears.",
            location: CLLocationCoordinate2D(latitude: 44.4280, longitude: -110.5885),
            state: "Wyoming",
            area: "2,221,766 acres",
            activities: ["Hiking", "Wildlife Viewing", "Photography", "Camping", "Fishing"],
            imageURL: "yellowstone.jpg"
        ),
        Park(
            id: UUID(),
            name: "Grand Canyon National Park",
            description: "One of the world's most famous natural wonders, offering breathtaking views and geological history spanning millions of years.",
            location: CLLocationCoordinate2D(latitude: 36.1069, longitude: -112.1129),
            state: "Arizona",
            area: "1,217,262 acres",
            activities: ["Hiking", "Photography", "Scenic Viewing", "Rafting", "Stargazing"],
            imageURL: "grandcanyon.jpg"
        )
    ]
}
```

### 3. Points of Interest Tool

```swift
//  NearbyPointsOfInterestTool.swift
import Foundation
import FoundationModels
import MapKit

struct FindNearbyPointsOfInterestTool: Tool {
    
    let park: Park
    
    var name: String = "findNearbyPointsOfInterest"
    var description: String = "Find points of interest near a national park including hotels, restaurants, trails, and visitor centers."
    
    @Generable
    enum Category: String, CaseIterable {
        case hotel
        case restaurant
        case trail
        case campground
        case visitorCenter
        case viewpoint
        case picnicArea
        case museum
        case parking
        case rangerStation
        case gasStation
        case grocery
        
        func toMapKitCategories() -> [MKPointOfInterestCategory] {
            switch self {
            case .hotel:
                return [.hotel]
            case .restaurant:
                return [.restaurant, .cafe]
            case .trail:
                return [.park]
            case .campground:
                return [.campground]
            case .visitorCenter:
                return [.museum]
            case .viewpoint:
                return [.nationalPark]
            case .picnicArea:
                return [.park]
            case .museum:
                return [.museum]
            case .parking:
                return [.parking]
            case .rangerStation:
                return [.publicTransport]
            case .gasStation:
                return [.gasStation]
            case .grocery:
                return [.store]
            }
        }
        
        var displayName: String {
            switch self {
            case .hotel: return "Hotels"
            case .restaurant: return "Restaurants"
            case .trail: return "Trails"
            case .campground: return "Campgrounds"
            case .visitorCenter: return "Visitor Centers"
            case .viewpoint: return "Viewpoints"
            case .picnicArea: return "Picnic Areas"
            case .museum: return "Museums"
            case .parking: return "Parking"
            case .rangerStation: return "Ranger Stations"
            case .gasStation: return "Gas Stations"
            case .grocery: return "Grocery Stores"
            }
        }
    }
    
    @Generable
    struct Arguments {
        
        @Guide(description: "This is the type of destination to look for.")
        let pointOfInterestCategory: Category
        
        @Guide(description: "The natural language query of what to search for.")
        let naturalLanguageQuery: String
        
        @Guide(description: "Maximum number of results to return (default: 5)")
        let maxResults: Int?
    }
    
    func call(arguments: Arguments) async throws -> ToolOutput {
        
        let items = try await findPointOfInterests(location: park.location, arguments: arguments)
        let maxResults = arguments.maxResults ?? 5
        let results = items.prefix(maxResults).compactMap { item in
            var info = item.name ?? "Unknown"
            if let address = item.placemark.title {
                info += " - \(address)"
            }
            if let phone = item.phoneNumber {
                info += " - \(phone)"
            }
            return info
        }
        
        print("Found \(results.count) \(arguments.pointOfInterestCategory.displayName.lowercased()) near \(park.name)")
        
        let formattedResults = results.isEmpty 
            ? "No \(arguments.pointOfInterestCategory.displayName.lowercased()) found near \(park.name)"
            : "Found these \(arguments.pointOfInterestCategory.displayName.lowercased()) near \(park.name):\n" + results.map { "• \($0)" }.joined(separator: "\n")
            
        return ToolOutput(formattedResults)
    }
    
    private func findPointOfInterests(location: CLLocationCoordinate2D, arguments: Arguments) async throws -> [MKMapItem] {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = arguments.naturalLanguageQuery
        request.region = MKCoordinateRegion(
            center: location, 
            latitudinalMeters: 50_000, // 50km radius
            longitudinalMeters: 50_000
        )
        
        let categories = arguments.pointOfInterestCategory.toMapKitCategories()
        request.pointOfInterestFilter = .init(including: categories)
        
        let search = MKLocalSearch(request: request)
        let response = try await search.start()
        return response.mapItems
    }
}
```

### 4. Weather Tool

```swift
//  WeatherTool.swift
import Foundation
import FoundationModels
import CoreLocation

struct WeatherTool: Tool {
    
    var name: String = "getWeather"
    var description: String = "Get current weather conditions and forecast for a location"
    
    @Generable
    struct Arguments {
        @Guide(description: "The location name to get weather for")
        let location: String
        
        @Guide(description: "Whether to include forecast (true) or just current conditions (false)")
        let includeForecast: Bool?
    }
    
    func call(arguments: Arguments) async throws -> ToolOutput {
        // In a real implementation, you'd call a weather API
        // For this example, we'll simulate weather data
        
        let includesForecast = arguments.includeForecast ?? false
        let weather = generateSimulatedWeather(for: arguments.location, includeForecast: includesForecast)
        
        return ToolOutput(weather)
    }
    
    private func generateSimulatedWeather(for location: String, includeForecast: Bool) -> String {
        let conditions = ["Sunny", "Partly Cloudy", "Cloudy", "Light Rain", "Clear"]
        let temps = [65, 72, 68, 71, 75, 69, 73]
        
        let currentCondition = conditions.randomElement() ?? "Sunny"
        let currentTemp = temps.randomElement() ?? 70
        
        var weather = "Current weather in \(location):\n"
        weather += "• Condition: \(currentCondition)\n"
        weather += "• Temperature: \(currentTemp)°F\n"
        weather += "• Humidity: \(Int.random(in: 30...80))%\n"
        weather += "• Wind: \(Int.random(in: 3...15)) mph"
        
        if includeForecast {
            weather += "\n\n3-Day Forecast:\n"
            for i in 1...3 {
                let dayCondition = conditions.randomElement() ?? "Sunny"
                let dayTemp = temps.randomElement() ?? 70
                weather += "• Day \(i): \(dayCondition), \(dayTemp)°F\n"
            }
        }
        
        return weather
    }
}
```

### 5. Itinerary Planner Service

```swift
//  ItineraryPlanner.swift
import Foundation
import Observation
import FoundationModels

@MainActor
@Observable
final class ItineraryPlanner {
    
    private(set) var itinerary: Itinerary.PartiallyGenerated?
    private(set) var isPlanning: Bool = false
    private(set) var error: PlanningError?
    
    var session: LanguageModelSession
    let park: Park
    
    enum PlanningError: LocalizedError {
        case invalidPark
        case planningFailed(Error)
        case noResults
        
        var errorDescription: String? {
            switch self {
            case .invalidPark:
                return "Invalid park selection"
            case .planningFailed(let error):
                return "Planning failed: \(error.localizedDescription)"
            case .noResults:
                return "No itinerary could be generated"
            }
        }
    }
    
    init(park: Park) {
        self.park = park
        
        let pointOfInterestsTool = FindNearbyPointsOfInterestTool(park: park)
        let weatherTool = WeatherTool()
        
        self.session = LanguageModelSession(tools: [pointOfInterestsTool, weatherTool]) {
            """
            You are a helpful travel assistant. Your task is to create personalized 
            and informative travel itineraries based on the user's preferences and inputs. 
            Provide clear, concise, and friendly suggestions.
            """
            
            """
            Use the findNearbyPointsOfInterest tool to find various businesses and 
            activities near \(park.name). Use the getWeather tool to check current 
            conditions and plan accordingly.
            """
            
            """
            Here is a description for \(park.name) for your reference:
            \(park.description)
            
            Available activities: \(park.activities.joined(separator: ", "))
            Location: \(park.state)
            """
            
            "Here is an example of a well-structured itinerary:"
            Itinerary.exampleTripToNationalPark
        }
    }
    
    func suggestItinerary(preferences: TravelPreferences = .default) async {
        isPlanning = true
        error = nil
        itinerary = nil
        
        do {
            let prompt = createPrompt(for: preferences)
            let stream = session.streamResponse(to: prompt, generating: Itinerary.self)
            
            for try await partial in stream {
                self.itinerary = partial
            }
            
            if itinerary == nil {
                error = .noResults
            }
        } catch {
            self.error = .planningFailed(error)
        }
        
        isPlanning = false
    }
    
    private func createPrompt(for preferences: TravelPreferences) -> String {
        var prompt = """
        Create a \(preferences.duration)-day travel itinerary for \(park.name), 
        including daily activities, suggested times, and brief descriptions of each stop. 
        Make it engaging and suitable for \(preferences.experienceLevel.rawValue) visitors.
        """
        
        if !preferences.interests.isEmpty {
            prompt += "\n\nFocus on these interests: \(preferences.interests.joined(separator: ", "))"
        }
        
        if let groupSize = preferences.groupSize {
            prompt += "\n\nThis itinerary is for a group of \(groupSize) people."
        }
        
        if !preferences.accessibility.isEmpty {
            prompt += "\n\nAccessibility considerations: \(preferences.accessibility.joined(separator: ", "))"
        }
        
        return prompt
    }
}

struct TravelPreferences {
    let duration: Int
    let experienceLevel: ExperienceLevel
    let interests: [String]
    let groupSize: Int?
    let accessibility: [String]
    
    enum ExperienceLevel: String, CaseIterable {
        case firstTime = "first-time"
        case experienced = "experienced"
        case expert = "expert"
        
        var displayName: String {
            switch self {
            case .firstTime: return "First-time Visitor"
            case .experienced: return "Experienced Traveler"
            case .expert: return "Expert Explorer"
            }
        }
    }
    
    static let `default` = TravelPreferences(
        duration: 3,
        experienceLevel: .firstTime,
        interests: [],
        groupSize: nil,
        accessibility: []
    )
}
```

### 6. Sample Itinerary Data

```swift
extension Itinerary: InstructionsRepresentable {
    
    static var exampleTripToNationalPark: Itinerary {
        Itinerary(
            title: "Adventure Through Yellowstone National Park",
            description: "Discover the geothermal wonders, scenic hikes, and wildlife of America's first national park on this immersive 3-day journey.",
            days: [
                DayPlan(
                    day: 1,
                    plan: "Arrive at Yellowstone and explore the famous geysers and hot springs in the park's western region.",
                    activities: [
                        Activity(
                            type: .sightseeing,
                            title: "Old Faithful Geyser",
                            description: "Watch one of the most predictable geothermal features in the world erupt approximately every 90 minutes.",
                            durationMinutes: 60,
                            timeOfDay: "Morning"
                        ),
                        Activity(
                            type: .nature,
                            title: "Grand Prismatic Spring",
                            description: "Marvel at the vibrant colors of this enormous hot spring, best viewed from the overlook trail.",
                            durationMinutes: 90,
                            timeOfDay: "Afternoon"
                        ),
                        Activity(
                            type: .walking,
                            title: "Fountain Paint Pot Trail",
                            description: "Stroll past mud pots, fumaroles, and geysers on this short, accessible boardwalk trail.",
                            durationMinutes: 45,
                            timeOfDay: "Evening"
                        )
                    ]
                ),
                DayPlan(
                    day: 2,
                    plan: "Hike through scenic landscapes and keep an eye out for bison and other wildlife.",
                    activities: [
                        Activity(
                            type: .hiking,
                            title: "Lamar Valley",
                            description: "Go on an early morning hike for a chance to see wolves, bears, and herds of bison in this wildlife-rich valley.",
                            durationMinutes: 180,
                            timeOfDay: "Early Morning"
                        ),
                        Activity(
                            type: .nature,
                            title: "Yellowstone Lake Picnic",
                            description: "Enjoy a relaxing picnic by the shores of Yellowstone Lake with stunning mountain views.",
                            durationMinutes: 120,
                            timeOfDay: "Afternoon"
                        ),
                        Activity(
                            type: .camping,
                            title: "Campfire Evening",
                            description: "Wrap up the day with a cozy campfire, s'mores, and storytelling under the stars.",
                            durationMinutes: 120,
                            timeOfDay: "Evening"
                        )
                    ]
                ),
                DayPlan(
                    day: 3,
                    plan: "Visit the dramatic canyons and waterfalls before heading home.",
                    activities: [
                        Activity(
                            type: .sightseeing,
                            title: "Grand Canyon of the Yellowstone",
                            description: "Hike to Artist Point for breathtaking views of the colorful canyon and Lower Falls.",
                            durationMinutes: 120,
                            timeOfDay: "Morning"
                        ),
                        Activity(
                            type: .photography,
                            title: "Upper Falls Viewpoint",
                            description: "Capture the power and beauty of the Upper Falls from the overlook trail.",
                            durationMinutes: 60,
                            timeOfDay: "Afternoon"
                        ),
                        Activity(
                            type: .walking,
                            title: "Geyser Basin Drive",
                            description: "Take a leisurely drive with stops at various basins to say goodbye to the park's geothermal wonders.",
                            durationMinutes: 90,
                            timeOfDay: "Late Afternoon"
                        )
                    ]
                )
            ],
            summary: "This 3-day Yellowstone adventure blends hiking, wildlife spotting, geothermal exploration, and quiet moments in nature—perfect for outdoor lovers and first-time visitors alike."
        )
    }
}
```

### 7. User Interface Components

```swift
//  ParkSelectionView.swift
import SwiftUI

struct ParkSelectionView: View {
    let parks: [Park]
    let onParkSelected: (Park) -> Void
    
    var body: some View {
        NavigationView {
            List(parks) { park in
                ParkRowView(park: park) {
                    onParkSelected(park)
                }
            }
            .navigationTitle("Choose Your Destination")
        }
    }
}

struct ParkRowView: View {
    let park: Park
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(park.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text(park.state)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                }
                
                Text(park.description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
                
                HStack {
                    Label(park.area, systemImage: "map")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        ForEach(park.activities.prefix(3), id: \\.self) { activity in
                            Text(activity)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.green.opacity(0.1))
                                .cornerRadius(4)
                        }
                        
                        if park.activities.count > 3 {
                            Text("+\(park.activities.count - 3)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}
```

```swift
//  TravelPreferencesView.swift
import SwiftUI

struct TravelPreferencesView: View {
    @Binding var preferences: TravelPreferences
    let onContinue: () -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section("Trip Duration") {
                    Stepper(value: $preferences.duration, in: 1...7) {
                        Text("\(preferences.duration) day\(preferences.duration == 1 ? "" : "s")")
                    }
                }
                
                Section("Experience Level") {
                    Picker("Experience", selection: $preferences.experienceLevel) {
                        ForEach(TravelPreferences.ExperienceLevel.allCases, id: \\.self) { level in
                            Text(level.displayName).tag(level)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section("Interests") {
                    InterestSelectionView(selectedInterests: $preferences.interests)
                }
                
                Section("Group Size") {
                    HStack {
                        Text("Number of travelers")
                        Spacer()
                        TextField("Optional", value: $preferences.groupSize, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 80)
                    }
                }
                
                Section("Accessibility") {
                    AccessibilitySelectionView(selectedOptions: $preferences.accessibility)
                }
            }
            .navigationTitle("Travel Preferences")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Continue", action: onContinue)
                        .buttonStyle(.borderedProminent)
                }
            }
        }
    }
}

struct InterestSelectionView: View {
    @Binding var selectedInterests: [String]
    
    private let availableInterests = [
        "Wildlife Viewing", "Photography", "Hiking", "Scenic Drives",
        "Cultural Sites", "Adventure Sports", "Relaxation", "Stargazing",
        "Water Activities", "Camping", "Educational Tours", "Family Fun"
    ]
    
    var body: some View {
        LazyVGrid(columns: [
            GridItem(.adaptive(minimum: 120))
        ], spacing: 8) {
            ForEach(availableInterests, id: \\.self) { interest in
                InterestTag(
                    title: interest,
                    isSelected: selectedInterests.contains(interest)
                ) {
                    if selectedInterests.contains(interest) {
                        selectedInterests.removeAll { $0 == interest }
                    } else {
                        selectedInterests.append(interest)
                    }
                }
            }
        }
    }
}

struct InterestTag: View {
    let title: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Text(title)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.blue : Color.gray.opacity(0.2))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(16)
        }
        .buttonStyle(.plain)
    }
}

struct AccessibilitySelectionView: View {
    @Binding var selectedOptions: [String]
    
    private let accessibilityOptions = [
        "Wheelchair accessible", "Limited mobility", "Visual impairments",
        "Hearing impairments", "Family with young children", "Pet-friendly"
    ]
    
    var body: some View {
        ForEach(accessibilityOptions, id: \\.self) { option in
            HStack {
                Button(action: {
                    if selectedOptions.contains(option) {
                        selectedOptions.removeAll { $0 == option }
                    } else {
                        selectedOptions.append(option)
                    }
                }) {
                    Image(systemName: selectedOptions.contains(option) ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(selectedOptions.contains(option) ? .blue : .gray)
                }
                
                Text(option)
                    .font(.body)
                
                Spacer()
            }
        }
    }
}
```

```swift
//  ItineraryView.swift
import SwiftUI
import FoundationModels

struct ItineraryView: View {
    let itinerary: Itinerary.PartiallyGenerated
    
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 12) {
                    if let title = itinerary.title {
                        Text(title)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                    } else {
                        Text("Generating itinerary title...")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .redacted(reason: .placeholder)
                    }
                    
                    if let description = itinerary.description {
                        Text(description)
                            .font(.body)
                            .foregroundColor(.secondary)
                    } else {
                        Text("Generating description...")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .redacted(reason: .placeholder)
                    }
                }
                .padding(.horizontal)
                
                Divider()
                
                // Days
                if let days = itinerary.days {
                    ForEach(days.indices, id: \\.self) { index in
                        DayView(dayPlan: days[index], isFirst: index == 0)
                    }
                } else {
                    ForEach(0..<3, id: \\.self) { index in
                        PlaceholderDayView(dayNumber: index + 1)
                    }
                }
                
                // Summary
                if let summary = itinerary.summary {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Trip Summary")
                            .font(.headline)
                        
                        Text(summary)
                            .font(.body)
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
}

struct DayView: View {
    let dayPlan: DayPlan.PartiallyGenerated
    let isFirst: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Day Header
            HStack {
                if let day = dayPlan.day {
                    Text("Day \(day)")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                } else {
                    Text("Day -")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                        .redacted(reason: .placeholder)
                }
                
                Spacer()
            }
            
            // Day Plan
            if let plan = dayPlan.plan {
                Text(plan)
                    .font(.body)
                    .foregroundColor(.secondary)
            } else {
                Text("Generating day plan...")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .redacted(reason: .placeholder)
            }
            
            // Activities
            if let activities = dayPlan.activities {
                LazyVStack(spacing: 12) {
                    ForEach(activities.indices, id: \\.self) { index in
                        ActivityView(activity: activities[index])
                    }
                }
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(0..<3, id: \\.self) { _ in
                        PlaceholderActivityView()
                    }
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, isFirst ? 0 : 12)
    }
}

struct ActivityView: View {
    let activity: Activity.PartiallyGenerated
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Activity Type Icon
            if let type = activity.type {
                Image(systemName: iconForActivityType(type))
                    .font(.title3)
                    .foregroundColor(.blue)
                    .frame(width: 24, height: 24)
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 24, height: 24)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                // Title
                if let title = activity.title {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                } else {
                    Text("Loading activity...")
                        .font(.headline)
                        .redacted(reason: .placeholder)
                }
                
                // Description
                if let description = activity.description {
                    Text(description)
                        .font(.body)
                        .foregroundColor(.secondary)
                } else {
                    Text("Loading description...")
                        .font(.body)
                        .redacted(reason: .placeholder)
                }
                
                // Metadata
                HStack {
                    if let duration = activity.durationMinutes {
                        Label("\(duration) min", systemImage: "clock")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if let timeOfDay = activity.timeOfDay {
                        Label(timeOfDay, systemImage: "sun.max")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
    
    private func iconForActivityType(_ type: ActivityKind) -> String {
        switch type {
        case .hiking: return "figure.hiking"
        case .camping: return "tent"
        case .wildlifeViewing: return "binoculars"
        case .scenicDrive: return "car"
        case .photography: return "camera"
        case .sightseeing: return "eye"
        case .nature: return "leaf"
        case .walking: return "figure.walk"
        case .dining: return "fork.knife"
        case .shopping: return "bag"
        case .cultural: return "building.columns"
        case .adventure: return "mountain.2"
        case .relaxation: return "spa"
        }
    }
}

struct PlaceholderActivityView: View {
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Loading activity...")
                    .font(.headline)
                    .redacted(reason: .placeholder)
                
                Text("Loading description...")
                    .font(.body)
                    .redacted(reason: .placeholder)
            }
            
            Spacer()
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
}

struct PlaceholderDayView: View {
    let dayNumber: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Day \(dayNumber)")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.blue)
            
            Text("Generating day plan...")
                .font(.body)
                .foregroundColor(.secondary)
                .redacted(reason: .placeholder)
            
            LazyVStack(spacing: 12) {
                ForEach(0..<3, id: \\.self) { _ in
                    PlaceholderActivityView()
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
    }
}
```

### 8. Main Travel Planning Screen

```swift
//  TravelPlanningView.swift
import SwiftUI

struct TravelPlanningView: View {
    @State private var selectedPark: Park?
    @State private var preferences = TravelPreferences.default
    @State private var itineraryPlanner: ItineraryPlanner?
    @State private var currentStep: PlanningStep = .selectPark
    
    enum PlanningStep {
        case selectPark
        case setPreferences
        case generateItinerary
        case viewItinerary
    }
    
    var body: some View {
        NavigationView {
            Group {
                switch currentStep {
                case .selectPark:
                    ParkSelectionView(parks: Park.sampleParks) { park in
                        selectedPark = park
                        currentStep = .setPreferences
                    }
                    
                case .setPreferences:
                    TravelPreferencesView(preferences: $preferences) {
                        currentStep = .generateItinerary
                        generateItinerary()
                    }
                    
                case .generateItinerary:
                    GeneratingItineraryView()
                    
                case .viewItinerary:
                    if let planner = itineraryPlanner,
                       let itinerary = planner.itinerary {
                        ItineraryView(itinerary: itinerary)
                            .toolbar {
                                ToolbarItem(placement: .navigationBarTrailing) {
                                    Button("Start Over") {
                                        resetPlanning()
                                    }
                                }
                            }
                    }
                }
            }
        }
    }
    
    private func generateItinerary() {
        guard let park = selectedPark else { return }
        
        itineraryPlanner = ItineraryPlanner(park: park)
        
        Task {
            await itineraryPlanner?.suggestItinerary(preferences: preferences)
            
            if itineraryPlanner?.error == nil {
                currentStep = .viewItinerary
            } else {
                // Handle error
                currentStep = .selectPark
            }
        }
    }
    
    private func resetPlanning() {
        selectedPark = nil
        preferences = TravelPreferences.default
        itineraryPlanner = nil
        currentStep = .selectPark
    }
}

struct GeneratingItineraryView: View {
    @State private var animationOffset: CGFloat = -100
    
    var body: some View {
        VStack(spacing: 24) {
            // Animated Icon
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "map")
                    .font(.system(size: 48))
                    .foregroundColor(.blue)
                    .offset(x: animationOffset)
                    .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: animationOffset)
            }
            
            VStack(spacing: 8) {
                Text("Creating Your Perfect Itinerary")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Our AI is analyzing local attractions, weather, and your preferences...")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            ProgressView()
                .scaleEffect(1.2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            animationOffset = 100
        }
    }
}
```

### 9. App Entry Point

```swift
//  TravelApp.swift
import SwiftUI

@main
struct TravelApp: App {
    var body: some Scene {
        WindowGroup {
            TravelPlanningView()
        }
    }
}
```

## Key Features Demonstrated

### 1. Tool Integration
- **MapKit Integration**: Real location search with proper error handling
- **Weather API Simulation**: Shows how to integrate external services
- **Tool Chaining**: Weather and location tools work together for context

### 2. Structured Generation
- **Complex Data Models**: Nested structures with proper `@Guide` attributes
- **Real-time Updates**: UI responds to partial generation progress
- **Type Safety**: Compile-time validation of AI outputs

### 3. User Experience
- **Progressive Disclosure**: Step-by-step planning process
- **Loading States**: Graceful handling of generation time
- **Error Recovery**: Proper error handling and retry mechanisms

### 4. Production Considerations
- **Performance**: Session reuse and proper memory management
- **Accessibility**: Support for different user needs
- **Customization**: Flexible preferences system

## Best Practices Demonstrated

1. **Tool Design**: Clear interfaces with proper argument validation
2. **Error Handling**: Comprehensive error types with user-friendly messages
3. **UI Patterns**: Partial content rendering with placeholders
4. **State Management**: Clean separation of concerns with `@Observable`
5. **Performance**: Efficient session management and reuse

## Next Steps

1. **Add Real APIs**: Replace simulated weather data with actual services
2. **Enhance Tools**: Add more sophisticated location and booking tools
3. **Offline Support**: Cache common queries for offline use
4. **Personalization**: Learn from user preferences over time

---

*This example shows how Foundation Models can power sophisticated, real-world applications with multiple data sources and complex user interactions.*