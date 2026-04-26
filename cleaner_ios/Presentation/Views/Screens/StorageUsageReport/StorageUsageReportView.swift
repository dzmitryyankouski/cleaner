import SwiftUI

/// Full-screen "Storage usage report" page.
struct StorageUsageReportView: View {
    let usedGB: Double
    let totalGB: Double
    let optimizeMB: Int
    let categories: [StorageCategoryItem]

    @Environment(\.dismiss) private var dismiss

    private var freeGB: Int { Int(totalGB - usedGB) }

    var body: some View {
        ZStack {
            // Background — same gradient as MainScreen
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.765, green: 0.761, blue: 0.831),
                    Color(red: 0.839, green: 0.812, blue: 0.890),
                    Color(red: 0.808, green: 0.769, blue: 0.886),
                    Color(red: 0.741, green: 0.772, blue: 0.953)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // ── Header ──────────────────────────────────────────────
                ZStack {
                    // Back button (left)
                    HStack {
                        Button(action: { dismiss() }) {
                            ZStack {
                                Circle()
                                    .fill(Color.white.opacity(0.5))
                                    .frame(width: 44, height: 44)

                                Image(systemName: "chevron.left")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.black)
                            }
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 16)

                    // Title (centre)
                    Text("Storage usage report")
                        .font(.custom("Geologica", size: 20).weight(.medium))
                        .tracking(-0.2)
                        .foregroundColor(.black)
                        .frame(maxWidth: 230)
                        .multilineTextAlignment(.center)
                }
                .frame(height: 44)

                // ── Scrollable body ──────────────────────────────────────
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        StorageUsageCard(
                            totalGB: totalGB,
                            categories: categories
                        )
                        .padding(.horizontal, 16)
                        .padding(.top, 16)

                        Spacer(minLength: 16)
                    }
                }

                // ── Footer buttons ───────────────────────────────────────
                VStack(spacing: 8) {
                    // Primary: Free up X GB
                    AppButton(
                        title: "Free up \(freeGB) GB",
                        style: .primary,
                        action: {}
                    ) {
                        Image("trash")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                    }

                    // Secondary: Optimize & save ~X MB
                    AppButton(
                        title: "Optimize & save ~\(optimizeMB) MB",
                        style: .secondary,
                        action: {}
                    ) {
                        Image("menu.compress")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
        .navigationBarHidden(true)
    }
}

#Preview {
    StorageUsageReportView(
        usedGB: 68,
        totalGB: 256,
        optimizeMB: 246,
        categories: [
            StorageCategoryItem(
                name: "Photos and Live Photos",
                iconAsset: "storage-report.photos",
                sizeGB: 23.5,
                badgeColor: StorageReportPalette.photosBadge,
                subItems: [
                    StorageSubItem(name: "Blurry photos",  color: StorageReportPalette.blurryPhotos,  sizeGB: 5.0),
                    StorageSubItem(name: "Similar photos", color: StorageReportPalette.similarPhotos, sizeGB: 4.5),
                    StorageSubItem(name: "Duplicates",     color: StorageReportPalette.duplicates,    sizeGB: 6.0),
                    StorageSubItem(name: "Screenshots",    color: StorageReportPalette.screenshots,   sizeGB: 4.0),
                    StorageSubItem(name: "Live Photos",    color: StorageReportPalette.livePhotos,    sizeGB: 4.0),
                ]
            ),
            StorageCategoryItem(
                name: "Videos",
                iconAsset: "storage-report.videos",
                sizeGB: 44.5,
                badgeColor: StorageReportPalette.videosBadge,
                subItems: [
                    StorageSubItem(name: "Similar videos", color: StorageReportPalette.similarVideos, sizeGB: 34.5),
                    StorageSubItem(name: "Screen records", color: StorageReportPalette.screenRecords, sizeGB: 10.0),
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
}
