// PresentationSession.swift
import Foundation

// MARK: - Practice Record（Class Presentation 練習記錄）

/// 一次 Class Presentation 練習嘅記錄（用喺 History 畫面「Public Speaking Practice」）
/// 儲存 AI 評分結果 + 日期時間（完整 6 個分數 + overall）
struct PracticeRecord: Identifiable, Hashable {
    let id: UUID
    let date: Date

    /// 情境名稱（例如 "Class Presentation"）
    let scenarioTitle: String

    /// 六個面向分數（0–10）
    let verbalScore: Double
    let visualScore: Double
    let timeScore: Double
    let audienceScore: Double
    let vocalScore: Double
    let nonverbalScore: Double

    /// Overall 分數 + 短評（例如 "Great", "Needs work"）
    let overall: Double
    let overallComment: String

    /// 方便 History UI 顯示時間
    var formattedDate: String {
        let df = DateFormatter()
        df.dateFormat = "d/M/yyyy\nhh:mm a"
        return df.string(from: date)
    }

    /// History UI 用嚟顯示 Vocal / Non-verbal Label
    var vocalLabel: String {
        String(format: "%.1f", vocalScore)
    }

    var nonverbalLabel: String {
        String(format: "%.1f", nonverbalScore)
    }
}

// MARK: - Game / Certificate 假資料用 Record

struct GameRecord: Identifiable, Hashable {
    let id: UUID
    let date: Date
    let title: String
    let imageName: String
    let modeLabel: String      // 例如 "Time Attack", "Story Mode"
    let bestScore: Int
}

struct CertificateRecord: Identifiable, Hashable {
    let id: UUID
    let date: Date
    let imageName: String
    let trackTitle: String     // 例如 "Story Telling"
    let levelTitle: String     // 例如 "Level 1 • Beginner"
}

// MARK: - PresentationSession

/// 整個練習 Session 嘅狀態容器
final class PresentationSession: ObservableObject {

    // MARK: - 檔案 / OCR 內容

    // Slides (ppt/pdf) & Script (pdf) & Marking Scheme (pdf)
    @Published var slidesURL: URL?
    @Published var scriptURL: URL?
    @Published var markingSchemeURL: URL?

    // 由 VRSetupView 抽出的文字（「OCR」結果）
    @Published var slidesText: String = ""
    @Published var scriptText: String = ""
    @Published var markingText: String = ""

    // MARK: - 練習設定 / 用時

    // 預設練習時間（分鐘），由 VRSetupView 設定
    @Published var durationMinutes: Int = 5

    // 結果頁顯示控制
    @Published var showResult: Bool = false
    @Published var actualUsedSeconds: Int = 0

    var formattedUsedTime: String {
        let m = actualUsedSeconds / 60
        let s = actualUsedSeconds % 60
        return String(format: "%02d:%02d", m, s)
    }

    // MARK: - DeepSeek 分析狀態

    @Published var isAnalyzing: Bool = false

    // MARK: - 分數（0–10）

    /// 4 個 numeric 分數（Result / Detail Feedback 已在用）
    @Published var scoreVerbalContent: Double?
    @Published var scoreVisualAids: Double?
    @Published var scoreTimeManagement: Double?
    @Published var scoreAudienceEngagement: Double?

    /// Vocal / Non-verbal 兩個 numeric 分數（新加，用來儲存 & 之後可顯示）
    @Published var scoreVocalDelivery: Double?
    @Published var scoreNonverbal: Double?

    /// UI 上顯示嘅 Label（例如之前暫時用 "Updating"）
    /// 現在可以改為顯示實際數值（例如 "7.5"），但保留 String 類型不影響既有 UI。
    @Published var scoreVocalDeliveryLabel: String = "Updating"
    @Published var scoreNonverbalLabel: String = "Updating"

    /// Overall
    @Published var overallScore: Double?
    @Published var overallComment: String?

    // MARK: - 詳細建議（每項約 20 字）

    @Published var feedbackVerbalContent: String = ""
    @Published var feedbackVisualAids: String = ""
    @Published var feedbackTimeManagement: String = ""
    @Published var feedbackAudienceEngagement: String = ""
    @Published var feedbackVocalDelivery: String = ""
    @Published var feedbackNonverbal: String = ""

    // MARK: - History：各類紀錄

    /// Public Speaking Practice（Class Presentation）歷史紀錄
    @Published var practiceRecords: [PracticeRecord] = []

    /// Game 假紀錄（History -> Game Tab 用）
    @Published var gameRecords: [GameRecord] = []

    /// Certificate 假紀錄（History -> Certificate Tab 用）
    @Published var certificateRecords: [CertificateRecord] = []

    // MARK: - Init

    init() {
        seedDummyPracticeRecords()
        seedDummyGameRecords()
        seedDummyCertificateRecords()
    }

    // MARK: - Public 方法

    /// DeepSeek 分析完成之後，由 DeepSeekAnalyzer 呼叫：
    ///
    ///   session.addPracticeRecordFromCurrentScores()
    ///
    /// 會用 **目前 UI 上儲存嘅 6 個分數 + overall** 建立一條 Record
    func addPracticeRecordFromCurrentScores() {
        let record = PracticeRecord(
            id: UUID(),
            date: Date(),
            scenarioTitle: "Class Presentation",
            verbalScore: scoreVerbalContent ?? 0.0,
            visualScore: scoreVisualAids ?? 0.0,
            timeScore: scoreTimeManagement ?? 0.0,
            audienceScore: scoreAudienceEngagement ?? 0.0,
            vocalScore: scoreVocalDelivery ?? 0.0,
            nonverbalScore: scoreNonverbal ?? 0.0,
            overall: overallScore ?? 0.0,
            overallComment: overallComment ?? ""
        )

        // 最新紀錄插入最上面
        practiceRecords.insert(record, at: 0)
    }

    /// Result / Detail Feedback 頁面開始新一輪分析前，清空分數 & 文字
    /// ⚠️ 不會清除歷史紀錄
    func resetResults() {
        scoreVerbalContent = nil
        scoreVisualAids = nil
        scoreTimeManagement = nil
        scoreAudienceEngagement = nil
        scoreVocalDelivery = nil
        scoreNonverbal = nil

        overallScore = nil
        overallComment = nil

        feedbackVerbalContent = ""
        feedbackVisualAids = ""
        feedbackTimeManagement = ""
        feedbackAudienceEngagement = ""
        feedbackVocalDelivery = ""
        feedbackNonverbal = ""

        // 顯示文字重設
        scoreVocalDeliveryLabel = "Updating"
        scoreNonverbalLabel = "Updating"
    }

    // MARK: - Dummy Data：Practice / Game / Certificate

    /// 初始兩條「Class Presentation」假紀錄
    private func seedDummyPracticeRecords() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"

        let dates: [Date] = [
            formatter.date(from: "2025-05-12 11:30") ?? Date(),
            formatter.date(from: "2025-04-12 08:30") ?? Date()
        ]

        let r1 = PracticeRecord(
            id: UUID(),
            date: dates[0],
            scenarioTitle: "Class Presentation",
            verbalScore: 7.0,
            visualScore: 8.0,
            timeScore: 8.0,
            audienceScore: 8.0,
            vocalScore: 6.5,
            nonverbalScore: 6.0,
            overall: 7.3,
            overallComment: "Good progress"
        )

        let r2 = PracticeRecord(
            id: UUID(),
            date: dates[1],
            scenarioTitle: "Class Presentation",
            verbalScore: 6.5,
            visualScore: 7.5,
            timeScore: 7.0,
            audienceScore: 7.5,
            vocalScore: 6.0,
            nonverbalScore: 5.5,
            overall: 6.9,
            overallComment: "Needs work"
        )

        practiceRecords = [r1, r2]
    }

    /// Game Tab 用兩條假紀錄（配合你 History UI style）
    private func seedDummyGameRecords() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"

        let g1 = GameRecord(
            id: UUID(),
            date: formatter.date(from: "2025-05-10 14:20") ?? Date(),
            title: "Timing Rush",
            imageName: "Game_pic2_1",
            modeLabel: "Story Mode",
            bestScore: 9800
        )
        let g2 = GameRecord(
            id: UUID(),
            date: formatter.date(from: "2025-05-02 18:10") ?? Date(),
            title: "Confidence Combo",
            imageName: "Game_pic2_2",
            modeLabel: "Story Mode",
            bestScore: 8200
        )

        gameRecords = [g1, g2]
    }

    /// Certificate Tab 用兩條假紀錄
    private func seedDummyCertificateRecords() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        let c1 = CertificateRecord(
            id: UUID(),
            date: formatter.date(from: "2025-03-15") ?? Date(),
            imageName: "Certificates_pic1_1",
            trackTitle: "Story Telling",
            levelTitle: "Level 1 • Beginner"
        )
        let c2 = CertificateRecord(
            id: UUID(),
            date: formatter.date(from: "2025-04-20") ?? Date(),
            imageName: "Certificates_pic2_2",
            trackTitle: "Connect with Audience",
            levelTitle: "Level 2 • Intermediate"
        )

        certificateRecords = [c1, c2]
    }
}
