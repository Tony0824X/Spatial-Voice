// VRQAResultView.swift
import SwiftUI
import UniformTypeIdentifiers
import PDFKit
import RealityKit

// MARK: - Q&A 狀態

enum QAStatus {
    case idle      // 顯示「Answer」
    case listening // 顯示「Listening...」+「Stop」
    case answered  // 顯示「Answered」
}

struct QAItem: Identifiable {
    let id = UUID()
    let number: Int
    let text: String
    var status: QAStatus = .idle
}

// MARK: - QASessionView

struct QASessionView: View {
    @EnvironmentObject private var session: PresentationSession
    @Environment(\.dismiss) private var dismiss

    @State private var items: [QAItem] = [
        .init(number: 1, text: "Lecturer: Given the programme’s high operating cost and low 1% contribution to total recycling, what specific metrics should the government prioritise to evaluate future cost-effectiveness?"),
        .init(number: 2, text: "Classmate: Your findings show motivation is the core issue. What new incentive structures, beyond GREEN$ gifts, could realistically attract younger citizens to participate consistently?"),
        .init(number: 3, text: "Classmate: Since fragmented data limits public accountability, what types of G@C performance data should be made open to enable meaningful citizen oversight and policy improvement?")
    ]

    @State private var showResult: Bool = false

    var body: some View {
        if showResult {
            PresentationResultView()
        } else {
            ZStack {
                LinearGradient(
                    colors: [Color(red: 10/255, green: 8/255, blue: 40/255),
                             Color(red: 5/255, green: 5/255, blue: 25/255)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 28) {
                    Text("Q&A SESSION")
                        .font(.system(size: 40, weight: .heavy))
                        .kerning(3)
                        .foregroundStyle(.white)
                        .padding(.top, 24)

                    VStack(spacing: 18) {
                        ForEach($items) { $item in
                            QAQuestionRow(item: $item)
                        }
                    }
                    .padding(.horizontal, 40)

                    Spacer(minLength: 20)
                }
            }
            .overlay(alignment: .bottomTrailing) {
                Button {
                    showResult = true
                } label: {
                    Label("Next", systemImage: "chevron.right")
                        .font(.headline.weight(.bold))
                        .padding(.horizontal, 24)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.9), in: Capsule())
                        .foregroundStyle(Color(red: 35/255, green: 20/255, blue: 90/255))
                }
                .buttonStyle(.plain)
                .padding(.trailing, 32)
                .padding(.bottom, 28)
            }
        }
    }
}

private struct QAQuestionRow: View {
    @Binding var item: QAItem

    private var avatarName: String {
        switch item.number {
        case 1: return "Profile_QApic1"
        case 2: return "Profile_QApic2"
        case 3: return "Profile_QApic3"
        default: return "Profile_QApic1"
        }
    }

    private var cardBackground: Color {
        Color.white.opacity(0.96)
    }

    var body: some View {
        HStack(spacing: 16) {
            Image(avatarName)
                .resizable()
                .scaledToFill()
                .frame(width: 64, height: 64)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 6) {
                Text("QUESTION \(item.number)")
                    .font(.headline.weight(.heavy))
                    .foregroundStyle(Color(red: 40/255, green: 35/255, blue: 60/255))

                Text(item.text)
                    .font(.subheadline)
                    .foregroundStyle(Color.black.opacity(0.75))
                    .fixedSize(horizontal: false, vertical: true)

                HStack {
                    Spacer()
                    statusButtons
                }
                .padding(.top, 8)
            }
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 16)
        .background(cardBackground, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
        .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 4)
    }

    @ViewBuilder
    private var statusButtons: some View {
        switch item.status {
        case .idle:
            Button {
                item.status = .listening
            } label: {
                Text("Answer")
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(Color(red: 214/255, green: 190/255, blue: 255/255), in: Capsule())
                    .foregroundStyle(Color(red: 65/255, green: 35/255, blue: 120/255))
            }
            .buttonStyle(.plain)

        case .listening:
            HStack(spacing: 12) {
                Text("Listening ...")
                    .font(.subheadline.weight(.bold))
                    .padding(.horizontal, 18)
                    .padding(.vertical, 8)
                    .background(Color(red: 255/255, green: 221/255, blue: 120/255), in: Capsule())
                    .foregroundStyle(Color.black)
                    .overlay(
                        Capsule()
                            .stroke(Color.black.opacity(0.15), lineWidth: 1)
                    )

                Button {
                    item.status = .answered
                } label: {
                    Text("Stop")
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(Color(red: 210/255, green: 190/255, blue: 255/255), in: Capsule())
                        .foregroundStyle(Color(red: 65/255, green: 35/255, blue: 120/255))
                }
                .buttonStyle(.plain)
            }

        case .answered:
            Text("Answered")
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background(Color(.systemGray4), in: Capsule())
                .foregroundStyle(.black.opacity(0.8))
        }
    }
}

// MARK: - PresentationHUDView（原 TwoScreenHUDView，改名避免重複）

struct PresentationHUDView: View {
    let onBackToClass: () -> Void

    @EnvironmentObject private var session: PresentationSession
    @Environment(\.dismiss) private var dismiss

    @State private var isTimerRunning = false
    @State private var remainingSeconds: Int = 0
    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    @State private var slidesPageIndex: Int = 0
    @State private var slidesPageCount: Int = 1

    @State private var scriptPageIndex: Int = 0
    @State private var scriptPageCount: Int = 1

    var body: some View {
        VStack(spacing: 18) {
            timerControlBar
                .padding(.top, 4)
                .padding(.horizontal, 40)

            HStack(spacing: 32) {
                screen1View
                screen2View
            }
            .frame(maxWidth: 1240, maxHeight: 600)
        }
        .padding(.horizontal, 40)
        .padding(.bottom, 40)
        .onAppear {
            remainingSeconds = max(1, session.durationMinutes) * 60
            updatePageCounts()
        }
        .onChange(of: session.slidesURL) { _ in
            updatePageCounts()
        }
        .onChange(of: session.scriptURL) { _ in
            updatePageCounts()
        }
        .onReceive(ticker) { _ in
            guard isTimerRunning else { return }
            if remainingSeconds > 0 {
                remainingSeconds -= 1
            } else {
                isTimerRunning = false
            }
        }
    }

    private var timerControlBar: some View {
        HStack(spacing: 18) {
            Spacer()

            Button {
                if isTimerRunning {
                    isTimerRunning = false
                } else {
                    if remainingSeconds <= 0 {
                        remainingSeconds = max(1, session.durationMinutes) * 60
                    }
                    isTimerRunning = true
                }
            } label: {
                Text(isTimerRunning ? "Stop" : "Start")
                    .font(.headline.weight(.bold))
                    .padding(.horizontal, 28)
                    .padding(.vertical, 10)
                    .background(Color.yellow, in: Capsule())
                    .foregroundStyle(.black)
            }
            .buttonStyle(.plain)

            HStack(spacing: 6) {
                Image(systemName: "clock")
                Text(formattedRemainingTime)
                    .font(.headline.monospacedDigit())
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .background(Color.black.opacity(0.7), in: Capsule())
            .foregroundStyle(.white)

            Text(isTimerRunning ? "Listening..." : "Paused")
                .font(.headline)
                .padding(.horizontal, 24)
                .padding(.vertical, 10)
                .background(
                    LinearGradient(
                        colors: [.blue.opacity(0.9), .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    in: Capsule()
                )
                .foregroundStyle(.white)

            Spacer(minLength: 24)

            Button {
                isTimerRunning = false
                let totalSeconds = max(1, session.durationMinutes) * 60
                let used = max(0, totalSeconds - remainingSeconds)
                session.actualUsedSeconds = used
                session.showResult = true

                // 🔹 這裡觸發 DeepSeek 分析（非阻塞 UI）
                Task {
                    await DeepSeekAnalyzer.shared.analyze(session: session)
                }

                dismiss()
            } label: {
                Text("End")
                    .font(.headline.weight(.bold))
                    .padding(.horizontal, 28)
                    .padding(.vertical, 10)
                    .background(Color.red, in: Capsule())
                    .foregroundStyle(.white)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }

    private var screen1View: some View {
        HUDNeonScreen(
            colors: [Color.green, Color.teal, Color.green]
        ) {
            VStack(spacing: 16) {
                if let url = session.slidesURL {
                    Text("Slides")
                        .font(.title2.bold())
                        .foregroundStyle(.white)

                    Text(url.lastPathComponent)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.8))

                    if url.pathExtension.lowercased() == "pdf" {
                        HUDPDFKitContainerView(
                            url: url,
                            pageIndex: slidesPageIndex,
                            continuous: false
                        )
                    } else {
                        Text("Preview not available for this file type.\n(Only PDF is rendered.)")
                            .font(.footnote)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.white.opacity(0.8))
                            .padding(.top, 40)
                    }
                } else {
                    Spacer()
                    Text("No slides selected")
                        .font(.title3)
                        .foregroundStyle(.white.opacity(0.7))
                    Spacer()
                }
            }
            .padding(20)
        }
        .overlay(alignment: .bottom) {
            HStack(spacing: 18) {
                Button {
                    onBackToClass()
                } label: {
                    Text("Back")
                        .font(.headline)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 9)
                        .background(
                            LinearGradient(
                                colors: [.teal, .green],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            in: Capsule()
                        )
                }
                .buttonStyle(.plain)

                Spacer()

                Button {
                    if slidesPageIndex > 0 {
                        slidesPageIndex -= 1
                    }
                } label: {
                    Text("Previous")
                        .font(.headline)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 9)
                        .background(
                            LinearGradient(
                                colors: [.teal, .blue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            in: Capsule()
                        )
                }
                .buttonStyle(.plain)
                .disabled(slidesPageCount <= 1)

                Button {
                    if slidesPageIndex < slidesPageCount - 1 {
                        slidesPageIndex += 1
                    }
                } label: {
                    Text("Next")
                        .font(.headline)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 9)
                        .background(
                            LinearGradient(
                                colors: [.blue, .teal],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            in: Capsule()
                        )
                }
                .buttonStyle(.plain)
                .disabled(slidesPageCount <= 1)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 26)
        }
    }

    private var screen2View: some View {
        HUDNeonScreen(
            colors: [Color.orange, Color.pink, Color.orange]
        ) {
            VStack(spacing: 18) {
                if let url = session.scriptURL {
                    Text("Script")
                        .font(.title2.bold())
                        .foregroundStyle(.white)

                    Text(url.lastPathComponent)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.8))

                    if url.pathExtension.lowercased() == "pdf" {
                        HUDPDFKitContainerView(
                            url: url,
                            pageIndex: scriptPageIndex,
                            continuous: true
                        )
                    } else {
                        Text("Preview not available for this file type.\n(Only PDF is rendered.)")
                            .font(.footnote)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.white.opacity(0.8))
                            .padding(.top, 40)
                    }
                } else {
                    Spacer()
                    Text("No script selected")
                        .font(.title3)
                        .foregroundStyle(.white.opacity(0.7))
                    Spacer()
                }
            }
            .padding(20)
        }
        .overlay(alignment: .bottom) {
            HStack(spacing: 18) {
                Button {
                    if scriptPageIndex > 0 {
                        scriptPageIndex -= 1
                    }
                } label: {
                    Text("Previous")
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial, in: Capsule())
                }
                .buttonStyle(.plain)
                .disabled(scriptPageCount <= 1)

                Button {
                    if scriptPageIndex < scriptPageCount - 1 {
                        scriptPageIndex += 1
                    }
                } label: {
                    Text("Next")
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial, in: Capsule())
                }
                .buttonStyle(.plain)
                .disabled(scriptPageCount <= 1)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 26)
        }
    }

    private var formattedRemainingTime: String {
        let m = remainingSeconds / 60
        let s = remainingSeconds % 60
        return String(format: "%02d:%02d", m, s)
    }

    private func updatePageCounts() {
        if let url = session.slidesURL,
           let doc = PDFDocument(url: url) {
            slidesPageCount = max(doc.pageCount, 1)
            slidesPageIndex = min(slidesPageIndex, slidesPageCount - 1)
        }

        if let url = session.scriptURL,
           let doc = PDFDocument(url: url) {
            scriptPageCount = max(doc.pageCount, 1)
            scriptPageIndex = min(scriptPageIndex, scriptPageCount - 1)
        }
    }
}

// MARK: - PresentationResultView（新 UI）

struct PresentationResultView: View {
    @EnvironmentObject private var session: PresentationSession
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace

    @State private var showDetail: Bool = false

    private func formattedScore(_ value: Double?) -> String {
        guard let value else { return "--" }
        return String(format: "%.1f", value)
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 16/255, green: 10/255, blue: 40/255),
                         Color(red: 5/255, green: 5/255, blue: 25/255)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                // 標題
                VStack(spacing: 6) {
                    HStack {
                        Image(systemName: "timer")
                            .foregroundStyle(Color.yellow)
                        Text("Results Overview")
                            .font(.system(size: 34, weight: .heavy))
                        Spacer()
                    }
                    .foregroundStyle(.white)

                    HStack {
                        Text("Time Taken: \(session.formattedUsedTime)")
                        Text("Scores out of 10")
                            .foregroundStyle(.secondary)
                        Spacer()

                        if session.isAnalyzing {
                            HStack(spacing: 8) {
                                ProgressView()
                                    .progressViewStyle(.circular)
                                Text("Analyzing with AI...")
                            }
                            .foregroundStyle(.white)
                            .font(.footnote)
                        }
                    }
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.9))
                }
                .padding(.horizontal, 36)
                .padding(.top, 16)

                // 中間主體：左右 6 個卡 + 中間圓環
                HStack(alignment: .center, spacing: 32) {
                    VStack(spacing: 18) {
                        ResultMetricCard(
                            title: "Verbal / Content",
                            scoreText: formattedScore(session.scoreVerbalContent),
                            progress: (session.scoreVerbalContent ?? 0) / 10.0,
                            barColor: Color.yellow
                        )
                        ResultMetricCard(
                            title: "Vocal Delivery",
                            scoreText: session.scoreVocalDeliveryLabel,
                            progress: nil,
                            barColor: Color.pink
                        )
                        ResultMetricCard(
                            title: "Non-verbal / Body Language",
                            scoreText: session.scoreNonverbalLabel,
                            progress: nil,
                            barColor: Color.pink
                        )
                    }
                    .frame(maxWidth: 260)

                    DonutOverviewView(
                        overall: session.overallScore,
                        comment: session.overallComment ?? "Great"
                    )
                    .frame(width: 260, height: 260)

                    VStack(spacing: 18) {
                        ResultMetricCard(
                            title: "Visual Aids / Slides",
                            scoreText: formattedScore(session.scoreVisualAids),
                            progress: (session.scoreVisualAids ?? 0) / 10.0,
                            barColor: Color.green
                        )
                        ResultMetricCard(
                            title: "Time Management",
                            scoreText: formattedScore(session.scoreTimeManagement),
                            progress: (session.scoreTimeManagement ?? 0) / 10.0,
                            barColor: Color.pink
                        )
                        ResultMetricCard(
                            title: "Audience Engagement",
                            scoreText: formattedScore(session.scoreAudienceEngagement),
                            progress: (session.scoreAudienceEngagement ?? 0) / 10.0,
                            barColor: Color.yellow
                        )
                    }
                    .frame(maxWidth: 260)
                }
                .padding(.horizontal, 28)
                .padding(.top, 8)

                Spacer(minLength: 10)

                // 下方按鈕
                HStack(spacing: 24) {
                    Button {
                        showDetail = true
                    } label: {
                        Text("Detail Feedback")
                            .font(.headline.weight(.bold))
                            .padding(.horizontal, 30)
                            .padding(.vertical, 12)
                            .background(Color.yellow, in: RoundedRectangle(cornerRadius: 14))
                            .foregroundStyle(.black)
                    }
                    .buttonStyle(.plain)

                    Button {
                        Task {
                            await dismissImmersiveSpace()
                            session.showResult = false
                            dismiss()
                        }
                    } label: {
                        Text("Back to Menu")
                            .font(.headline.weight(.bold))
                            .padding(.horizontal, 30)
                            .padding(.vertical, 12)
                            .background(Color.yellow, in: RoundedRectangle(cornerRadius: 14))
                            .foregroundStyle(.black)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.bottom, 28)
            }
        }
        .fullScreenCover(isPresented: $showDetail) {
            DetailFeedbackView()
                .environmentObject(session)
        }
    }
}

// MARK: - 小元件：ResultMetricCard & DonutOverviewView

private struct ResultMetricCard: View {
    let title: String
    let scoreText: String
    let progress: Double?
    let barColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.subheadline.weight(.heavy))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.yellow.opacity(0.9), in: RoundedRectangle(cornerRadius: 8))
                .foregroundStyle(.black)

            Text(scoreText)
                .font(.system(size: 32, weight: .heavy))
                .foregroundStyle(.white)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.black.opacity(0.5))
                        .frame(height: 10)

                    if let progress {
                        let clamped = max(0, min(progress, 1))
                        RoundedRectangle(cornerRadius: 8)
                            .fill(barColor)
                            .frame(width: geo.size.width * clamped, height: 10)
                    }
                }
            }
            .frame(height: 12)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.purple.opacity(0.9), lineWidth: 3)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.black.opacity(0.3))
                )
        )
    }
}

private struct DonutOverviewView: View {
    let overall: Double?
    let comment: String

    private var overallText: String {
        guard let overall else { return "--" }
        return String(format: "%.1f", overall)
    }

    var body: some View {
        ZStack {
            // 外圈簡單 4 色環（這裡不按比例，只做視覺效果）
            Circle()
                .stroke(Color.pink, lineWidth: 26)
            Circle()
                .trim(from: 0, to: 0.25)
                .stroke(Color.yellow, style: StrokeStyle(lineWidth: 26, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Circle()
                .trim(from: 0.25, to: 0.5)
                .stroke(Color.green, style: StrokeStyle(lineWidth: 26, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Circle()
                .trim(from: 0.5, to: 0.75)
                .stroke(Color.pink.opacity(0.9), style: StrokeStyle(lineWidth: 26, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Circle()
                .trim(from: 0.75, to: 1.0)
                .stroke(Color.yellow.opacity(0.9), style: StrokeStyle(lineWidth: 26, lineCap: .round))
                .rotationEffect(.degrees(-90))

            Circle()
                .fill(Color(red: 16/255, green: 10/255, blue: 40/255))
                .frame(width: 150, height: 150)

            VStack(spacing: 6) {
                Text("Overall")
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.9))
                Text(overallText)
                    .font(.system(size: 40, weight: .heavy))
                    .foregroundStyle(.white)

                Text(comment)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(Color.red)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.black.opacity(0.6), in: Capsule())
            }
        }
    }
}

// MARK: - DetailFeedbackView

struct DetailFeedbackView: View {
    @EnvironmentObject private var session: PresentationSession
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 16/255, green: 10/255, blue: 40/255),
                         Color(red: 5/255, green: 5/255, blue: 25/255)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 16) {
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .font(.headline)
                    .padding(8)
                    .background(.ultraThinMaterial, in: Capsule())
                    .buttonStyle(.plain)

                    Spacer()

                    Text("Detailed Feedback")
                        .font(.system(size: 30, weight: .heavy))
                        .foregroundStyle(.white)

                    Spacer()
                        .frame(maxWidth: 80)
                }
                .padding(.horizontal, 24)
                .padding(.top, 18)

                ScrollView {
                    VStack(spacing: 18) {
                        FeedbackCard(
                            title: "Verbal / Content",
                            score: session.scoreVerbalContent,
                            fallbackLabel: "--",
                            text: session.feedbackVerbalContent
                        )
                        FeedbackCard(
                            title: "Visual Aids / Slides",
                            score: session.scoreVisualAids,
                            fallbackLabel: "--",
                            text: session.feedbackVisualAids
                        )
                        FeedbackCard(
                            title: "Time Management",
                            score: session.scoreTimeManagement,
                            fallbackLabel: "--",
                            text: session.feedbackTimeManagement
                        )
                        FeedbackCard(
                            title: "Audience Engagement",
                            score: session.scoreAudienceEngagement,
                            fallbackLabel: "--",
                            text: session.feedbackAudienceEngagement
                        )
                        FeedbackCard(
                            title: "Vocal Delivery",
                            score: nil,
                            fallbackLabel: "Updating",
                            text: session.feedbackVocalDelivery
                        )
                        FeedbackCard(
                            title: "Non-verbal / Body Language",
                            score: nil,
                            fallbackLabel: "Updating",
                            text: session.feedbackNonverbal
                        )
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 30)
                }
            }
        }
    }
}

private struct FeedbackCard: View {
    let title: String
    let score: Double?
    let fallbackLabel: String
    let text: String

    private var scoreLabel: String {
        if let score {
            return String(format: "%.1f", score)
        } else {
            return fallbackLabel
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(title)
                    .font(.headline.weight(.bold))
                Spacer()
                Text(scoreLabel)
                    .font(.headline.weight(.bold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.yellow, in: Capsule())
                    .foregroundStyle(.black)
            }

            Text(text.isEmpty ? "No feedback available yet." : text)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.9))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.black.opacity(0.35))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
}

// MARK: - HUD 外框 / PDFKit wrapper

private struct HUDNeonScreen<Content: View>: View {
    var colors: [Color] = [.purple, .blue, .purple]
    @ViewBuilder var content: Content

    var body: some View {
        let gradient = LinearGradient(
            colors: colors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        ZStack {
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(Color.black.opacity(0.9))

            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .stroke(gradient, lineWidth: 5)

            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.black.opacity(0.85))
                .padding(10)

            content
                .padding(26)
        }
    }
}

private struct HUDPDFKitContainerView: UIViewRepresentable {
    let url: URL
    let pageIndex: Int
    let continuous: Bool

    func makeUIView(context: Context) -> PDFView {
        let view = PDFView()
        view.backgroundColor = .clear
        view.autoScales = true
        view.displayMode = continuous ? .singlePageContinuous : .singlePage
        view.displaysPageBreaks = false
        view.document = PDFDocument(url: url)
        if let page = view.document?.page(at: pageIndex) {
            view.go(to: page)
        }
        return view
    }

    func updateUIView(_ pdfView: PDFView, context: Context) {
        if pdfView.document == nil ||
            pdfView.document?.documentURL != url {
            pdfView.document = PDFDocument(url: url)
        }
        if let page = pdfView.document?.page(at: pageIndex) {
            pdfView.go(to: page)
        }
    }
}
