// StoryTellingLevel1View.swift
import SwiftUI

// MARK: - Data Models

struct MCQuestion: Identifiable {
    let id: Int
    let question: String
    let options: [String]
    let correctIndex: Int   // 0-based index of the correct option
}

// MARK: - Main View

struct StoryTellingLevel1View: View {
    @Binding var isPresented: Bool
    @Environment(\.dismiss) private var dismiss

    // Quiz state
    @State private var selectedAnswers: [Int: Int] = [:]   // questionID -> selected option index
    @State private var showIncompleteAlert = false
    @State private var showResult = false

    // Scenario content
    private let scenarioTitle = "University Demo Day: Pitch Your Startup"
    private let scenarioParagraphs = [
        "Imagine you are a university student about to present your startup idea at the annual Demo Day. The auditorium is packed with professors, investors, and fellow students — all eager to hear what you have built.",
        "You have exactly 5 minutes on stage. Your slides are ready, but your story is what will make or break this pitch. A strong narrative can turn a simple app demo into an unforgettable moment that inspires people to believe in your vision.",
        "As you step up to the podium, you take a deep breath and begin with a personal anecdote that connects your idea to a real-world problem. The audience leans in. This is story telling at its finest — and now it's your turn to master it."
    ]

    // 5 MC questions about story telling best practices
    private let questions: [MCQuestion] = [
        MCQuestion(
            id: 0,
            question: "Q1: What is the most effective way to open a presentation?",
            options: [
                "A. Read your agenda slide word by word",
                "B. Start with a surprising fact or personal story",
                "C. Introduce yourself with your full resume",
                "D. Apologise for being nervous"
            ],
            correctIndex: 1
        ),
        MCQuestion(
            id: 1,
            question: "Q2: How can you best keep the audience engaged during your story?",
            options: [
                "A. Speak in a flat, monotone voice",
                "B. Use varied pacing, pauses, and vocal emphasis",
                "C. Read directly from your notes at all times",
                "D. Avoid eye contact to focus on your slides"
            ],
            correctIndex: 1
        ),
        MCQuestion(
            id: 2,
            question: "Q3: What role does emotional connection play in story telling?",
            options: [
                "A. Emotions are unprofessional and should be avoided",
                "B. Only sad stories create emotional connection",
                "C. Relatable emotions help the audience remember your message",
                "D. Emotional stories only work for children"
            ],
            correctIndex: 2
        ),
        MCQuestion(
            id: 3,
            question: "Q4: What makes a strong closing in a story-driven presentation?",
            options: [
                "A. Ending abruptly so people can leave",
                "B. Summarising key points and ending with a clear call-to-action",
                "C. Adding 10 more slides at the end",
                "D. Saying 'that's all I have' and walking off"
            ],
            correctIndex: 1
        ),
        MCQuestion(
            id: 4,
            question: "Q5: Why is structure important in story telling?",
            options: [
                "A. It makes the story longer",
                "B. A clear beginning, middle, and end helps the audience follow along",
                "C. Structure is only needed for written stories",
                "D. It removes the need for creativity"
            ],
            correctIndex: 1
        )
    ]

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(red: 20/255, green: 15/255, blue: 50/255),
                    Color(red: 40/255, green: 25/255, blue: 80/255)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 28) {
                    // Header
                    headerSection

                    // Scenario
                    scenarioSection

                    // Divider
                    dividerLine

                    // Questions
                    questionsSection

                    // Submit button
                    submitButton
                }
                .padding(.horizontal, 32)
                .padding(.vertical, 24)
                .frame(maxWidth: 900)
                .frame(maxWidth: .infinity)
            }

            // Back button (top-left)
            VStack {
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.9))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(.ultraThinMaterial, in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .padding(.leading, 24)
                    .padding(.top, 16)
                    Spacer()
                }
                Spacer()
            }
        }
        .alert("Incomplete", isPresented: $showIncompleteAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Please answer all 5 questions before submitting.")
        }
        .fullScreenCover(isPresented: $showResult) {
            StoryTellingResultView(
                isRootPresented: $isPresented,
                questions: questions,
                selectedAnswers: selectedAnswers
            )
        }
    }

    // MARK: - Subviews

    private var headerSection: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "book.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(
                        LinearGradient(colors: [.orange, .yellow], startPoint: .top, endPoint: .bottom)
                    )
                Text("Story Telling")
                    .font(.largeTitle.bold())
                    .foregroundColor(.white)
            }

            Text("Level 1 • Beginner")
                .font(.title3.weight(.semibold))
                .foregroundColor(.orange)
        }
        .padding(.top, 50)
    }

    private var scenarioSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Scenario header with icon
            HStack(spacing: 10) {
                Image(systemName: "theatermasks.fill")
                    .font(.title2)
                    .foregroundColor(.yellow)
                Text(scenarioTitle)
                    .font(.title2.weight(.bold))
                    .foregroundColor(.white)
            }
            .padding(.bottom, 4)

            // Illustration banner
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 70/255, green: 30/255, blue: 140/255),
                                Color(red: 120/255, green: 50/255, blue: 180/255)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 100)

                HStack(spacing: 20) {
                    Image(systemName: "person.wave.2.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.white.opacity(0.9))
                    VStack(alignment: .leading, spacing: 4) {
                        Text("🎤 Demo Day Pitch")
                            .font(.headline.bold())
                            .foregroundColor(.white)
                        Text("5 minutes to impress the audience")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    Spacer()
                    Image(systemName: "star.fill")
                        .font(.system(size: 30))
                        .foregroundColor(.yellow)
                }
                .padding(.horizontal, 20)
            }

            // Scenario paragraphs
            ForEach(Array(scenarioParagraphs.enumerated()), id: \.offset) { _, para in
                Text(para)
                    .font(.body)
                    .foregroundColor(.white.opacity(0.9))
                    .lineSpacing(4)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
    }

    private var dividerLine: some View {
        HStack(spacing: 12) {
            Rectangle()
                .fill(Color.white.opacity(0.15))
                .frame(height: 1)
            Text("📝 Quiz")
                .font(.headline)
                .foregroundColor(.white.opacity(0.7))
            Rectangle()
                .fill(Color.white.opacity(0.15))
                .frame(height: 1)
        }
    }

    private var questionsSection: some View {
        VStack(spacing: 20) {
            ForEach(questions) { q in
                questionCard(q)
            }
        }
    }

    private func questionCard(_ q: MCQuestion) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(q.question)
                .font(.headline.weight(.bold))
                .foregroundColor(.white)

            ForEach(Array(q.options.enumerated()), id: \.offset) { optIdx, optText in
                optionRow(questionID: q.id, optionIndex: optIdx, optionText: optText)
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }

    private func optionRow(questionID: Int, optionIndex: Int, optionText: String) -> some View {
        let isSelected = selectedAnswers[questionID] == optionIndex

        return Button {
            selectedAnswers[questionID] = optionIndex
        } label: {
            HStack(spacing: 12) {
                radioCircle(isSelected: isSelected)

                Text(optionText)
                    .font(.body)
                    .foregroundColor(isSelected ? .orange : .white.opacity(0.85))
                    .multilineTextAlignment(.leading)

                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isSelected ? Color.orange.opacity(0.12) : Color.white.opacity(0.04))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isSelected ? Color.orange.opacity(0.5) : Color.white.opacity(0.08), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func radioCircle(isSelected: Bool) -> some View {
        ZStack {
            Circle()
                .stroke(isSelected ? Color.orange : Color.white.opacity(0.4), lineWidth: 2)
                .frame(width: 24, height: 24)
            if isSelected {
                Circle()
                    .fill(Color.orange)
                    .frame(width: 14, height: 14)
            }
        }
    }

    private var submitButton: some View {
        Button {
            // Validate all questions answered
            if selectedAnswers.count < questions.count {
                showIncompleteAlert = true
            } else {
                showResult = true
            }
        } label: {
            Text("Submit")
                .font(.title3.weight(.bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: [.orange, Color(red: 1.0, green: 0.4, blue: 0.1)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                )
        }
        .buttonStyle(.plain)
        .padding(.bottom, 30)
    }
}
