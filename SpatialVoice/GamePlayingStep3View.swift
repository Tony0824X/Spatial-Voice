import SwiftUI
import Speech
import AVFoundation

struct GamePlayingStep3View: View {

    @Binding var coins: Int
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace

    @State private var showStep4: Bool = false

    struct QuestionState {
        var timer: Int = 0
        var status: ButtonStatus = .ready
        var resultText: String = ""
        var timerTask: Timer?
    }

    enum ButtonStatus {
        case ready
        case recording
        case finished
    }

    @State private var questions: [QuestionState] = Array(repeating: .init(), count: 4)

    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    @State private var audioEngine = AVAudioEngine()
    @State private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    @State private var recognitionTask: SFSpeechRecognitionTask?

    // 可微調位置
    private let topOffsetY: CGFloat = 155
    private let bottomOffsetY: CGFloat = -170
    private let leftOffsetX: CGFloat = 215
    private let rightOffsetX: CGFloat = -190

    // 每個區塊內部間距
    private let itemSpacing: CGFloat = 8

    var body: some View {
        ZStack {
            Image("Game_playing_step3")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            // Coins 顯示
            VStack {
                HStack {
                    Spacer()
                    HStack(spacing: 6) {
                        Image(systemName: "bitcoinsign.circle.fill")
                            .font(.title2)
                            .foregroundColor(.yellow)
                        Text("\(coins)")
                            .font(.title3.bold())
                            .foregroundColor(.white)
                    }
                    .padding(8)
                    .background(Color.black.opacity(0.6), in: RoundedRectangle(cornerRadius: 10))
                    .padding(.trailing, 24)
                }
                Spacer()
            }

            // Q1 左上
            VStack(spacing: itemSpacing) {
                centeredTimerSection(idx: 0, isBlack: true)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .offset(x: leftOffsetX, y: topOffsetY)

            // Q2 右上
            VStack(spacing: itemSpacing) {
                centeredTimerSection(idx: 1, isBlack: false)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            .offset(x: rightOffsetX, y: topOffsetY)

            // Q3 右下
            VStack(spacing: itemSpacing) {
                centeredTimerSection(idx: 2, isBlack: true)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
            .offset(x: rightOffsetX, y: bottomOffsetY)

            // Q4 左下
            VStack(spacing: itemSpacing) {
                centeredTimerSection(idx: 3, isBlack: false)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
            .offset(x: leftOffsetX, y: bottomOffsetY)

            // Next Button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button("Next") {
                        Task {
                            await dismissImmersiveSpace()
                            showStep4 = true
                        }

                    }
                    .font(.headline.weight(.bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 10)
                    .padding(.trailing, 24)
                    .padding(.bottom, 40)
                    .disabled(!allFinished())
                }
            }

            // NavigationLink 到 Step4
            NavigationLink(
                destination: GamePlayingStep4View(
                    answers: questions.map { $0.resultText },
                    coins: coins
                ),
                isActive: $showStep4
            ) {
                EmptyView()
            }

        }
        .onAppear {
            SFSpeechRecognizer.requestAuthorization { _ in }
            Task {
                _ = await openImmersiveSpace(id: "Gameroom1")
            }
        }
    }

    private func allFinished() -> Bool {
        return questions.allSatisfy { $0.status == .finished }
    }

    @ViewBuilder
    private func centeredTimerSection(idx: Int, isBlack: Bool) -> some View {
        let q = questions[idx]
        let rewardCoins = [100, 300, 500, 900]

        VStack(spacing: 4) {
            Text("Q\(idx+1) Timer")
                .font(.title2)
                .foregroundColor(isBlack ? .black : .white)
                .multilineTextAlignment(.center)

            Text("\(String(format: "%02d:%02d", q.timer/60, q.timer%60))")
                .font(.title2.monospacedDigit())
                .foregroundColor(isBlack ? .black : .white)
                .multilineTextAlignment(.center)

            Button(action: {
                handleButtonPress(idx: idx, reward: rewardCoins[idx])
            }) {
                Text(buttonTitle(for: q.status))
                    .font(.title2)
                    .foregroundColor((idx == 0 || idx == 2) ? .black : .white)
                    .multilineTextAlignment(.center)
            }
            .disabled(q.status == .finished)
        }
    }

    private func buttonTitle(for status: ButtonStatus) -> String {
        switch status {
        case .ready: return "Answer"
        case .recording: return "Stop"
        case .finished: return "Finished"
        }
    }

    private func handleButtonPress(idx: Int, reward: Int) {
        switch questions[idx].status {
        case .ready:
            questions[idx].status = .recording
            startTimer(idx: idx)
            startRecording(idx: idx)
        case .recording:
            stopRecording(idx: idx)
            finishQuestion(idx: idx, reward: reward)
        default:
            break
        }
    }

    private func startTimer(idx: Int) {
        questions[idx].timerTask?.invalidate()
        questions[idx].timer = 0

        questions[idx].timerTask = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            questions[idx].timer += 1
        }
    }

    private func startRecording(idx: Int) {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true)
        } catch {
            print("❌ AudioSession fail:", error)
            return
        }

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let req = recognitionRequest else { return }
        req.shouldReportPartialResults = true

        let inputNode = audioEngine.inputNode
        let hwFormat = inputNode.outputFormat(forBus: 0)

        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: hwFormat) { buffer, _ in
            req.append(buffer)
        }

        recognitionTask = speechRecognizer?.recognitionTask(with: req) { result, _ in
            if let r = result {
                questions[idx].resultText = r.bestTranscription.formattedString
            }
        }

        audioEngine.prepare()
        do { try audioEngine.start() } catch {
            print("❌ audioEngine start fail:", error)
        }
    }

    private func stopRecording(idx: Int) {
        audioEngine.stop()
        recognitionRequest?.endAudio()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionTask?.finish()
    }

    private func finishQuestion(idx: Int, reward: Int) {
        questions[idx].status = .finished
        questions[idx].timerTask?.invalidate()
        coins += reward
    }
}
