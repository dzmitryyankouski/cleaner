import SwiftUI

/// High-level component: a single album category card shown in the "Manual cleanup" grid.
/// Displays a preview photo from the folder, item count, category name, and optional storage badge.
struct AlbumPreviewCard: View {
    let title: String
    let itemCount: Int
    let previewImage: UIImage?
    let storageBadge: String?
    let hasAttention: Bool

    init(
        title: String,
        itemCount: Int,
        previewImage: UIImage? = nil,
        storageBadge: String? = nil,
        hasAttention: Bool = false
    ) {
        self.title = title
        self.itemCount = itemCount
        self.previewImage = previewImage
        self.storageBadge = storageBadge
        self.hasAttention = hasAttention
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 32)
                .fill(Color.white.opacity(0.3))

            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top) {
                    // Photo preview with attention badge overlay
                    ZStack(alignment: .topTrailing) {
                        Group {
                            if let image = previewImage {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                            } else {
                                RoundedRectangle(cornerRadius: 24)
                                    .fill(Color.gray.opacity(0.4))
                            }
                        }
                        .frame(width: 72, height: 72)
                        .clipShape(RoundedRectangle(cornerRadius: 24))

                        if hasAttention {
                            ZStack {
                                Circle()
                                    .fill(Color(red: 1, green: 0.043, blue: 0.043)) // #FF0B0B
                                    .frame(width: 22, height: 22)
                                // Exclamation mark vertical bar
                                RoundedRectangle(cornerRadius: 1)
                                    .fill(Color.white)
                                    .frame(width: 2.4, height: 7.3)
                                    .offset(y: -2.2)
                                // Exclamation mark dot
                                RoundedRectangle(cornerRadius: 1)
                                    .fill(Color.white)
                                    .frame(width: 2.4, height: 2.4)
                                    .offset(y: 4)
                            }
                            .frame(width: 22, height: 22)
                            .offset(x: 6, y: -6)
                        }
                    }
                    .frame(width: 72, height: 72)

                    Spacer()

                    Text("\(itemCount)")
                        .font(AppFonts.caption)
                        .foregroundColor(.black)
                }

                Spacer(minLength: 8)

                VStack(alignment: .leading, spacing: 8) {
                    Text(title)
                        .font(AppFonts.body)
                        .foregroundColor(.black)

                    if let badge = storageBadge {
                        Text(badge)
                            .font(AppFonts.caption)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(Color(red: 0.608, green: 0.639, blue: 0.851)) // #9BA3D9
                            .cornerRadius(21)
                    }
                }
            }
            .padding(16)
        }
        .frame(width: 172, height: 176)
    }
}

#Preview {
    HStack(spacing: 24) {
        AlbumPreviewCard(
            title: "Blurry photos",
            itemCount: 120,
            storageBadge: "+ 424 MB"
        )
        AlbumPreviewCard(
            title: "Old screenshots",
            itemCount: 87,
            storageBadge: "+ 212 MB",
            hasAttention: true
        )
    }
    .padding()
    .background(Color.gray.opacity(0.3))
}
