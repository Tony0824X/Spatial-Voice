//
//  HandTracker.swift
//  Test_Voice_BodyLang
//
//  Created by Assistant on 16/2/2026.
//

import Foundation
import ARKit
import SwiftUI

// MARK: - Hand Tracker

/// Tracks left and right hand movement using ARKit HandTrackingProvider.
/// Publishes live movement frequency (speed in m/s) for each hand.
@MainActor
final class HandTracker: ObservableObject {
    @Published var isTracking = false
    @Published var liveLeftFreq: Double = 0
    @Published var liveRightFreq: Double = 0
    @Published var liveSamples: [HandMovementSample] = []
    @Published var statusMessage: String = ""

    private var arkitSession = ARKitSession()
    private var handTracking = HandTrackingProvider()
    private var trackingTask: Task<Void, Never>?
    private var eventTask: Task<Void, Never>?

    private var startTime: CFAbsoluteTime = 0

    // Previous hand positions for computing movement delta
    private var prevLeftPos: SIMD3<Float>?
    private var prevRightPos: SIMD3<Float>?
    private var prevLeftTime: CFAbsoluteTime = 0
    private var prevRightTime: CFAbsoluteTime = 0

    // Running accumulators for session stats
    private var leftFreqSum: Double = 0
    private var rightFreqSum: Double = 0
    private var leftFreqMax: Double = 0
    private var rightFreqMax: Double = 0
    private var sampleCount: Int = 0

    // Sampling timer
    private var sampleTimer: Timer?
    private var currentLeftFreq: Double = 0
    private var currentRightFreq: Double = 0

    func start() async throws {
        guard !isTracking else { return }

        // Check support
        let supported = HandTrackingProvider.isSupported
        print("[HandTracker] isSupported = \(supported)")

        // Request authorization explicitly
        let authResult = await arkitSession.requestAuthorization(for: [.handTracking])
        let authStatus = authResult[.handTracking]
        print("[HandTracker] Authorization status = \(String(describing: authStatus))")
        statusMessage = "Auth: \(String(describing: authStatus))"

        guard authStatus == .allowed else {
            statusMessage = "Hand tracking not authorized"
            print("[HandTracker] Hand tracking not authorized")
            throw NSError(domain: "HandTracker", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "Hand tracking not authorized"])
        }

        // Create fresh provider for each session
        let provider = HandTrackingProvider()
        handTracking = provider

        do {
            try await arkitSession.run([provider])
            print("[HandTracker] ARKitSession.run() succeeded")
            statusMessage = "Tracking started"
        } catch {
            print("[HandTracker] ARKitSession.run() failed: \(error)")
            statusMessage = "Failed: \(error.localizedDescription)"
            throw error
        }

        isTracking = true
        startTime = CFAbsoluteTimeGetCurrent()
        prevLeftPos = nil
        prevRightPos = nil
        liveSamples.removeAll()
        leftFreqSum = 0
        rightFreqSum = 0
        leftFreqMax = 0
        rightFreqMax = 0
        sampleCount = 0
        liveLeftFreq = 0
        liveRightFreq = 0

        // Monitor session events for errors
        eventTask = Task {
            for await event in arkitSession.events {
                switch event {
                case .authorizationChanged(let type, let status):
                    print("[HandTracker] Auth changed: \(type) -> \(status)")
                    if type == .handTracking && status != .allowed {
                        statusMessage = "Auth revoked"
                    }
                case .dataProviderStateChanged(_, let newState, let error):
                    print("[HandTracker] Provider state changed: \(newState), error: \(String(describing: error))")
                    statusMessage = "State: \(newState)"
                @unknown default:
                    break
                }
            }
        }

        // Collect hand anchor updates — capture provider directly
        trackingTask = Task {
            print("[HandTracker] Starting anchor update loop")
            var updateCount = 0
            for await update in provider.anchorUpdates {
                guard !Task.isCancelled else { break }
                updateCount += 1
                if updateCount <= 10 {
                    print("[HandTracker] Update #\(updateCount): chirality=\(update.anchor.chirality) tracked=\(update.anchor.isTracked)")
                }
                processAnchor(update.anchor)
            }
            print("[HandTracker] Loop ended after \(updateCount) updates")
        }

        // Delay 0.5 second before recording to skip initial noise
        Task {
            try? await Task.sleep(nanoseconds: 500_000_000)
            guard self.isTracking else { return }

            // Reset start time so chart begins from t=0 after warmup
            self.startTime = CFAbsoluteTimeGetCurrent()
            self.statusMessage = "Recording..."

            // Sample at 5 Hz for chart data
            self.sampleTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.recordSample()
                }
            }
        }
    }

    func stop() -> BodyLanguageSession? {
        guard isTracking else { return nil }
        isTracking = false

        trackingTask?.cancel()
        trackingTask = nil
        eventTask?.cancel()
        eventTask = nil
        sampleTimer?.invalidate()
        sampleTimer = nil

        arkitSession.stop()

        let duration = CFAbsoluteTimeGetCurrent() - startTime
        guard sampleCount > 0 else {
            print("[HandTracker] No samples recorded")
            return nil
        }

        let avgLeft = leftFreqSum / Double(sampleCount)
        let avgRight = rightFreqSum / Double(sampleCount)

        print("[HandTracker] Done: \(duration)s, \(sampleCount) samples, avgL=\(avgLeft), avgR=\(avgRight)")

        let session = BodyLanguageSession(
            id: UUID().uuidString,
            createdAt: Date(),
            duration: duration,
            avgLeftFreq: avgLeft,
            avgRightFreq: avgRight,
            maxLeftFreq: leftFreqMax,
            maxRightFreq: rightFreqMax,
            samples: liveSamples
        )

        try? BodyLanguageStore.saveSession(session)
        return session
    }

    // MARK: - Private

    private func processAnchor(_ anchor: HandAnchor) {
        guard anchor.isTracked else { return }

        let transform = anchor.originFromAnchorTransform
        let pos = SIMD3<Float>(
            transform.columns.3.x,
            transform.columns.3.y,
            transform.columns.3.z
        )
        let now = CFAbsoluteTimeGetCurrent()

        switch anchor.chirality {
        case .left:
            if let prevPos = prevLeftPos {
                let dt = now - prevLeftTime
                if dt > 0.001 {
                    let dist = distance(pos, prevPos)
                    let speed = Double(dist) / dt
                    currentLeftFreq = speed
                    liveLeftFreq = speed
                }
            }
            prevLeftPos = pos
            prevLeftTime = now

        case .right:
            if let prevPos = prevRightPos {
                let dt = now - prevRightTime
                if dt > 0.001 {
                    let dist = distance(pos, prevPos)
                    let speed = Double(dist) / dt
                    currentRightFreq = speed
                    liveRightFreq = speed
                }
            }
            prevRightPos = pos
            prevRightTime = now
        }
    }

    private func recordSample() {
        guard isTracking else { return }

        let t = CFAbsoluteTimeGetCurrent() - startTime
        let sample = HandMovementSample(
            t: t,
            leftFreq: currentLeftFreq,
            rightFreq: currentRightFreq
        )
        liveSamples.append(sample)

        leftFreqSum += currentLeftFreq
        rightFreqSum += currentRightFreq
        leftFreqMax = max(leftFreqMax, currentLeftFreq)
        rightFreqMax = max(rightFreqMax, currentRightFreq)
        sampleCount += 1
    }
}
