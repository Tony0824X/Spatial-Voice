import Foundation

struct VocalAnalysisResult: Codable {
    let score: Int       // 0...10
    let feedback: String // ~20 English words
}

enum DeepSeekClient {
    // ✅ 你自己填入（建議用 .xcconfig/Keychain，不要硬寫在 public repo）
    static let apiKey = "sk-3e95370d7f334abea905de01e68a24ac"

    // OpenAI-compatible endpoint (可能要按你帳戶調整)
    static let baseURL = URL(string: "https://api.deepseek.com/v1/chat/completions")!
    static let model = "deepseek-chat"

    struct Message: Codable {
        let role: String
        let content: String
    }

    struct RequestBody: Codable {
        let model: String
        let messages: [Message]
        let temperature: Double
        let max_tokens: Int
        let response_format: ResponseFormat?

        struct ResponseFormat: Codable {
            let type: String // "json_object"
        }
    }

    struct ResponseBody: Codable {
        struct Choice: Codable {
            struct Msg: Codable {
                let role: String
                let content: String
            }
            let message: Msg
        }
        let choices: [Choice]
    }

    /// Send vocal-only features to DeepSeek and get {score, feedback} in JSON.
    static func analyzeVocal(
        transcript: String,
        duration: Double,
        wpm: Double,
        avgDB: Double,
        maxDB: Double,
        samples: [VoiceSample]
    ) async throws -> VocalAnalysisResult {

        // Downsample samples in case it's huge
        let compact = downsample(samples, targetCount: 180)

        // Extract simple stats from samples (vocal-only)
        let dbValues = compact.map { $0.db }
        let dbMin = dbValues.min() ?? -80
        let dbMax = dbValues.max() ?? -80
        let dbRange = dbMax - dbMin

        let payload = """
        VOCAL FEATURES (no semantic judging):
        - duration_sec: \(String(format: "%.2f", duration))
        - wpm: \(String(format: "%.2f", wpm))
        - avg_db: \(String(format: "%.2f", avgDB))
        - max_db: \(String(format: "%.2f", maxDB))
        - min_db: \(String(format: "%.2f", dbMin))
        - range_db: \(String(format: "%.2f", dbRange))
        - sample_points: \(compact.count)
        - transcript_text (for pacing only, ignore content): \(transcript)
        """

        let systemPrompt = """
        You are a vocal coach. Only evaluate VOCAL delivery (volume stability, clarity proxy via pace, consistency, pauses implied by loudness dips).
        Do NOT evaluate the meaning/content of the transcript.
        Return STRICT JSON with keys: score (integer 0-10), feedback (about 20 English words).
        feedback must be concise, actionable, and only about vocal info.
        """

        let userPrompt = """
        Analyze the vocal features below and produce the JSON result.
        \(payload)
        """

        let body = RequestBody(
            model: model,
            messages: [
                Message(role: "system", content: systemPrompt),
                Message(role: "user", content: userPrompt)
            ],
            temperature: 0.2,
            max_tokens: 120,
            response_format: .init(type: "json_object")
        )

        var req = URLRequest(url: baseURL)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        req.httpBody = try JSONEncoder().encode(body)

        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse else {
            throw NSError(domain: "DeepSeek", code: 0, userInfo: [NSLocalizedDescriptionKey: "No HTTP response"])
        }
        guard (200...299).contains(http.statusCode) else {
            let text = String(data: data, encoding: .utf8) ?? "(no body)"
            throw NSError(domain: "DeepSeek", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: text])
        }

        let decoded = try JSONDecoder().decode(ResponseBody.self, from: data)
        guard let content = decoded.choices.first?.message.content else {
            throw NSError(domain: "DeepSeek", code: 0, userInfo: [NSLocalizedDescriptionKey: "Empty response"])
        }

        // content is JSON string, decode again
        guard let jsonData = content.data(using: .utf8) else {
            throw NSError(domain: "DeepSeek", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON content"])
        }

        let result = try JSONDecoder().decode(VocalAnalysisResult.self, from: jsonData)
        let clampedScore = min(max(result.score, 0), 10)
        return VocalAnalysisResult(score: clampedScore, feedback: result.feedback)
    }

    private static func downsample(_ samples: [VoiceSample], targetCount: Int) -> [VoiceSample] {
        guard targetCount > 1, samples.count > targetCount else { return samples }
        let step = Double(samples.count - 1) / Double(targetCount - 1)
        return (0..<targetCount).map { i in
            samples[Int(round(Double(i) * step))]
        }
    }

    // MARK: - Body Language Analysis

    struct BodyLanguageAnalysisResult: Codable {
        let score: Int       // 0...10
        let feedback: String // ~20 English words
    }

    /// Send hand movement features to DeepSeek and get {score, feedback} in JSON.
    static func analyzeBodyLanguage(
        duration: Double,
        avgLeftFreq: Double,
        avgRightFreq: Double,
        maxLeftFreq: Double,
        maxRightFreq: Double,
        samples: [HandMovementSample]
    ) async throws -> BodyLanguageAnalysisResult {

        // Downsample if too many points
        let compact = downsampleHandMovement(samples, targetCount: 180)

        let leftVals = compact.map { $0.leftFreq }
        let rightVals = compact.map { $0.rightFreq }

        let payload = """
        HAND MOVEMENT FEATURES:
        - duration_sec: \(String(format: "%.2f", duration))
        - avg_left_hand_speed_m_s: \(String(format: "%.4f", avgLeftFreq))
        - avg_right_hand_speed_m_s: \(String(format: "%.4f", avgRightFreq))
        - max_left_hand_speed_m_s: \(String(format: "%.4f", maxLeftFreq))
        - max_right_hand_speed_m_s: \(String(format: "%.4f", maxRightFreq))
        - left_hand_range: \(String(format: "%.4f", (leftVals.max() ?? 0) - (leftVals.min() ?? 0)))
        - right_hand_range: \(String(format: "%.4f", (rightVals.max() ?? 0) - (rightVals.min() ?? 0)))
        - sample_points: \(compact.count)
        """

        let systemPrompt = """
        You are a body language coach specializing in hand gestures during presentations.
        Evaluate the hand movement data: consistency, symmetry between left/right, appropriate movement level (not too still, not too fidgety).
        Ideal presenters use purposeful gestures with moderate movement speed.
        Return STRICT JSON with keys: score (integer 0-10), feedback (about 20 English words).
        feedback must be concise, actionable, and only about hand movement patterns.
        """

        let userPrompt = """
        Analyze the hand movement features below and produce the JSON result.
        \(payload)
        """

        let body = RequestBody(
            model: model,
            messages: [
                Message(role: "system", content: systemPrompt),
                Message(role: "user", content: userPrompt)
            ],
            temperature: 0.2,
            max_tokens: 120,
            response_format: .init(type: "json_object")
        )

        var req = URLRequest(url: baseURL)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        req.httpBody = try JSONEncoder().encode(body)

        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse else {
            throw NSError(domain: "DeepSeek", code: 0, userInfo: [NSLocalizedDescriptionKey: "No HTTP response"])
        }
        guard (200...299).contains(http.statusCode) else {
            let text = String(data: data, encoding: .utf8) ?? "(no body)"
            throw NSError(domain: "DeepSeek", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: text])
        }

        let decoded = try JSONDecoder().decode(ResponseBody.self, from: data)
        guard let content = decoded.choices.first?.message.content else {
            throw NSError(domain: "DeepSeek", code: 0, userInfo: [NSLocalizedDescriptionKey: "Empty response"])
        }

        guard let jsonData = content.data(using: .utf8) else {
            throw NSError(domain: "DeepSeek", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON content"])
        }

        let result = try JSONDecoder().decode(BodyLanguageAnalysisResult.self, from: jsonData)
        let clampedScore = min(max(result.score, 0), 10)
        return BodyLanguageAnalysisResult(score: clampedScore, feedback: result.feedback)
    }

    private static func downsampleHandMovement(_ samples: [HandMovementSample], targetCount: Int) -> [HandMovementSample] {
        guard targetCount > 1, samples.count > targetCount else { return samples }
        let step = Double(samples.count - 1) / Double(targetCount - 1)
        return (0..<targetCount).map { i in
            samples[Int(round(Double(i) * step))]
        }
    }
}
