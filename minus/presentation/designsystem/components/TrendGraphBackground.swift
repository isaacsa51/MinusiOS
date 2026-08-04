//
//  TrendGraphBackground.swift
//  minus
//

import SwiftUI

struct TrendGraphBackground: View {
    enum MarkerAnchor {
        /// The highlighted point renders at the card's leading edge.
        case start
        /// The highlighted point renders at the card's trailing edge.
        case end
    }

    let values: [Double]
    let highlightIndex: Int?
    let anchor: MarkerAnchor
    let tint: Color

    private let topInset: CGFloat = 0.15
    private let baselineInset: CGFloat = 0.92
    private let minimumPoints = 6

    private var plotted: (values: [Double], highlightIndex: Int?) {
        guard let highlightIndex, values.indices.contains(highlightIndex) else {
            return (values, highlightIndex)
        }
        switch anchor {
        case .start:
            var series = Array(values[highlightIndex...])
            if series.count < minimumPoints {
                series += Array(repeating: 0, count: minimumPoints - series.count)
            }
            return (series, 0)
        case .end:
            var series = Array(values[...highlightIndex])
            if series.count < minimumPoints {
                series = Array(repeating: 0, count: minimumPoints - series.count) + series
            }
            return (series, series.count - 1)
        }
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
        TrendGraphBackground(
            values: [70, 45, 30, 55, 90, 18, 40, 12, 6666],
            highlightIndex: 8,
            anchor: .end,
            tint: .spendingHeat(1)
        )
        .frame(height: 120)
        .background(Color.spendingHeat(1).opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

        TrendGraphBackground(
            values: [33, 90, 45, 70, 12, 55, 30],
            highlightIndex: 0,
            anchor: .start,
            tint: .spendingHeat(0)
        )
        .frame(height: 120)
        .background(Color.spendingHeat(0).opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

        TrendGraphBackground(
            values: [4.5],
            highlightIndex: 0,
            anchor: .start,
            tint: .spendingHeat(0)
        )
        .frame(height: 120)
        .background(Color.spendingHeat(0).opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
    .padding()
    .background(Color.minus.background)
}
