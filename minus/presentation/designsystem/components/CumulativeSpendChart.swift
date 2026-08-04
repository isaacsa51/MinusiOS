//
//  CumulativeSpendChart.swift
//  minus
//

import SwiftUI

struct CumulativeSpendChart: View {
    let values: [Double]
    let startLabel: String
    let endLabel: String
    let peakLabel: String
    var tint: Color = Color.minus.primaryAction

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if values.count > 1 {
                Text(peakLabel)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(tint.opacity(0.8))
            }

            GeometryReader { geo in
                let points = stepPoints(in: geo.size)

                ZStack(alignment: .topLeading) {
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: 0))
                        path.addLine(to: CGPoint(x: geo.size.width, y: 0))
                    }
                    .stroke(style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    .foregroundStyle(tint.opacity(0.25))

                    StepAreaShape(points: points, baselineY: geo.size.height)
                        .fill(
                            LinearGradient(
                                colors: [tint.opacity(0.32), tint.opacity(0.05)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                    StepLineShape(points: points)
                        .stroke(tint, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))

                    if let last = points.last {
                        Circle()
                            .fill(Color.minus.surface)
                            .frame(width: 14, height: 14)
                            .overlay(Circle().stroke(tint, lineWidth: 3))
                            .position(last)
                    }
                }
            }
            .frame(height: 140)

            if values.count > 1 {
                HStack {
                    Text(startLabel)
                    Spacer()
                    Text(endLabel)
                }
                .font(.caption2)
                .foregroundStyle(Color.minus.textSecondary)
            }
        }
    }

    private func stepPoints(in size: CGSize) -> [CGPoint] {
        guard values.count > 1 else { return [] }

        let maxValue = values.max() ?? 0
        let minValue = min(0, values.min() ?? 0)
        let range = maxValue - minValue

        let stepX = size.width / CGFloat(values.count - 1)
        let topInset: CGFloat = 0.12

        return values.enumerated().map { index, value in
            let ratio = range > 0 ? (value - minValue) / range : 0
            let y = size.height * (1 - topInset) * (1 - CGFloat(ratio))
            return CGPoint(x: CGFloat(index) * stepX, y: y)
        }
    }
}

private struct StepLineShape: Shape {
    let points: [CGPoint]

    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard let first = points.first, points.count > 1 else { return path }
        path.move(to: first)
        for i in 1..<points.count {
            let previous = points[i - 1]
            let current = points[i]
            path.addLine(to: CGPoint(x: current.x, y: previous.y))
            path.addLine(to: current)
        }
        return path
    }
}

private struct StepAreaShape: Shape {
    let points: [CGPoint]
    let baselineY: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard let first = points.first, let last = points.last, points.count > 1 else { return path }
        path.move(to: CGPoint(x: first.x, y: baselineY))
        path.addLine(to: first)
        for i in 1..<points.count {
            let previous = points[i - 1]
            let current = points[i]
            path.addLine(to: CGPoint(x: current.x, y: previous.y))
            path.addLine(to: current)
        }
        path.addLine(to: CGPoint(x: last.x, y: baselineY))
        path.closeSubpath()
        return path
    }
}

#Preview {
    CumulativeSpendChart(
        values: [0, 40, 40, 120, 180, 180, 260, 400, 400, 420],
        startLabel: "May 3",
        endLabel: "May 29",
        peakLabel: "$420.00"
    )
    .padding()
    .background(Color.minus.surface)
    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    .padding()
    .background(Color.minus.background)
}
