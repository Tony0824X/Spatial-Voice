//
//  DualLineChartWithAxes.swift
//  Test_Voice_BodyLang
//
//  Created by Assistant on 16/2/2026.
//

import SwiftUI

// MARK: - Dual Line Chart (Left / Right Hand)

/// A reusable chart component that draws two line series (left hand & right hand)
/// with axis labels and a legend.
struct DualLineChartWithAxes: View {
    let samples: [HandMovementSample]
    let maxY: Double // upper bound for Y axis (m/s)

    private let minY: Double = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Legend
            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    Circle().fill(.blue).frame(width: 8, height: 8)
                    Text("Left Hand").font(.caption)
                }
                HStack(spacing: 4) {
                    Circle().fill(.orange).frame(width: 8, height: 8)
                    Text("Right Hand").font(.caption)
                }
            }
            .foregroundStyle(.secondary)

            // Chart
            GeometryReader { geo in
                let size = geo.size
                let leftPad: CGFloat = 48
                let bottomPad: CGFloat = 22
                let topPad: CGFloat = 6
                let rightPad: CGFloat = 8

                let plotW = max(size.width - leftPad - rightPad, 1)
                let plotH = max(size.height - topPad - bottomPad, 1)

                let plotRect = CGRect(
                    x: leftPad,
                    y: topPad,
                    width: plotW,
                    height: plotH
                )

                ZStack {
                    // Canvas for grid lines + data lines
                    Canvas { context, _ in
                        drawGrid(context: context, rect: plotRect)
                        drawLine(context: context, rect: plotRect, keyPath: \.leftFreq, color: .blue)
                        drawLine(context: context, rect: plotRect, keyPath: \.rightFreq, color: .orange)
                    }

                    // Y-axis labels
                    yAxisLabels(rect: plotRect, leftPad: leftPad)

                    // X-axis labels
                    xAxisLabels(rect: plotRect, bottomPad: bottomPad)
                }
            }
        }
    }

    // MARK: - Drawing helpers

    private func drawGrid(context: GraphicsContext, rect: CGRect) {
        // Horizontal grid lines (4 levels)
        let gridSteps = 4
        for i in 0...gridSteps {
            let frac = Double(i) / Double(gridSteps)
            let y = rect.minY + CGFloat(1 - frac) * rect.height
            var p = Path()
            p.move(to: CGPoint(x: rect.minX, y: y))
            p.addLine(to: CGPoint(x: rect.maxX, y: y))
            context.stroke(p, with: .color(.white.opacity(0.15)), lineWidth: 1)
        }

        // Vertical grid lines
        let gridX: [Double] = [0.0, 0.25, 0.5, 0.75, 1.0]
        for frac in gridX {
            let x = rect.minX + CGFloat(frac) * rect.width
            var p = Path()
            p.move(to: CGPoint(x: x, y: rect.minY))
            p.addLine(to: CGPoint(x: x, y: rect.maxY))
            context.stroke(p, with: .color(.white.opacity(0.10)), lineWidth: 1)
        }
    }

    private func drawLine(
        context: GraphicsContext,
        rect: CGRect,
        keyPath: KeyPath<HandMovementSample, Double>,
        color: Color
    ) {
        let pts = normalizedPoints(rect: rect, keyPath: keyPath)
        guard pts.count > 1 else { return }

        var line = Path()
        line.move(to: pts[0])
        for pt in pts.dropFirst() {
            line.addLine(to: pt)
        }
        context.stroke(line, with: .color(color), lineWidth: 2)
    }

    private func normalizedPoints(
        rect: CGRect,
        keyPath: KeyPath<HandMovementSample, Double>
    ) -> [CGPoint] {
        guard samples.count > 1 else { return [] }
        let minT = samples.first!.t
        let maxT = samples.last!.t
        let tRange = max(maxT - minT, 0.0001)
        let yRange = max(maxY - minY, 0.0001)

        return samples.map { s in
            let x01 = (s.t - minT) / tRange
            let val = min(max(s[keyPath: keyPath], minY), maxY)
            let y01 = (val - minY) / yRange

            let x = rect.minX + CGFloat(x01) * rect.width
            let y = rect.minY + (1 - CGFloat(y01)) * rect.height
            return CGPoint(x: x, y: y)
        }
    }

    @ViewBuilder
    private func yAxisLabels(rect: CGRect, leftPad: CGFloat) -> some View {
        VStack(alignment: .trailing, spacing: 0) {
            Text(String(format: "%.1f", maxY))
            Spacer()
            Text(String(format: "%.1f", maxY * 0.75))
            Spacer()
            Text(String(format: "%.1f", maxY * 0.5))
            Spacer()
            Text(String(format: "%.1f", maxY * 0.25))
            Spacer()
            Text("0.0")
        }
        .font(.caption2)
        .foregroundStyle(.secondary)
        .frame(width: leftPad - 6, height: rect.height)
        .position(x: (leftPad - 6) / 2, y: rect.midY)
    }

    @ViewBuilder
    private func xAxisLabels(rect: CGRect, bottomPad: CGFloat) -> some View {
        let duration = max((samples.last?.t ?? 0), 0)
        HStack {
            Text("0s")
            Spacer()
            Text("\(Int(duration * 0.25))s")
            Spacer()
            Text("\(Int(duration * 0.50))s")
            Spacer()
            Text("\(Int(duration * 0.75))s")
            Spacer()
            Text("\(Int(duration))s")
        }
        .font(.caption2)
        .foregroundStyle(.secondary)
        .frame(width: rect.width)
        .position(x: rect.midX, y: rect.maxY + bottomPad / 2)
    }
}

// MARK: - Live Dual Line Chart (with axes)

/// Live display for hand movement with Y-axis (m/s) and X-axis (time) labels.
struct LiveDualLineChart: View {
    let samples: [HandMovementSample]
    let maxY: Double

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            let leftPad: CGFloat = 40
            let bottomPad: CGFloat = 22
            let topPad: CGFloat = 4
            let rightPad: CGFloat = 4

            let plotW = max(size.width - leftPad - rightPad, 1)
            let plotH = max(size.height - topPad - bottomPad, 1)
            let plotRect = CGRect(x: leftPad, y: topPad, width: plotW, height: plotH)

            ZStack {
                Canvas { context, _ in
                    // Grid lines
                    for i in 0...4 {
                        let frac = Double(i) / 4.0
                        let y = plotRect.minY + CGFloat(1 - frac) * plotRect.height
                        var p = Path()
                        p.move(to: CGPoint(x: plotRect.minX, y: y))
                        p.addLine(to: CGPoint(x: plotRect.maxX, y: y))
                        context.stroke(p, with: .color(.white.opacity(0.12)), lineWidth: 0.5)
                    }

                    // Data lines
                    drawLine(context: context, rect: plotRect, keyPath: \.leftFreq, color: .blue)
                    drawLine(context: context, rect: plotRect, keyPath: \.rightFreq, color: .orange)
                }

                // Y-axis labels
                VStack(alignment: .trailing, spacing: 0) {
                    Text(String(format: "%.1f", maxY)).font(.system(size: 9))
                    Spacer()
                    Text(String(format: "%.1f", maxY * 0.5)).font(.system(size: 9))
                    Spacer()
                    Text("0").font(.system(size: 9))
                }
                .foregroundStyle(.secondary)
                .frame(width: leftPad - 4, height: plotRect.height)
                .position(x: (leftPad - 4) / 2, y: plotRect.midY)

                // X-axis labels
                xAxisLabels(rect: plotRect, bottomPad: bottomPad)
            }
        }
    }

    @ViewBuilder
    private func xAxisLabels(rect: CGRect, bottomPad: CGFloat) -> some View {
        let duration = max((samples.last?.t ?? 0) - (samples.first?.t ?? 0), 0)
        HStack {
            Text("0s").font(.system(size: 9))
            Spacer()
            Text("\(Int(duration / 2))s").font(.system(size: 9))
            Spacer()
            Text("\(Int(duration))s").font(.system(size: 9))
        }
        .foregroundStyle(.secondary)
        .frame(width: rect.width)
        .position(x: rect.midX, y: rect.maxY + bottomPad / 2)
    }

    private func drawLine(
        context: GraphicsContext,
        rect: CGRect,
        keyPath: KeyPath<HandMovementSample, Double>,
        color: Color
    ) {
        guard samples.count > 1 else { return }
        let minT = samples.first!.t
        let maxT = samples.last!.t
        let tRange = max(maxT - minT, 0.0001)

        let pts: [CGPoint] = samples.map { s in
            let x01 = (s.t - minT) / tRange
            let val = min(max(s[keyPath: keyPath], 0), maxY)
            let y01 = val / max(maxY, 0.0001)
            return CGPoint(
                x: rect.minX + CGFloat(x01) * rect.width,
                y: rect.minY + (1 - CGFloat(y01)) * rect.height
            )
        }

        guard pts.count > 1 else { return }
        var line = Path()
        line.move(to: pts[0])
        for pt in pts.dropFirst() {
            line.addLine(to: pt)
        }
        context.stroke(line, with: .color(color), lineWidth: 2)
    }
}

// MARK: - Live Voice Chart (with axes)

/// Live chart for voice loudness with Y-axis (dB) and X-axis (time) labels.
struct LiveVoiceChart: View {
    let samples: [VoiceSample]
    let minDB: Double
    let maxDB: Double

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            let leftPad: CGFloat = 40
            let bottomPad: CGFloat = 22
            let topPad: CGFloat = 4
            let rightPad: CGFloat = 4

            let plotW = max(size.width - leftPad - rightPad, 1)
            let plotH = max(size.height - topPad - bottomPad, 1)
            let plotRect = CGRect(x: leftPad, y: topPad, width: plotW, height: plotH)

            ZStack {
                Canvas { context, _ in
                    // Grid lines
                    for i in 0...4 {
                        let frac = Double(i) / 4.0
                        let y = plotRect.minY + CGFloat(1 - frac) * plotRect.height
                        var p = Path()
                        p.move(to: CGPoint(x: plotRect.minX, y: y))
                        p.addLine(to: CGPoint(x: plotRect.maxX, y: y))
                        context.stroke(p, with: .color(.white.opacity(0.12)), lineWidth: 0.5)
                    }

                    // Data line
                    guard samples.count > 1 else { return }
                    let minT = samples.first!.t
                    let maxT = samples.last!.t
                    let tRange = max(maxT - minT, 0.0001)
                    let dbRange = max(maxDB - minDB, 0.0001)

                    let pts: [CGPoint] = samples.map { s in
                        let x01 = (s.t - minT) / tRange
                        let val = min(max(s.db, minDB), maxDB)
                        let y01 = (val - minDB) / dbRange
                        return CGPoint(
                            x: plotRect.minX + CGFloat(x01) * plotRect.width,
                            y: plotRect.minY + (1 - CGFloat(y01)) * plotRect.height
                        )
                    }

                    guard pts.count > 1 else { return }
                    var line = Path()
                    line.move(to: pts[0])
                    for pt in pts.dropFirst() {
                        line.addLine(to: pt)
                    }
                    context.stroke(line, with: .color(.cyan), lineWidth: 2)
                }

                // Y-axis labels (dB)
                VStack(alignment: .trailing, spacing: 0) {
                    Text("\(Int(maxDB))").font(.system(size: 9))
                    Spacer()
                    Text("\(Int((maxDB + minDB) / 2))").font(.system(size: 9))
                    Spacer()
                    Text("\(Int(minDB))").font(.system(size: 9))
                }
                .foregroundStyle(.secondary)
                .frame(width: leftPad - 4, height: plotRect.height)
                .position(x: (leftPad - 4) / 2, y: plotRect.midY)

                // X-axis labels
                xAxisLabels(rect: plotRect, bottomPad: bottomPad)
            }
        }
    }

    @ViewBuilder
    private func xAxisLabels(rect: CGRect, bottomPad: CGFloat) -> some View {
        let duration = max((samples.last?.t ?? 0) - (samples.first?.t ?? 0), 0)
        HStack {
            Text("0s").font(.system(size: 9))
            Spacer()
            Text("\(Int(duration / 2))s").font(.system(size: 9))
            Spacer()
            Text("\(Int(duration))s").font(.system(size: 9))
        }
        .foregroundStyle(.secondary)
        .frame(width: rect.width)
        .position(x: rect.midX, y: rect.maxY + bottomPad / 2)
    }
}
