import SwiftUI

/// Data model for a single album category card (mock — will be replaced with real data later)
private struct AlbumCategory {
    let title: String
    let itemCount: Int
    let storageBadge: String?
    let hasAttention: Bool
}

/// MainScreen mockup
struct MainScreen: View {
    @State var selectedTab = 0
    @State var isPro: Bool = true    // Toggle for demo; set to true for PRO, false for TRIAL
    @State var isGalleryEmpty: Bool = true // Toggle for demo; set true when gallery has nothing to clean
    @State var isScanning: Bool = false     // Toggle for demo; set true while scan is in progress

    // Mock data — swap out for real data when ready
    private let albumCategories: [AlbumCategory] = [
        AlbumCategory(title: "Blurry photos",  itemCount: 120, storageBadge: "+ 424 MB", hasAttention: false),
        AlbumCategory(title: "Duplicate files", itemCount: 87,  storageBadge: "+ 424 MB", hasAttention: false),
        AlbumCategory(title: "Screenshots",    itemCount: 214, storageBadge: "+ 318 MB", hasAttention: true),
        AlbumCategory(title: "Large videos",   itemCount: 15,  storageBadge: "+ 2.1 GB",  hasAttention: true),
    ]

    var body: some View {
        ZStack {
            // Background gradient
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

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Block 1: Statistics card
                    if isScanning {
                        StorageStatisticsCardScanning(usedGB: 46, totalGB: 256)
                            .padding(.top, 16)
                    } else if isPro {
                        StorageStatisticsCard(
                            usedGB: 20,
                            totalGB: 256,
                            isEmpty: isGalleryEmpty,
                            onRecover: {},
                            onSeeReport: {}
                        )
                        .padding(.top, 16)
                    } else {
                        StorageStatisticsTrialCard(
                            usedGB: 68,
                            totalGB: 256,
                            recoverGB: 34,
                            onRecover: {},
                            onGetPro: {},
                            features: [
                                TrialFeature(text: "Activate trial mode", isActive: true),
                                TrialFeature(text: "Clean up to 200 MB manually", isActive: true),
                                TrialFeature(text: "Run your first 500 MB AI cleanup", isActive: true),
                                TrialFeature(text: "Compress up to 100 MB", isActive: true),
                                TrialFeature(text: "Get PRO for unlimited cleanup", isActive: false)
                            ]
                        )
                        .padding(.top, 16)
                    }

                    // Block 2: Manual cleanup
                    VStack(alignment: .leading, spacing: 16) {
                        SectionHeader(
                            title: "Manual cleanup",
                            subtitle: (!isScanning && !isGalleryEmpty) ? "Review and delete files by category" : nil
                        )

                        if isScanning {
                            // Scanning state — search/eye icon + message
                            VStack(spacing: 16) {
                                Image("mainScreen.scanning")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 46, height: 46)

                                Text("We're getting things ready. Files for manual\ncleanup will show up here shortly")
                                    .font(AppFonts.body)
                                    .foregroundColor(AppColors.sectionHeaderSubtitle)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, 48)
                        } else if isGalleryEmpty {
                            // Clean gallery state — sparkle icon + message
                            VStack(spacing: 16) {
                                Image("mainScreen.clean-gallery")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 46, height: 46)

                                Text("Your gallery looks clean. We really\ncouldn't find anything to clean")
                                    .font(AppFonts.body)
                                    .foregroundColor(AppColors.sectionHeaderSubtitle)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, 48)
                        } else {
                            LazyVGrid(
                                columns: [GridItem(.fixed(172)), GridItem(.fixed(172))],
                                spacing: 14
                            ) {
                                ForEach(albumCategories, id: \.title) { category in
                                    AlbumPreviewCard(
                                        title: category.title,
                                        itemCount: category.itemCount,
                                        storageBadge: category.storageBadge,
                                        hasAttention: category.hasAttention
                                    )
                                }
                            }
                            .padding(.top, 16)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 32)
                    .padding(.bottom, 32)
                }
            }
        }
    }
}

#Preview {
    MainScreen()
}
