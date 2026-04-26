import SwiftUI

/// A single coloured segment for the donut chart.
struct DonutSegment {
    let color: Color
    let sizeGB: Double
}

/// Full 360° donut chart.
/// Segments cover photos/videos sub-items, then "others", then free space (white).
/// usedGB = sum of all coloured segments (photos + videos).
/// othersGB = the "other" storage category.
/// Free space = totalGB - usedGB - othersGB, rendered in white.
struct StorageUsageDonutChart: View {
    let segments: [DonutSegment]   // sub-items with their real sizeGB and color
    let othersGB: Double           // "Other" category size — drawn as a muted segment
    let totalGB: Double            // total device storage

    private let lineWidth: CGFloat = 26
    private let startAngle: Double = -90
    private let othersColor = Color(red: 0.639, green: 0.663, blue: 0.859) // #A3A9DB
    private let freeColor = Color.white.opacity(0.3)

    /// Total used = all sub-item segments + others
    private var totalUsedGB: Double {
        segments.reduce(0) { $0 + $1.sizeGB } + othersGB
    }

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

            // ── Coloured segments (sub-items) ───────────────────────────
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
                let usedFormatted = totalUsedGB.truncatingRemainder(dividingBy: 1) == 0
                    ? String(format: "%.0f", totalUsedGB)
                    : String(format: "%.1f", totalUsedGB)
                Text("\(usedFormatted) GB\nof \(Int(totalGB)) GB")
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

    private func fraction(for segment: DonutSegment) -> Double {
        segment.sizeGB / totalGB
    }

    private var allSegmentsFraction: Double {
        segments.reduce(0) { $0 + fraction(for: $1) }
    }

    private var segmentRanges: [(Double, Double)] {
        var ranges: [(Double, Double)] = []
        var cursor: Double = 0
        for seg in segments {
            let f = fraction(for: seg)
            ranges.append((cursor, cursor + f))
            cursor += f
        }
        return ranges
    }
}

#Preview {
    // Preview mirrors real data from StorageUsageCard so colors match sub-items exactly
    ZStack {
        Color.green.ignoresSafeArea()
        StorageUsageDonutChart(
            segments: [
                DonutSegment(color: StorageReportPalette.blurryPhotos,  sizeGB: 5.0),   // Blurry photos
                DonutSegment(color: StorageReportPalette.similarPhotos, sizeGB: 4.5),   // Similar photos
                DonutSegment(color: StorageReportPalette.duplicates,    sizeGB: 6.0),   // Duplicates
                DonutSegment(color: StorageReportPalette.screenshots,   sizeGB: 4.0),   // Screenshots
                DonutSegment(color: StorageReportPalette.livePhotos,    sizeGB: 4.0),   // Live Photos
                DonutSegment(color: StorageReportPalette.similarVideos, sizeGB: 34.5),  // Similar videos
                DonutSegment(color: StorageReportPalette.screenRecords, sizeGB: 10.0),  // Screen records
            ],
            othersGB: 88.6,
            totalGB: 256
        )
        .frame(width: 272, height: 272)
        .padding(40)
    }
}
