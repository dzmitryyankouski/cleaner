import SwiftUI

struct SmartCleanupSelector: View {
    @Environment(\.mediaLibrary) private var mediaLibrary

    @State private var largeFilesSelected: Bool = false
    @State private var duplicatesSelected: Bool = false
    @State private var blurryPhotosSelected: Bool = false
    @State private var oldFilesSelected: Bool = false
    @State private var optimizeLivePhotosSelected: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack {
                SectionHeader(
                    title: "Smart recommendations",
                    subtitle: "Pick the options you'd like us to use to free up space on your iPhone"
                )

                VStack(spacing: 20) {
                    SmartCleanupSelectorItem(
                        title: "Large files",
                        description: "Files that take up the most space",
                        icon: .system("square.stack.3d.up"),
                        isOn: $largeFilesSelected
                    )
                    SmartCleanupSelectorItem(
                        title: "Duplicates",
                        description: "Exact copies of the same file",
                        icon: .system("square.on.square"),
                        isOn: $duplicatesSelected
                    )
                    SmartCleanupSelectorItem(
                        title: "Blurry photos",
                        description: "Photos that are out of focus",
                        icon: .asset("photo.blur"),
                        isOn: $blurryPhotosSelected
                    )
                    SmartCleanupSelectorItem(
                        title: "Old files",
                        description: "Files you haven't used recently",
                        icon: .system("clock"),
                        isOn: $oldFilesSelected
                    )
                    SmartCleanupSelectorItem(
                        title: "Optimize Live Photos",
                        description: "Remove the video, keep the photo",
                        icon: .system("livephoto"),
                        isOn: $optimizeLivePhotosSelected
                    )
                }
                .padding(16)
                .background(Color.white.opacity(0.3))
                .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
                .padding(.top, 30)

                Spacer()

                ProgressBarWithText(
                    label: "You will recover",
                    current: mediaLibrary?.selectedStorageGB ?? 0,
                    total: mediaLibrary?.usedGB ?? 0
                ) {
                    AppButton(title: "See recommendations", style: .primary, icon: "eye") {}
                }
            }
            .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background {
            AppColors.background.ignoresSafeArea()
        }
        .navigationTitle("Smart cleanup")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: largeFilesSelected) { _, new in
            mediaLibrary?.reconcile(largeFiles: new, duplicates: duplicatesSelected, blurryPhotos: blurryPhotosSelected, oldFiles: oldFilesSelected, optimizeLivePhotos: optimizeLivePhotosSelected)
        }
        .onChange(of: duplicatesSelected) { _, new in
            mediaLibrary?.reconcile(largeFiles: largeFilesSelected, duplicates: new, blurryPhotos: blurryPhotosSelected, oldFiles: oldFilesSelected, optimizeLivePhotos: optimizeLivePhotosSelected)
        }
        .onChange(of: oldFilesSelected) { _, new in
            mediaLibrary?.reconcile(largeFiles: largeFilesSelected, duplicates: duplicatesSelected, blurryPhotos: blurryPhotosSelected, oldFiles: new, optimizeLivePhotos: optimizeLivePhotosSelected)
        }
    }
}

struct SmartCleanupSelectorItem: View {

    enum Icon {
        case system(String)
        case asset(String)
    }

    let title: String
    let description: String
    let icon: Icon

    @Binding var isOn: Bool

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.white)
                    .frame(width: 32, height: 32)
                Group {
                    switch icon {
                    case .system(let name):
                        Image(systemName: name)
                            .font(.system(size: 18, weight: .regular))
                            .foregroundStyle(Color(red: 69 / 255, green: 36 / 255, blue: 1))
                    case .asset(let name):
                        Image(name)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 18, height: 18)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(AppFonts.geologica(size: 16, wght: 300))
                Text(description)
                    .font(AppFonts.geologica(size: 12, wght: 300))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            AppToggle(isOn: $isOn)
        }
    }
}
