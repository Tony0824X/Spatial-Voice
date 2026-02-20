// DeepSeekAnalyzer.swift
import Foundation

/// 用 DeepSeek API 分析簡報表現（script + slides + marking scheme + time）
final class DeepSeekAnalyzer {
    static let shared = DeepSeekAnalyzer()

    // TODO: 把下面這行改成你的實際 DeepSeek API Key
    // 建議：正式版唔好直接寫死喺程式碼入面，可以之後搬去設定檔 / Keychain
    private let apiKey: String = "sk-53279b4b332740668d7cfacc9f37257f"

    private init() {}

    // MARK: - Public
    func analyze(session: PresentationSession) async {
        await MainActor.run {
            session.isAnalyzing = true
            session.resetResults()
        }

        defer {
            Task { @MainActor in
                session.isAnalyzing = false
            }
        }

        let prompt = buildPrompt(from: session)
        guard !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            await MainActor.run {
                session.overallComment = "No data for analysis."
            }
            return
        }

        do {
            async let mainResult = try? callDeepSeek(prompt: prompt)
            
            let duration = Double(session.actualUsedSeconds)
            let wordCount = session.liveSpokenText.split(whereSeparator: { $0.isWhitespace || $0.isNewline }).count
            let wpm = duration > 0 ? (Double(wordCount) / duration * 60.0) : 0
            
            async let vocalResult = try? DeepSeekClient.analyzeVocal(
                transcript: session.liveSpokenText,
                duration: duration,
                wpm: wpm,
                avgDB: session.avgDB,
                maxDB: session.maxDB,
                samples: session.voiceSamples
            )
            
            async let bodyResult = try? DeepSeekClient.analyzeBodyLanguage(
                duration: duration,
                avgLeftFreq: session.avgLeftFreq,
                avgRightFreq: session.avgRightFreq,
                maxLeftFreq: session.maxLeftFreq,
                maxRightFreq: session.maxRightFreq,
                samples: session.handSamples
            )

            let mainRes = await mainResult
            let vRes = await vocalResult
            let bRes = await bodyResult
            
            let analysis = (mainRes != nil) ? (try? decodeAnalysis(from: mainRes!)) : nil

            await MainActor.run {
                if let a = analysis {
                    // 1. 把 4 個自動評分項目套入 UI
                    session.scoreVerbalContent       = a.scores.verbalContent
                    session.scoreVisualAids          = a.scores.visualAidsSlides
                    session.scoreTimeManagement      = a.scores.timeManagement
                    session.scoreAudienceEngagement  = a.scores.audienceEngagement

                    session.overallScore             = a.scores.overall
                    session.overallComment           = a.scores.overallComment

                    // 2. 4 個面向文字建議（DetailFeedbackView 用）
                    session.feedbackVerbalContent    = a.feedback.verbalContent ?? ""
                    session.feedbackVisualAids       = a.feedback.visualAidsSlides ?? ""
                    session.feedbackTimeManagement   = a.feedback.timeManagement ?? ""
                    session.feedbackAudienceEngagement = a.feedback.audienceEngagement ?? ""
                    
                    // Optional fallback
                    if vRes == nil {
                        session.scoreVocalDelivery = a.scores.vocalDelivery
                        if let val = a.scores.vocalDelivery {
                            session.scoreVocalDeliveryLabel = String(format: "%.1f", val)
                        }
                        session.feedbackVocalDelivery = a.feedback.vocalDelivery ?? ""
                    }
                    if bRes == nil {
                        session.scoreNonverbal = a.scores.nonverbalBodyLanguage
                        if let val = a.scores.nonverbalBodyLanguage {
                            session.scoreNonverbalLabel = String(format: "%.1f", val)
                        }
                        session.feedbackNonverbal = a.feedback.nonverbalBodyLanguage ?? ""
                    }
                }

                if let v = vRes {
                    session.scoreVocalDelivery = Double(v.score)
                    session.scoreVocalDeliveryLabel = String(format: "%.1f", Double(v.score))
                    session.feedbackVocalDelivery = v.feedback
                }
                
                if let b = bRes {
                    session.scoreNonverbal = Double(b.score)
                    session.scoreNonverbalLabel = String(format: "%.1f", Double(b.score))
                    session.feedbackNonverbal = b.feedback
                }

                // 3. 儲存一條「Practice Record」去 History（完整 6 分）
                session.addPracticeRecordFromCurrentScores()
            }
        }
    }

    // MARK: - Prompt 構造

    /// 根據當前 session 內容，組合一段 prompt 俾 DeepSeek
    private func buildPrompt(from session: PresentationSession) -> String {
        // 防止 prompt 太長，簡單用 prefix 限制
        let script  = session.scriptText.prefix(8000)
        let slides  = session.slidesText.prefix(8000)
        let marking = session.markingText.prefix(8000)

        var components: [String] = []
        components.append("You are an experienced public speaking coach.")
        components.append("You will receive the student's speech script, slides text and marking scheme, plus timing data.")
        components.append("Evaluate the presentation on six aspects, each scored from 0 to 10:")
        components.append("1) verbal_content, 2) visual_aids_slides, 3) time_management, 4) audience_engagement, 5) vocal_delivery, 6) nonverbal_body_language.")
        components.append("Also compute an overall score (0–10) and a short overall_comment (two words, like 'Well Done').")
        components.append("Then give about 20 English words of feedback for EACH of the six aspects.")
        components.append("Return ONLY a single JSON object with this structure:\n")
        components.append("""
        {
          "scores": {
            "verbal_content": 0-10 number,
            "visual_aids_slides": 0-10 number,
            "time_management": 0-10 number,
            "audience_engagement": 0-10 number,
            "vocal_delivery": always return number 0,
            "nonverbal_body_language": always return number 0,
            "overall": 0-10 number,
            "overall_comment": "short phrase"
          },
          "feedback": {
            "verbal_content": "about 20 English words of feedback",
            "visual_aids_slides": "about 20 English words of feedback",
            "time_management": "about 20 English words of feedback",
            "audience_engagement": "about 20 English words of feedback",
            "vocal_delivery": "return null here",
            "nonverbal_body_language": "return null here"
          }
        }
        """)

        components.append("Timing data:")
        components.append("Target duration (minutes): \(session.durationMinutes)")
        components.append("Actual used seconds: \(session.actualUsedSeconds)")

        if !script.isEmpty {
            components.append("\nSpeech script text:\n\(script)")
        }
        if !slides.isEmpty {
            components.append("\nSlides text or OCR content:\n\(slides)")
        }
        if !marking.isEmpty {
            components.append("\nMarking scheme text:\n\(marking)")
        }

        return components.joined(separator: "\n\n")
    }

    // MARK: - DeepSeek HTTP 呼叫

    private func callDeepSeek(prompt: String) async throws -> String {
        guard !apiKey.isEmpty else {
            throw NSError(
                domain: "DeepSeekAnalyzer",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Missing API key"]
            )
        }

        // DeepSeek 官方 chat completions endpoint
        guard let url = URL(string: "https://api.deepseek.com/chat/completions") else {
            throw NSError(
                domain: "DeepSeekAnalyzer",
                code: -2,
                userInfo: [NSLocalizedDescriptionKey: "Invalid URL"]
            )
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let body = ChatRequest(
            model: "deepseek-chat",
            messages: [
                .init(role: "system", content: "You are a helpful assistant and public speaking coach."),
                .init(role: "user", content: prompt)
            ],
            max_tokens: 800,
            temperature: 0.4,
            response_format: .init(type: "json_object")
        )

        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)

        if let http = response as? HTTPURLResponse, http.statusCode >= 300 {
            let bodyString = String(data: data, encoding: .utf8) ?? ""
            throw NSError(
                domain: "DeepSeekAnalyzer",
                code: http.statusCode,
                userInfo: [NSLocalizedDescriptionKey: "HTTP \(http.statusCode): \(bodyString)"]
            )
        }

        let decoded = try JSONDecoder().decode(ChatResponse.self, from: data)
        guard let content = decoded.choices.first?.message.content else {
            throw NSError(
                domain: "DeepSeekAnalyzer",
                code: -3,
                userInfo: [NSLocalizedDescriptionKey: "No content in response"]
            )
        }
        return content
    }

    // MARK: - JSON 解析

    private func decodeAnalysis(from jsonString: String) throws -> PresentationAnalysis {
        let data = Data(jsonString.utf8)
        let decoder = JSONDecoder()
        return try decoder.decode(PresentationAnalysis.self, from: data)
    }
}

// MARK: - 型別定義（同你之前一樣）

private struct ChatRequest: Encodable {
    struct Message: Encodable {
        let role: String
        let content: String
    }

    struct ResponseFormat: Encodable {
        let type: String
    }

    let model: String
    let messages: [Message]
    let max_tokens: Int
    let temperature: Double
    let response_format: ResponseFormat
}

private struct ChatResponse: Decodable {
    struct Choice: Decodable {
        struct Message: Decodable {
            let role: String
            let content: String
        }
        let message: Message
    }
    let choices: [Choice]
}

private struct PresentationAnalysis: Decodable {
    struct Scores: Decodable {
        let verbalContent: Double?
        let visualAidsSlides: Double?
        let timeManagement: Double?
        let audienceEngagement: Double?
        let vocalDelivery: Double?
        let nonverbalBodyLanguage: Double?
        let overall: Double?
        let overallComment: String?

        private enum CodingKeys: String, CodingKey {
            case verbalContent          = "verbal_content"
            case visualAidsSlides       = "visual_aids_slides"
            case timeManagement         = "time_management"
            case audienceEngagement     = "audience_engagement"
            case vocalDelivery          = "vocal_delivery"
            case nonverbalBodyLanguage  = "nonverbal_body_language"
            case overall
            case overallComment         = "overall_comment"
        }
    }

    struct Feedback: Decodable {
        let verbalContent: String?
        let visualAidsSlides: String?
        let timeManagement: String?
        let audienceEngagement: String?
        let vocalDelivery: String?
        let nonverbalBodyLanguage: String?

        private enum CodingKeys: String, CodingKey {
            case verbalContent          = "verbal_content"
            case visualAidsSlides       = "visual_aids_slides"
            case timeManagement         = "time_management"
            case audienceEngagement     = "audience_engagement"
            case vocalDelivery          = "vocal_delivery"
            case nonverbalBodyLanguage  = "nonverbal_body_language"
        }
    }

    let scores: Scores
    let feedback: Feedback
}
