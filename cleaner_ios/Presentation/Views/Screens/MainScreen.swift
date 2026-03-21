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
                    StorageStatisticsCard(
                        usedGB: 125,
                        totalGB: 256,
                        onRecover: {},
                        onSeeReport: {}
                    )

                    // Block 2: Manual cleanup
                    VStack(alignment: .leading, spacing: 16) {
                        SectionHeader(
                            title: "Manual cleanup",
                            subtitle: "Review and delete files by category"
                        )

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
