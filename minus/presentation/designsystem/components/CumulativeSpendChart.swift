//
//  CumulativeSpendChart.swift
//  minus
//

import Charts
import SwiftUI

struct CumulativeSpendPoint: Identifiable {
    var id: Date { date }
    let date: Date
    let total: Double
}

struct CumulativeSpendChart: View {
    let points: [CumulativeSpendPoint]
    let startLabel: String
    let endLabel: String
    let peakLabel: String
    var tint: Color = Color.minus.primaryAction

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if points.count > 1 {
                Text(peakLabel)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(tint.opacity(0.8))
            }

            Chart {
                ForEach(points) { point in
                    AreaMark(
                        x: .value("Date", point.date),
                        y: .value("Total", point.total)
                    )
                    .interpolationMethod(.stepEnd)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [tint.opacity(0.32), tint.opacity(0.05)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("Total", point.total)
                    )
                    .interpolationMethod(.stepEnd)
                    .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                    .foregroundStyle(tint)
                }

                if let last = points.last {
                    PointMark(
                        x: .value("Date", last.date),
                        y: .value("Total", last.total)
                    )
                    .symbol {
                        Circle()
                            .fill(Color.minus.surface)
                            .frame(width: 14, height: 14)
                            .overlay(Circle().stroke(tint, lineWidth: 3))
                    }
                }
            }
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
            .chartYScale(domain: .automatic(includesZero: true))
            .overlay(alignment: .top) {
                GeometryReader { geo in
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: 0))
                        path.addLine(to: CGPoint(x: geo.size.width, y: 0))
                    }
                    .stroke(style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    .foregroundStyle(tint.opacity(0.25))
                }
                .frame(height: 1)
            }
            .frame(height: 140)

            if points.count > 1 {
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
}

#Preview {
    CumulativeSpendChart(
        points: [0, 40, 40, 120, 180, 180, 260, 400, 400, 420].enumerated().map { index, value in
            CumulativeSpendPoint(
                date: Calendar.current.date(byAdding: .day, value: index, to: Date())!,
                total: value
            )
        },
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
