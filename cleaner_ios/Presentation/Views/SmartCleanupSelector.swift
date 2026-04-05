import SwiftUI

struct SmartCleanupSelector: View {
    @Environment(\.appRouter) private var appRouter
    @Environment(\.mediaLibrary) private var mediaLibrary

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
                        isOn: toggleBinding(for: \.largeFilesSelected)
                    )
                    SmartCleanupSelectorItem(
                        title: "Duplicates",
                        description: "Exact copies of the same file",
                        icon: .system("square.on.square"),
                        isOn: toggleBinding(for: \.duplicatesSelected)
                    )
                    SmartCleanupSelectorItem(
                        title: "Blurry photos",
                        description: "Photos that are out of focus",
                        icon: .asset("photo.blur"),
                        isOn: toggleBinding(for: \.blurryPhotosSelected)
                    )
                    SmartCleanupSelectorItem(
                        title: "Short videos",
                        description: "Clips shorter than 6 seconds",
                        icon: .system("video"),
                        isOn: toggleBinding(for: \.shortVideosSelected)
                    )
                    SmartCleanupSelectorItem(
                        title: "Optimize Live Photos",
                        description: "Remove the video, keep the photo",
                        icon: .system("livephoto"),
                        isOn: toggleBinding(for: \.optimizeLivePhotosSelected)
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
                    AppButton(title: "See recommendations", style: .primary, icon: "eye") {
                        appRouter.push(.smartCleanupBrowse)
                    }
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
    }

    private func toggleBinding(for keyPath: ReferenceWritableKeyPath<MediaLibrary, Bool>) -> Binding<Bool> {
        Binding(
            get: { mediaLibrary?[keyPath: keyPath] ?? false },
            set: { newValue in
                mediaLibrary?[keyPath: keyPath] = newValue
                mediaLibrary?.reconcile()
            }
        )
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
