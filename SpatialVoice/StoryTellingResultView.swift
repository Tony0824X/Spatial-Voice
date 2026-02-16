// StoryTellingResultView.swift
import SwiftUI

struct StoryTellingResultView: View {
    @Binding var isRootPresented: Bool
    let questions: [MCQuestion]
    let selectedAnswers: [Int: Int]

    @Environment(\.dismiss) private var dismiss
    @State private var showCertificate = false

    // Computed results
    private var results: [(question: MCQuestion, isCorrect: Bool)] {
        questions.map { q in
            let selected = selectedAnswers[q.id] ?? -1
            return (q, selected == q.correctIndex)
        }
    }

    private var correctCount: Int {
        results.filter(\.isCorrect).count
    }

    private var passed: Bool {
        correctCount >= 4
    }

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [
                    Color(red: 15/255, green: 12/255, blue: 40/255),
                    Color(red: 35/255, green: 20/255, blue: 70/255)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    resultHeader

                    // Score summary
                    scoreSummary

                    // Per-question results
                    ForEach(results, id: \.question.id) { item in
                        questionResultRow(item.question, isCorrect: item.isCorrect)
                    }

                    // Action buttons
                    actionButtons
                }
                .padding(.horizontal, 32)
                .padding(.vertical, 24)
                .frame(maxWidth: 900)
                .frame(maxWidth: .infinity)
            }
        }
        .fullScreenCover(isPresented: $showCertificate) {
            StoryTellingCertificateView(isRootPresented: $isRootPresented)
        }
    }

    // MARK: - Subviews

    private var resultHeader: some View {
        VStack(spacing: 10) {
            Image(systemName: passed ? "checkmark.seal.fill" : "xmark.seal.fill")
                .font(.system(size: 56))
                .foregroundStyle(passed
                    ? LinearGradient(colors: [.green, .mint], startPoint: .top, endPoint: .bottom)
                    : LinearGradient(colors: [.red, .orange], startPoint: .top, endPoint: .bottom)
                )

            Text(passed ? "Congratulations!" : "Not Quite There")
                .font(.largeTitle.bold())
                .foregroundColor(.white)

            Text(passed
                 ? "You passed the Story Telling Level 1 quiz!"
                 : "You need at least 4 correct answers to pass.")
                .font(.title3)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
        }
        .padding(.top, 30)
    }

    private var scoreSummary: some View {
        HStack(spacing: 16) {
            VStack(spacing: 4) {
                Text("\(correctCount)/\(questions.count)")
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundColor(passed ? .green : .red)
                Text("Score")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.white.opacity(0.7))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.white.opacity(0.08))
            )

            VStack(spacing: 4) {
                Text(passed ? "PASS" : "FAIL")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(passed ? .green : .red)
                Text("Result")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.white.opacity(0.7))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.white.opacity(0.08))
            )
        }
    }

    private func questionResultRow(_ q: MCQuestion, isCorrect: Bool) -> some View {
        HStack(spacing: 14) {
            // Result icon
            Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.system(size: 30, weight: .bold))
                .foregroundColor(isCorrect ? .green : .red)

            VStack(alignment: .leading, spacing: 4) {
                Text(q.question)
                    .font(.headline)
                    .foregroundColor(.white)

                // Show user's answer
                let selectedIdx = selectedAnswers[q.id] ?? -1
                if selectedIdx >= 0 && selectedIdx < q.options.count {
                    Text("Your answer: \(q.options[selectedIdx])")
                        .font(.subheadline)
                        .foregroundColor(isCorrect ? .green.opacity(0.8) : .red.opacity(0.8))
                }

                // If wrong, show the correct answer
                if !isCorrect {
                    Text("Correct: \(q.options[q.correctIndex])")
                        .font(.subheadline)
                        .foregroundColor(.yellow.opacity(0.9))
                }
            }

            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(
                    isCorrect ? Color.green.opacity(0.3) : Color.red.opacity(0.3),
                    lineWidth: 1
                )
        )
    }

    private var actionButtons: some View {
        VStack(spacing: 14) {
            if passed {
                Button {
                    showCertificate = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.right.circle.fill")
                        Text("Next — Get Your Certificate")
                    }
                    .font(.title3.weight(.bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            colors: [.green, Color(red: 0.1, green: 0.7, blue: 0.4)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                    )
                }
                .buttonStyle(.plain)
            }

            Button {
                // Dismiss all the way back to home
                isRootPresented = false
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "house.fill")
                    Text("Back to Home")
                }
                .font(.headline.weight(.bold))
                .foregroundColor(.white.opacity(0.9))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    Color.white.opacity(0.1),
                    in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        }
        .padding(.bottom, 30)
    }
}
