# Content Generation Examples

## Overview

This guide demonstrates advanced content generation using Foundation Models' structured generation capabilities. Learn how to create type-safe AI outputs for exams, jokes, and other structured content.

## Exam Generation System

### Data Models

```swift
//  Exam.swift
import Foundation
import FoundationModels

@Generable
struct Exam {
    
    @Guide(description: "The title of the exam.")
    let name: String

    @Guide(description: "A short description of what this exam covers.")
    let description: String

    @Guide(description: "A list of questions included in the exam.", .count(3))
    let questions: [Question]
}

@Generable
struct Question {
    
    let questionId: UUID = UUID()
    
    @Guide(description: "The text for the exam question.")
    let text: String

    @Guide(description: "The number of points this question is worth. Make sure it is 10.")
    let point: Int

    @Guide(description: "The answer choices for this question. One of them must be marked as correct.", .count(4))
    let choices: [Choice]
}

@Generable
struct Choice {
    
    // This property will NOT be part of partially generated type
    // The reason is that it has been initialized.
    let choiceId = UUID()
    
    @Guide(description: "The text displayed for this answer choice.")
    let text: String

    @Guide(description: "Indicates whether this choice is the correct answer.")
    let isCorrect: Bool
}
```

### Sample Data for Training

```swift
extension Exam {
    
    static let sampleExam = Exam(
        name: "Swift Fundamentals Exam",
        description: "A beginner-level exam to test knowledge of Swift basics including variables, optionals, and control flow.",
        questions: [
            Question(
                text: "Which keyword is used to declare a constant in Swift?",
                point: 10,
                choices: [
                    Choice(text: "var", isCorrect: false),
                    Choice(text: "let", isCorrect: true),
                    Choice(text: "const", isCorrect: false),
                    Choice(text: "define", isCorrect: false)
                ]
            ),
            Question(
                text: "What is the default value of an optional if it is not assigned?",
                point: 10,
                choices: [
                    Choice(text: "nil", isCorrect: true),
                    Choice(text: "0", isCorrect: false),
                    Choice(text: "undefined", isCorrect: false),
                    Choice(text: "null", isCorrect: false)
                ]
            ),
            Question(
                text: "Which statement is used for conditional branching in Swift?",
                point: 10,
                choices: [
                    Choice(text: "if", isCorrect: true),
                    Choice(text: "when", isCorrect: false),
                    Choice(text: "case", isCorrect: false),
                    Choice(text: "switchif", isCorrect: false)
                ]
            )
        ]
    )
}
```

### Exam Generator Service

```swift
//  ExamGenerator.swift
import FoundationModels
import Observation

@Observable
@MainActor
class ExamGenerator {
    
    var exam: Exam.PartiallyGenerated?
    var session: LanguageModelSession

    init() {
        self.session = LanguageModelSession() {
            """
            You are responsible for creating an exam. Each exam will consist of questions. 
            Each question will have 4 choices, where one of them will be correct.    
            """
            
            "Here is an example of sample exam:"
            
            Exam.sampleExam
        }
    }
    
    func generate(skillLevel: SkillLevel) async throws {
        
        let prompt = "Create a \(skillLevel.title.lowercased())-level Swift programming exam"
        
        let stream = session.streamResponse(to: prompt, generating: Exam.self)
        
        for try await partialResponse in stream {
            exam = partialResponse
        }
    }
    
    func generateCustomExam(topic: String, difficulty: String, questionCount: Int) async throws {
        let prompt = """
        Create a \(difficulty) level exam about \(topic) with \(questionCount) questions. 
        Each question should be worth 10 points and have exactly 4 multiple choice answers.
        """
        
        let stream = session.streamResponse(to: prompt, generating: Exam.self)
        
        for try await partialResponse in stream {
            exam = partialResponse
        }
    }
}
```

### Skill Level Configuration

```swift
//  SkillLevel.swift
import Foundation
import SwiftUI 

enum SkillLevel: CaseIterable, Identifiable {
    case beginner
    case intermediate
    case advanced
    
    var id: Self { self }
    
    var title: String {
        switch self {
        case .beginner: return "Beginner"
        case .intermediate: return "Intermediate"
        case .advanced: return "Advanced"
        }
    }
    
    var iconName: String {
        switch self {
        case .beginner: return "tortoise.fill"
        case .intermediate: return "bolt.fill"
        case .advanced: return "flame.fill"
        }
    }

    var color: Color {
        switch self {
        case .beginner: return .green
        case .intermediate: return .orange
        case .advanced: return .red
        }
    }
    
    var description: String {
        switch self {
        case .beginner:
            return "Basic concepts and fundamental syntax"
        case .intermediate:
            return "Object-oriented programming and common patterns"
        case .advanced:
            return "Complex topics, protocols, and advanced Swift features"
        }
    }
}
```

### UI Implementation

```swift
//  ExamScreen.swift
import SwiftUI
import FoundationModels

struct ExamScreen: View {
    
    let skillLevel: SkillLevel
    @State private var examGenerator: ExamGenerator?
    @State private var selectedChoices: [GenerationID: GenerationID] = [:]
    @State private var score: Int?
    @State private var showingResults = false
    
    private func generateExamQuestions() async {
        do {
            examGenerator = ExamGenerator()
            try await examGenerator?.generate(skillLevel: skillLevel)
        } catch {
            print(error.localizedDescription)
        }
    }
    
    private func submitExam() {
        guard let exam = examGenerator?.exam else { return }
        score = Grader.grade(examKey: exam, studentSubmission: selectedChoices)
        showingResults = true
    }
    
    var body: some View {
        
        let exam = examGenerator?.exam
        
        Group {
            if let exam {
                ScrollView {
                    LazyVStack(spacing: 20) {
                        // Exam Header
                        VStack(alignment: .leading, spacing: 8) {
                            if let name = exam.name {
                                Text(name)
                                    .font(.title)
                                    .fontWeight(.bold)
                            }
                            
                            if let description = exam.description {
                                Text(description)
                                    .font(.body)
                                    .foregroundColor(.secondary)
                            }
                            
                            Divider()
                        }
                        .padding(.horizontal)
                        
                        // Questions
                        if let questions = exam.questions {
                            ForEach(Array(questions.enumerated()), id: \\.element.id) { index, question in
                                QuestionView(
                                    index: index,
                                    question: question,
                                    selectedChoiceId: selectedChoices[question.id] ?? .init(),
                                    onSelectChoice: { selectedChoiceId in
                                        selectedChoices[question.id] = selectedChoiceId
                                    }
                                )
                                .padding(.horizontal)
                            }
                            
                            // Submit Button
                            Button("Submit Exam") {
                                submitExam()
                            }
                            .buttonStyle(.borderedProminent)
                            .padding()
                            .disabled(selectedChoices.count < questions.count)
                        }
                    }
                }
            } else {
                VStack {
                    ProgressView("Generating \(skillLevel.title) Exam...")
                        .scaleEffect(1.2)
                    
                    Text("Creating questions tailored to your skill level")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationTitle(skillLevel.title)
        .navigationBarTitleDisplayMode(.large)
        .task {
            await generateExamQuestions()
        }
        .sheet(isPresented: $showingResults) {
            ExamResultsView(
                score: score ?? 0,
                totalQuestions: examGenerator?.exam?.questions?.count ?? 0,
                skillLevel: skillLevel
            )
        }
    }
}
```

### Question View Component

```swift
//  QuestionView.swift
import SwiftUI
import FoundationModels

struct QuestionView: View {
    
    let index: Int
    let question: Question.PartiallyGenerated
    let selectedChoiceId: GenerationID
    let onSelectChoice: (GenerationID) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Question Header
            if let questionText = question.text {
                HStack(alignment: .top, spacing: 12) {
                    Text("\(index + 1)")
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                        .frame(width: 28, height: 28)
                        .background(Color.blue)
                        .clipShape(Circle())
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(questionText)
                            .font(.body)
                            .foregroundColor(.primary)
                        
                        if let point = question.point {
                            Text("\(point) points")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            } else {
                HStack(alignment: .top, spacing: 12) {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 28, height: 28)
                    
                    Text("Loading question...")
                        .redacted(reason: .placeholder)
                }
            }
            
            // Choices
            if let choices = question.choices {
                VStack(spacing: 8) {
                    ForEach(choices) { choice in
                        ChoiceRowView(
                            choice: choice,
                            isSelected: selectedChoiceId == choice.id,
                            onSelect: { onSelectChoice(choice.id) }
                        )
                    }
                }
                .padding(.leading, 40)
            } else {
                VStack(spacing: 8) {
                    ForEach(0..<4, id: \\.self) { _ in
                        PlaceholderChoiceView()
                    }
                }
                .padding(.leading, 40)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
}

struct ChoiceRowView: View {
    let choice: Choice.PartiallyGenerated
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                .foregroundColor(isSelected ? .blue : .gray)
                .font(.title3)
            
            if let choiceText = choice.text {
                Text(choiceText)
                    .font(.body)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
            } else {
                Text("Loading choice...")
                    .redacted(reason: .placeholder)
            }
            
            Spacer()
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onSelect()
        }
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

struct PlaceholderChoiceView: View {
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 20, height: 20)
            
            Text("Loading choice...")
                .redacted(reason: .placeholder)
            
            Spacer()
        }
    }
}
```

## Joke Generation System

### Simple Joke Structure

```swift
//  Joke.swift
import FoundationModels

@Generable
struct Joke {
    @Guide(description: "A short, clever, and family-friendly joke text")
    let text: String
    
    @Guide(description: "The category or theme of the joke (dad, pun, clean, etc.)")
    let category: String?
    
    @Guide(description: "Difficulty level from 1-5, where 1 is simple and 5 is complex wordplay")
    let difficulty: Int?
}
```

### Joke Generator with Tools

```swift
//  JokeMaker.swift
import FoundationModels
import Observation

struct DadJokesTool: Tool {
    
    var name: String = "dadJokesTool"
    var description: String = "Generate classic dad jokes that are punny, clean, and perfect for lightening the mood."
    
    @Generable
    struct Arguments {
        @Guide(description: "A natural language topic or keyword to base the dad joke on")
        let naturalLanguageQuery: String
    }
    
    func call(arguments: Arguments) async throws -> ToolOutput {
        let randomJoke = randomDadJoke(topic: arguments.naturalLanguageQuery)
        return ToolOutput(randomJoke)
    }
    
    private func randomDadJoke(topic: String) -> String {
        let jokes = [
            "I'm reading a book on anti-gravity. It's impossible to put down!",
            "Why don't skeletons fight each other? They don't have the guts.",
            "I only know 25 letters of the alphabet. I don't know y.",
            "Did you hear about the restaurant on the moon? Great food, no atmosphere.",
            "Why did the scarecrow win an award? Because he was outstanding in his field!"
        ]
        
        return jokes.randomElement() ?? "I'm all out of jokes about \(topic)... for now!"
    }
}

@MainActor
@Observable
class JokeMaker {
    
    let session: LanguageModelSession
    private(set) var joke: Joke.PartiallyGenerated?
    private(set) var isGenerating: Bool = false
    let dadJokesTool = DadJokesTool()
    
    init() {
        self.session = LanguageModelSession(tools: [dadJokesTool]) {
            """
            You are a professional joke writer. Your task is to generate short, 
            clever, and family-friendly jokes on request. Keep the tone light and playful.
            """
            
            """
            Use the dadJokesTool to create funny and family friendly dad jokes when appropriate.
            """
        }
    }
    
    func suggestJoke(topic: String = "") async throws {
        isGenerating = true
        
        let prompt = if topic.isEmpty {
            "Tell me a short, clever, and family-friendly joke"
        } else {
            "Tell me a short, clever, and family-friendly joke about \(topic)"
        }
        
        let stream = session.streamResponse(to: prompt, generating: Joke.self)
        
        for try await partial in stream {
            self.joke = partial
        }
        
        isGenerating = false
    }
    
    func clearJoke() {
        joke = nil
    }
}
```

### Joke UI

```swift
//  JokeView.swift
import SwiftUI

struct JokeView: View {
    
    @State private var jokeMaker = JokeMaker()
    @State private var topic = ""
    @State private var favoriteJokes: [String] = []
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Topic Input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Joke Topic (Optional)")
                        .font(.headline)
                    
                    TextField("e.g., programming, coffee, cats", text: $topic)
                        .textFieldStyle(.roundedBorder)
                        .disabled(jokeMaker.isGenerating)
                }
                
                // Generate Button
                Button("Get a Joke!") {
                    Task {
                        try await jokeMaker.suggestJoke(topic: topic)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(jokeMaker.isGenerating)
                .controlSize(.large)
                
                // Joke Display
                if let joke = jokeMaker.joke {
                    VStack(spacing: 16) {
                        if let text = joke.text {
                            Text(text)
                                .font(.title3)
                                .multilineTextAlignment(.center)
                                .padding()
                                .background(Color.yellow.opacity(0.1))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
                                )
                        } else if jokeMaker.isGenerating {
                            VStack {
                                ProgressView()
                                Text("Crafting the perfect joke...")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                        }
                        
                        // Action Buttons
                        if let jokeText = joke.text, !jokeText.isEmpty {
                            HStack(spacing: 16) {
                                Button(action: {
                                    favoriteJokes.append(jokeText)
                                }) {
                                    Label("Save", systemImage: "heart")
                                }
                                .buttonStyle(.bordered)
                                
                                Button(action: {
                                    UIPasteboard.general.string = jokeText
                                }) {
                                    Label("Copy", systemImage: "doc.on.doc")
                                }
                                .buttonStyle(.bordered)
                                
                                Button(action: {
                                    shareJoke(jokeText)
                                }) {
                                    Label("Share", systemImage: "square.and.arrow.up")
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                    }
                } else if jokeMaker.isGenerating {
                    VStack {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("Generating joke...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top)
                    }
                    .frame(maxWidth: .infinity, minHeight: 100)
                }
                
                Spacer()
                
                // Favorite Jokes
                if !favoriteJokes.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Favorite Jokes")
                            .font(.headline)
                        
                        ScrollView {
                            LazyVStack(alignment: .leading, spacing: 8) {
                                ForEach(favoriteJokes.indices, id: \\.self) { index in
                                    Text(favoriteJokes[index])
                                        .font(.caption)
                                        .padding(8)
                                        .background(Color.gray.opacity(0.1))
                                        .cornerRadius(8)
                                }
                            }
                        }
                        .frame(maxHeight: 150)
                    }
                }
            }
            .padding()
            .navigationTitle("Joke Generator")
        }
    }
    
    private func shareJoke(_ joke: String) {
        let activityController = UIActivityViewController(
            activityItems: [joke],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(activityController, animated: true)
        }
    }
}
```

## Grading System

### Automated Grader

```swift
//  Grader.swift
import Foundation
import FoundationModels

struct Grader {
    
    static func grade(examKey: Exam.PartiallyGenerated, studentSubmission: [GenerationID: GenerationID]) -> Int {
        var score = 0
        
        guard let questions = examKey.questions else {
            return 0
        }
        
        for question in questions {
            // Safely unwrap choices and find the correct one
            guard let choices = question.choices,
                  let correctChoice = choices.first(where: { $0.isCorrect == true }) else {
                continue
            }
            
            if studentSubmission[question.id] == correctChoice.id {
                score += question.point ?? 0
            }
        }
        
        return score
    }
    
    static func generateDetailedResults(
        examKey: Exam.PartiallyGenerated, 
        studentSubmission: [GenerationID: GenerationID]
    ) -> ExamResults {
        
        var results: [QuestionResult] = []
        var totalScore = 0
        var maxScore = 0
        
        guard let questions = examKey.questions else {
            return ExamResults(totalScore: 0, maxScore: 0, questionResults: [])
        }
        
        for question in questions {
            guard let choices = question.choices,
                  let correctChoice = choices.first(where: { $0.isCorrect == true }),
                  let questionText = question.text else {
                continue
            }
            
            let studentChoiceId = studentSubmission[question.id]
            let studentChoice = choices.first { $0.id == studentChoiceId }
            let isCorrect = studentChoiceId == correctChoice.id
            let points = question.point ?? 0
            
            maxScore += points
            if isCorrect {
                totalScore += points
            }
            
            let result = QuestionResult(
                questionText: questionText,
                studentAnswer: studentChoice?.text ?? "No answer",
                correctAnswer: correctChoice.text ?? "Unknown",
                isCorrect: isCorrect,
                points: points
            )
            results.append(result)
        }
        
        return ExamResults(
            totalScore: totalScore,
            maxScore: maxScore,
            questionResults: results
        )
    }
}

struct ExamResults {
    let totalScore: Int
    let maxScore: Int
    let questionResults: [QuestionResult]
    
    var percentage: Double {
        guard maxScore > 0 else { return 0 }
        return Double(totalScore) / Double(maxScore) * 100
    }
    
    var grade: String {
        switch percentage {
        case 90...100: return "A"
        case 80..<90: return "B"
        case 70..<80: return "C"
        case 60..<70: return "D"
        default: return "F"
        }
    }
}

struct QuestionResult {
    let questionText: String
    let studentAnswer: String
    let correctAnswer: String
    let isCorrect: Bool
    let points: Int
}
```

### Results View

```swift
//  ExamResultsView.swift
import SwiftUI

struct ExamResultsView: View {
    let score: Int
    let totalQuestions: Int
    let skillLevel: SkillLevel
    @Environment(\\.dismiss) private var dismiss
    
    private var percentage: Double {
        guard totalQuestions > 0 else { return 0 }
        return Double(score) / Double(totalQuestions * 10) * 100
    }
    
    private var grade: String {
        switch percentage {
        case 90...100: return "A"
        case 80..<90: return "B"
        case 70..<80: return "C"
        case 60..<70: return "D"
        default: return "F"
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Score Display
                VStack(spacing: 16) {
                    Text("Exam Complete!")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    ZStack {
                        Circle()
                            .stroke(Color.gray.opacity(0.3), lineWidth: 8)
                            .frame(width: 120, height: 120)
                        
                        Circle()
                            .trim(from: 0, to: percentage / 100)
                            .stroke(gradeColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                            .frame(width: 120, height: 120)
                            .rotationEffect(.degrees(-90))
                            .animation(.easeInOut(duration: 1), value: percentage)
                        
                        VStack {
                            Text(grade)
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(gradeColor)
                            
                            Text("\(Int(percentage))%")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Text("\(score) out of \(totalQuestions * 10) points")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                
                // Performance Summary
                VStack(alignment: .leading, spacing: 12) {
                    Text("Performance Summary")
                        .font(.headline)
                    
                    HStack {
                        Text("Skill Level:")
                        Spacer()
                        Label(skillLevel.title, systemImage: skillLevel.iconName)
                            .foregroundColor(skillLevel.color)
                    }
                    
                    HStack {
                        Text("Questions Correct:")
                        Spacer()
                        Text("\(score / 10) of \(totalQuestions)")
                    }
                    
                    HStack {
                        Text("Grade:")
                        Spacer()
                        Text(grade)
                            .fontWeight(.bold)
                            .foregroundColor(gradeColor)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
                
                // Encouragement Message
                VStack(spacing: 8) {
                    Text(encouragementMessage)
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                    
                    if percentage < 70 {
                        Text("Consider reviewing the material and trying again!")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
                
                Spacer()
                
                // Action Buttons
                VStack(spacing: 12) {
                    Button("Take Another Exam") {
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    
                    Button("Back to Skill Selection") {
                        dismiss()
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding()
            .navigationTitle("Exam Results")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var gradeColor: Color {
        switch grade {
        case "A": return .green
        case "B": return .blue
        case "C": return .orange
        case "D": return .yellow
        default: return .red
        }
    }
    
    private var encouragementMessage: String {
        switch percentage {
        case 90...100:
            return "Excellent work! You've mastered this skill level."
        case 80..<90:
            return "Great job! You have a solid understanding of the material."
        case 70..<80:
            return "Good effort! You're on the right track."
        case 60..<70:
            return "Keep studying! You're making progress."
        default:
            return "Don't give up! Practice makes perfect."
        }
    }
}
```

## Best Practices

### 1. Structured Generation Guidelines

- Use clear, specific `@Guide` descriptions
- Provide sample data for training
- Implement proper error handling for partial data
- Validate generated content before display

### 2. Performance Optimization

- Prewarm sessions during app initialization
- Reuse sessions across multiple generations
- Implement proper cancellation for long operations
- Cache generated content when appropriate

### 3. User Experience

- Show progress indicators during generation
- Handle partial content gracefully
- Provide clear error messages
- Allow users to regenerate content

### 4. Testing Strategies

- Test with various input parameters
- Validate generated content structure
- Test error scenarios and edge cases
- Use mock generators for UI testing

## Next Steps

1. **Explore Tool Integration**: Learn how to [extend AI capabilities](../tool-protocol.md) with custom tools
2. **Advanced UI Patterns**: Check out [SwiftUI integration](../swiftui-integration.md) techniques
3. **Error Handling**: Implement [robust error management](../error-handling.md)

---

*Master structured content generation to build powerful AI-driven applications!*