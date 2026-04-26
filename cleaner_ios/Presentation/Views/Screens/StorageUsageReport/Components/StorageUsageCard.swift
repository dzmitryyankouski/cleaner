import SwiftUI

// MARK: - Data models

/// One sub-item inside a storage category (e.g. "Blurry photos" inside Photos).
struct StorageSubItem {
    let name: String
    let color: Color
    let sizeGB: Double
}

/// Top-level storage category (Photos, Videos, Other).
struct StorageCategoryItem {
    let name: String
    let iconAsset: String      // asset catalog name
    let sizeGB: Double
    let badgeColor: Color
    let subItems: [StorageSubItem]
}

// MARK: - Private helpers

private struct CategoryRow: View {
    let category: StorageCategoryItem
    let totalGB: Double

    private var badgeLabel: String {
        category.sizeGB >= 1
            ? String(format: "%.1f GB", category.sizeGB)
            : String(format: "%.0f MB", category.sizeGB * 1024)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header row: icon + name + badge
            HStack(spacing: 0) {
                // Icon box
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.white.opacity(0.5))
                        .frame(width: 32, height: 32)
                    Image(category.iconAsset)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 32, height: 32)
                }

                Text(category.name)
                    .font(.custom("Geologica", size: 16).weight(.light))
                    .foregroundColor(.black)
                    .padding(.leading, 12)

                Spacer()

                // Size badge
                Text(badgeLabel)
                    .font(.custom("Geologica", size: 12).weight(.regular))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(category.badgeColor)
                    .clipShape(Capsule())
            }

            // Sub-items
            if !category.subItems.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(category.subItems, id: \.name) { sub in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(sub.color)
                                .frame(width: 8, height: 8)
                            Text(sub.name)
                                .font(.custom("Geologica", size: 14).weight(.light))
                                .foregroundColor(.black)
                        }
                        .padding(.leading, 44)
                    }
                }
            }
        }
    }
}

// MARK: - Main card

/// "Storage usage" white-glass card: donut chart + category legend.
struct StorageUsageCard: View {
    let totalGB: Double
    let categories: [StorageCategoryItem]

    /// Change this one value to resize the donut chart.
    private let donutSize: CGFloat = 270

    @State private var showingInfo = false

    // Build donut segments from sub-items of categories that have sub-items
    // (photos + videos). Categories without sub-items are treated as "others".
    private var donutSegments: [DonutSegment] {
        categories.flatMap { cat in
            cat.subItems.map { sub in
                DonutSegment(color: sub.color, sizeGB: sub.sizeGB)
            }
        }
    }

    // Sum of sizes for categories that have no sub-items (e.g. "Other")
    private var othersGB: Double {
        categories
            .filter { $0.subItems.isEmpty }
            .reduce(0) { $0 + $1.sizeGB }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // ── Title row ───────────────────────────────────────────────
            HStack {
                Text("Storage usage")
                    .font(.custom("Geologica", size: 20).weight(.medium))
                    .tracking(-0.2)
                    .foregroundColor(.black)

                Spacer()

                // info button
                Button(action: { showingInfo = true }) {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.5))
                            .frame(width: 44, height: 44)
                        Text("?")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.black)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)

            // ── Donut chart ─────────────────────────────────────────────
            StorageUsageDonutChart(
                segments: donutSegments,
                othersGB: othersGB,
                totalGB: totalGB
            )
            .frame(width: donutSize, height: donutSize)
            .padding(.top, 8)
            .frame(maxWidth: .infinity)

            // ── Category rows ────────────────────────────────────────────
            VStack(alignment: .leading, spacing: 20) {
                ForEach(categories, id: \.name) { category in
                    CategoryRow(category: category, totalGB: totalGB)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 24)
            .padding(.bottom, 24)
        }
        .background(Color.white.opacity(0.3))
        .cornerRadius(34)
        .sheet(isPresented: $showingInfo) {
            StorageUsageInfoView()
                .presentationDetents([.large])
                .presentationBackground(Color.clear)
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 0.765, green: 0.761, blue: 0.831),
                Color(red: 0.741, green: 0.772, blue: 0.953)
            ]),
            startPoint: .top, endPoint: .bottom
        )
        .ignoresSafeArea()

        ScrollView {
            StorageUsageCard(
                totalGB: 256,
                categories: [
                    StorageCategoryItem(
                        name: "Photos and Live Photos",
                        iconAsset: "storage-report.photos",
                        sizeGB: 23.5,
                        badgeColor: StorageReportPalette.photosBadge,
                        subItems: [
                            StorageSubItem(name: "Blurry photos",   color: StorageReportPalette.blurryPhotos,  sizeGB: 5.0),
                            StorageSubItem(name: "Similar photos",  color: StorageReportPalette.similarPhotos, sizeGB: 4.5),
                            StorageSubItem(name: "Duplicates",      color: StorageReportPalette.duplicates,    sizeGB: 6.0),
                            StorageSubItem(name: "Screenshots",     color: StorageReportPalette.screenshots,   sizeGB: 4.0),
                            StorageSubItem(name: "Live Photos",     color: StorageReportPalette.livePhotos,    sizeGB: 4.0),
                        ]
                    ),
                    StorageCategoryItem(
                        name: "Videos",
                        iconAsset: "storage-report.videos",
                        sizeGB: 44.5,
                        badgeColor: StorageReportPalette.videosBadge,
                        subItems: [
                            StorageSubItem(name: "Similar videos",  color: StorageReportPalette.similarVideos, sizeGB: 34.5),
                            StorageSubItem(name: "Screen records",  color: StorageReportPalette.screenRecords, sizeGB: 10.0),
                        ]
                    ),
                    StorageCategoryItem(
                        name: "Other",
                        iconAsset: "storage-report.other",
                        sizeGB: 88.6,
                        badgeColor: StorageReportPalette.otherBadge,
                        subItems: []
                    ),
                ]
            )
            .padding(16)
        }
    }
}

