import SwiftUI

struct GamePlayingStep4View: View {
    // Step3 傳進來的四題結果 + coins
    let answers: [String]
    let coins: Int
    
    // API Key 固定寫死
    private let deepseekAPIKey = "sk-53279b4b332740668d7cfacc9f37257f"
    private let deepseekURL = URL(string: "https://api.deepseek.com/chat/completions")!
    
    // UI state
    @State private var grades: [String] = Array(repeating: "?", count: 4)
    @State private var feedbacks: [String] = Array(repeating: "No feedback.", count: 4)
    @State private var improvementTips: [String] = Array(repeating: "", count: 4)
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            Image("Game_playing_step4")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                
                // 🔹 Top Bar Coins 顯示
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
                .padding(.top, 1)
                
                Spacer().frame(height: 10)
                
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(0..<4, id: \.self) { idx in
                            ResultRowView(
                                questionText: questionTitle(idx: idx),
                                grade: grades[idx],
                                feedback: feedbacks[idx],
                                improvementTip: improvementTips[idx],
                                isDark: idx % 2 == 1
                            )
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 23)
                }
                
                Spacer()
            }
            
            // 🔹 Back Button 右下角
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button {
                        // 連續 dismiss 兩層
                        dismiss()
                        dismiss()
                    } label: {
                        HStack(spacing: 8) {
                            Text("Back")
                        }
                        .font(.headline.weight(.bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 10)
                    }
                    .padding(.trailing, 24)
                    .padding(.bottom, 70)
                }
            }
        }
        .onAppear {
            analyzeAllAnswers()
        }
    }
    
    private func questionTitle(idx: Int) -> String {
        switch idx {
        case 0: return "Q1: Tell me about yourself."
        case 1: return "Q2: Why do you want to work here?"
        case 2: return "Q3: Why do you want this position?"
        case 3: return "Q4: Why are you leaving current job?"
        default: return ""
        }
    }
    
    private func analyzeAllAnswers() {
        for i in 0..<answers.count {
            analyzeAnswer(idx: i, text: answers[i])
        }
    }
    
    private func analyzeAnswer(idx: Int, text: String) {
        guard !text.isEmpty else {
            grades[idx] = "F"
            feedbacks[idx] = "No answer provided."
            return
        }
        
        var request = URLRequest(url: deepseekURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(deepseekAPIKey)", forHTTPHeaderField: "Authorization")
        
        let body: [String: Any] = [
            "model": "deepseek-chat",
            "messages": [
                [
                    "role": "system",
                    "content": "You are an interviewer assistant. Analyze the answer. Reply in exactly 3 lines:\nLine 1: Grade: (A/B/C/D)\nLine 2: Feedback: (30-35 words feedback)\nLine 3: Tip: (a short ~20 word tip on how to improve to the next higher grade. If grade is A, say 'Great job! Keep it up.')"
                ],
                [
                    "role": "user",
                    "content": "Question: \(questionTitle(idx: idx)) Answer: \(text)"
                ]
            ]
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            print("❌ JSON create fail:", error)
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error {
                print("❌ API error:", error)
                DispatchQueue.main.async {
                    grades[idx] = "ERR"
                    feedbacks[idx] = "Feedback failed."
                }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    grades[idx] = "?"
                    feedbacks[idx] = "No response."
                }
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let choices = json["choices"] as? [[String: Any]],
                   let message = choices.first?["message"] as? [String: Any],
                   let content = message["content"] as? String {
                    
                    let lines = content.components(separatedBy: "\n").filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
                    
                    let rawGrade = lines.first ?? ""
                    let extractedGrade = rawGrade
                        .replacingOccurrences(of: "Grade:", with: "")
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    // Extract feedback and tip from structured response
                    var fb = ""
                    var tip = ""
                    for line in lines.dropFirst() {
                        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                        if trimmed.lowercased().hasPrefix("tip:") {
                            tip = trimmed
                                .replacingOccurrences(of: "Tip:", with: "", options: .caseInsensitive)
                                .trimmingCharacters(in: .whitespacesAndNewlines)
                        } else if trimmed.lowercased().hasPrefix("feedback:") {
                            fb = trimmed
                                .replacingOccurrences(of: "Feedback:", with: "", options: .caseInsensitive)
                                .trimmingCharacters(in: .whitespacesAndNewlines)
                        } else if fb.isEmpty {
                            fb = trimmed
                        }
                    }
                    
                    DispatchQueue.main.async {
                        grades[idx] = extractedGrade.isEmpty ? "?" : extractedGrade
                        
                        let words = fb.split(separator: " ")
                        if words.count > 35 {
                            let truncated = words.prefix(35).joined(separator: " ")
                            feedbacks[idx] = truncated
                        } else if fb.isEmpty {
                            feedbacks[idx] = "No feedback."
                        } else {
                            feedbacks[idx] = fb
                        }
                        
                        // Set improvement tip
                        if tip.isEmpty {
                            improvementTips[idx] = improvementTipFallback(for: extractedGrade)
                        } else {
                            improvementTips[idx] = tip
                        }
                    }
                    
                } else {
                    DispatchQueue.main.async {
                        grades[idx] = "?"
                        feedbacks[idx] = "Parse error."
                    }
                }
            } catch {
                print("❌ JSON parse fail:", error)
                DispatchQueue.main.async {
                    grades[idx] = "?"
                    feedbacks[idx] = "Parse failed."
                }
            }
        }.resume()
    }
    
    /// Fallback improvement tip when DeepSeek does not return one
    private func improvementTipFallback(for grade: String) -> String {
        switch grade.uppercased() {
        case "A":
            return "Great job! Keep up the excellent work."
        case "B":
            return "Add more specific examples to reach A."
        case "C":
            return "Expand details and show genuine interest to reach B."
        case "D":
            return "Be more professional and provide concrete answers to reach C."
        default:
            return ""
        }
    }
}

fileprivate struct ResultRowView: View {
    let questionText: String
    let grade: String
    let feedback: String
    let improvementTip: String
    let isDark: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Text(grade)
                .font(.system(size: 42, weight: .bold))
                .foregroundColor(.red)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(questionText)
                    .font(.headline)
                    .foregroundColor(isDark ? .white : .black)
                
                Text(feedback)
                    .font(.headline)
                    .foregroundColor(.red)
                    .lineLimit(2)
                
                if !improvementTip.isEmpty {
                    Text("💡 \(improvementTip)")
                        .font(.subheadline)
                        .foregroundColor(.orange)
                        .lineLimit(2)
                }
            }
            Spacer()
        }
        .padding()
        .background(isDark ? Color.black.opacity(0.7) : Color.white.opacity(0.8))
        .cornerRadius(12)
    }
}
