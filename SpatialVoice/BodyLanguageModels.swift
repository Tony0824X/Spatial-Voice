//
//  BodyLanguageModels.swift
//  Test_Voice_BodyLang
//
//  Created by Assistant on 16/2/2026.
//

import Foundation

// MARK: - Models

/// A single sample capturing hand movement intensity at a point in time.
struct HandMovementSample: Codable {
    let t: Double        // seconds since recording started
    let leftFreq: Double // left hand movement magnitude (m/s)
    let rightFreq: Double // right hand movement magnitude (m/s)
}

/// A completed body language recording session.
struct BodyLanguageSession: Codable, Identifiable {
    let id: String
    let createdAt: Date
    let duration: Double
    let avgLeftFreq: Double
    let avgRightFreq: Double
    let maxLeftFreq: Double
    let maxRightFreq: Double
    let samples: [HandMovementSample]
}

// MARK: - Local Storage

enum BodyLanguageStore {

    private static func documentsURL() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    private static func sessionJSONURL(forSessionID id: String) -> URL {
        documentsURL().appendingPathComponent("bodylang-session-\(id).json")
    }

    static func saveSession(_ session: BodyLanguageSession) throws {
        let url = sessionJSONURL(forSessionID: session.id)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(session)
        try data.write(to: url, options: .atomic)
    }

    static func loadAllSessions() -> [BodyLanguageSession] {
        let dir = documentsURL()
        let items = (try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)) ?? []
        let jsons = items.filter {
            $0.lastPathComponent.hasPrefix("bodylang-session-") && $0.pathExtension == "json"
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        return jsons.compactMap { url in
            guard let data = try? Data(contentsOf: url) else { return nil }
            return try? decoder.decode(BodyLanguageSession.self, from: data)
        }
        .sorted { $0.createdAt > $1.createdAt }
    }

    static func deleteSessionFiles(_ session: BodyLanguageSession) {
        let fm = FileManager.default
        let jsonURL = sessionJSONURL(forSessionID: session.id)
        if fm.fileExists(atPath: jsonURL.path) {
            try? fm.removeItem(at: jsonURL)
        }
    }
}
