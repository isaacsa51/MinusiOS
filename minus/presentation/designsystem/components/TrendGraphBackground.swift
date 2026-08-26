//
//  TrendGraphBackground.swift
//  minus
//

import SwiftUI

struct TrendGraphBackground: View {
    /// Which edge the text-legibility gradient (see `textGradientEdge`)
    /// concentrates at — the opposite edge fades to fully clear.
    enum GradientEdge {
        case top
        case bottom
    }

    let values: [Double]
    let highlightIndex: Int?
    let tint: Color
    /// Layers a `tint` wash on top of the graph — same color as the area
    /// fill and line, just stronger — concentrated at this edge and fading
    /// to clear at the opposite one, so text placed over that edge (by the
    /// caller) stays legible without the graph's own drawing changing at
    /// all. `nil` (the default) renders no wash.
    var textGradientEdge: GradientEdge? = nil

    private let topInset: CGFloat = 0.15
    private let baselineInset: CGFloat = 0.92
    /// Points shown on each side of the highlighted one, so it always lands
    /// dead center in the card regardless of where it falls in `values` —
    /// zero-padded on whichever side runs out of real data first.
    private let contextRadius = 3

    private var plotted: (values: [Double], highlightIndex: Int?) {
        guard let highlightIndex, values.indices.contains(highlightIndex) else {
            return (values, highlightIndex)
        }

        let lowerBound = max(0, highlightIndex - contextRadius)
        let upperBound = min(values.count - 1, highlightIndex + contextRadius)
        var series = Array(values[lowerBound...upperBound])
        var centeredIndex = highlightIndex - lowerBound

        let leadingPad = contextRadius - (highlightIndex - lowerBound)
        if leadingPad > 0 {
            series = Array(repeating: 0, count: leadingPad) + series
            centeredIndex += leadingPad
        }
        let trailingPad = contextRadius - (upperBound - highlightIndex)
        if trailingPad > 0 {
            series += Array(repeating: 0, count: trailingPad)
        }

        return (series, centeredIndex)
    }

    var body: some View {
        GeometryReader { geo in
            let series = plotted
            let points = points(for: series.values, in: geo.size)
            let baselineY = geo.size.height

            ZStack {
                SmoothAreaShape(points: points, baselineY: baselineY)
                    .fill(
                        LinearGradient(
                            colors: [tint.opacity(0.32), tint.opacity(0.08)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                SmoothLineShape(points: points)
                    .stroke(tint.opacity(0.45), lineWidth: 1.5)

                if let highlightIndex = series.highlightIndex, points.indices.contains(highlightIndex) {
                    let point = points[highlightIndex]
                    Circle()
                        .fill(tint.opacity(0.22))
                        .frame(width: 22, height: 22)
                        .position(point)
                    Circle()
                        .fill(tint)
                        .frame(width: 8, height: 8)
                        .position(point)
                }

                if let textGradientEdge {
                    LinearGradient(
                        colors: [tint.opacity(0.5), tint.opacity(0.2), .clear],
                        startPoint: textGradientEdge == .top ? .top : .bottom,
                        endPoint: textGradientEdge == .top ? .bottom : .top
                    )
                    .allowsHitTesting(false)
                }
            }
        }
    }

    private func points(for values: [Double], in size: CGSize) -> [CGPoint] {
        guard values.count > 1 else { return [] }

        let minValue = values.min() ?? 0
        let maxValue = values.max() ?? 0
        let range = maxValue - minValue

        let stepX = size.width / CGFloat(values.count - 1)
        let band = baselineInset - topInset

        return values.enumerated().map { index, value in
            let ratio = range > 0 ? (value - minValue) / range : 0.5
            let y = size.height * (baselineInset - CGFloat(ratio) * band)
            return CGPoint(x: CGFloat(index) * stepX, y: y)
        }
    }
}

private extension Path {
    mutating func addSmoothCurve(through points: [CGPoint]) {
        guard points.count > 1 else { return }
        guard points.count > 2 else {
            addLine(to: points[1])
            return
        }
        for i in 0..<points.count - 1 {
            let p0 = i == 0 ? points[i] : points[i - 1]
            let p1 = points[i]
            let p2 = points[i + 1]
            let p3 = i + 2 < points.count ? points[i + 2] : p2

            let control1 = CGPoint(x: p1.x + (p2.x - p0.x) / 6, y: p1.y + (p2.y - p0.y) / 6)
            let control2 = CGPoint(x: p2.x - (p3.x - p1.x) / 6, y: p2.y - (p3.y - p1.y) / 6)
            addCurve(to: p2, control1: control1, control2: control2)
        }
    }
}

private struct SmoothLineShape: Shape {
    let points: [CGPoint]

    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard let first = points.first, points.count > 1 else { return path }
        path.move(to: first)
        path.addSmoothCurve(through: points)
        return path
    }
}

private struct SmoothAreaShape: Shape {
    let points: [CGPoint]
    let baselineY: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard let first = points.first, let last = points.last, points.count > 1 else { return path }
        path.move(to: CGPoint(x: first.x, y: baselineY))
        path.addLine(to: first)
        path.addSmoothCurve(through: points)
        path.addLine(to: CGPoint(x: last.x, y: baselineY))
        path.closeSubpath()
        return path
    }
}

#Preview {
    VStack(spacing: 12) {
        // Highlight at the very end of the series — still centers.
        TrendGraphBackground(
            values: [70, 45, 30, 55, 90, 18, 40, 12, 6666],
            highlightIndex: 8,
            tint: .spendingHeat(1)
        )
        .frame(height: 120)
        .background(Color.spendingHeat(1).opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

        // Highlight at the very start — still centers.
        TrendGraphBackground(
            values: [33, 90, 45, 70, 12, 55, 30],
            highlightIndex: 0,
            tint: .spendingHeat(0)
        )
        .frame(height: 120)
        .background(Color.spendingHeat(0).opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

        // Highlight already in the middle.
        TrendGraphBackground(
            values: [33, 90, 45, 70, 12, 55, 30],
            highlightIndex: 3,
            tint: .spendingHeat(0)
        )
        .frame(height: 120)
        .background(Color.spendingHeat(0).opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

        TrendGraphBackground(
            values: [4.5],
            highlightIndex: 0,
            tint: .spendingHeat(0)
        )
        .frame(height: 120)
        .background(Color.spendingHeat(0).opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

        TrendGraphBackground(
            values: [33, 90, 45, 70, 12, 55, 30],
            highlightIndex: 0,
            tint: .spendingHeat(0),
            textGradientEdge: .top
        )
        .frame(height: 120)
        .background(Color.spendingHeat(0).opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

        TrendGraphBackground(
            values: [70, 45, 30, 55, 90, 18, 40, 12, 6666],
            highlightIndex: 8,
            tint: .spendingHeat(1),
            textGradientEdge: .bottom
        )
        .frame(height: 120)
        .background(Color.spendingHeat(1).opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
    .padding()
    .background(Color.minus.background)
}
