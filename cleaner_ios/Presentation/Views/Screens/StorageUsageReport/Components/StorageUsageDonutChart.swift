import SwiftUI

/// A single coloured segment for the donut chart.
struct DonutSegment {
    let color: Color
    let fraction: Double
}

/// Full 360° donut chart.
/// Segments cover photos/videos sub-items, then "others", then free space (white).
/// usedGB = sum of all coloured segments (photos + videos).
/// othersGB = the "other" storage category.
/// Free space = totalGB - usedGB - othersGB, rendered in white.
struct StorageUsageDonutChart: View {
    let segments: [DonutSegment]
    let usedGB: Double
    let othersGB: Double
    let totalGB: Double

    private let lineWidth: CGFloat = 26
    private let startAngle: Double = -90   // 12 o'clock
    private let othersColor = Color(red: 0.639, green: 0.663, blue: 0.859) // #A3A9DB
    private let freeColor = Color.white.opacity(0.3)

    var body: some View {
        ZStack {
            // ── Free space (white) — full circle base ───────────────────
            Circle()
                .stroke(freeColor, style: StrokeStyle(lineWidth: lineWidth, lineCap: .butt))

            // ── Others segment ──────────────────────────────────────────
            let othersFraction = othersGB / totalGB
            let othersStart = allSegmentsFraction
            Circle()
                .trim(from: CGFloat(othersStart), to: CGFloat(othersStart + othersFraction))
                .stroke(othersColor.opacity(0.8), style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(startAngle))

            // ── Coloured segments ───────────────────────────────────────
            // Draw back-to-front so the first segment sits on top.
            ForEach(segmentRanges.indices.reversed(), id: \.self) { i in
                let (from, to) = segmentRanges[i]
                Circle()
                    .trim(from: CGFloat(from), to: CGFloat(to))
                    .stroke(
                        segments[i].color,
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                    )
                    .rotationEffect(.degrees(startAngle))
            }

            // ── Centre label ────────────────────────────────────────────
            VStack(spacing: 2) {
                Text("\(Int(usedGB)) GB\nof \(Int(totalGB)) GB")
                    .font(.custom("Geologica", size: 28).weight(.medium))
                    .tracking(-0.28)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.black)

                Text("used")
                    .font(.custom("Geologica", size: 20).weight(.medium))
                    .tracking(-0.2)
                    .foregroundColor(Color(red: 0.463, green: 0.427, blue: 0.647)) // #766DA5
            }
        }
    }

    /// Sum of all coloured segment fractions (trim end of last coloured segment).
    private var allSegmentsFraction: Double {
        segments.reduce(0) { $0 + $1.fraction }
    }

    /// Convert segment fractions → trim(from:to:) pairs (fraction of full 360°).
    private var segmentRanges: [(Double, Double)] {
        var ranges: [(Double, Double)] = []
        var cursor: Double = 0
        for seg in segments {
            ranges.append((cursor, cursor + seg.fraction))
            cursor += seg.fraction
        }
        return ranges
    }
}

#Preview {
    ZStack {
        Color.green.ignoresSafeArea()
        StorageUsageDonutChart(
            segments: [
                DonutSegment(color: Color(hex: "#6600FF"), fraction: 0.10),
                DonutSegment(color: Color(hex: "#CC00FF"), fraction: 0.08),
                DonutSegment(color: Color(hex: "#FF9500"), fraction: 0.06),
                DonutSegment(color: Color(hex: "#0099FF"), fraction: 0.04),
                DonutSegment(color: Color(hex: "#00C07A"), fraction: 0.03),
                DonutSegment(color: Color(hex: "#A6C700"), fraction: 0.09),
                DonutSegment(color: Color(hex: "#FF0073"), fraction: 0.07),
            ],
            usedGB: 47,    // sum of segment fractions * 256 ≈ 47 GB (photos + videos)
            othersGB: 81,  // others category
            totalGB: 256   // free = 256 - 47 - 21 = 188 GB
        )
        .frame(width: 272, height: 272)
        .padding(40)
    }
}
