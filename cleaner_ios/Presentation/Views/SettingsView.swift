import SwiftUI

struct SettingsView: View {
    @Environment(\.settings) private var settings
    @Environment(\.photoLibrary) private var photoLibrary
    @Environment(\.videoLibrary) private var videoLibrary

    @Namespace private var namespace

    @State private var photoSimilarityThreshold: Float = 0.95
    @State private var searchSimilarityThreshold: Float = 0.188
    @State private var videoSimilarityThreshold: Float = 0.93
    @State private var hasChanged: Bool = false

    @Binding var isPresented: Bool

    func reset() {
        photoSimilarityThreshold = 0.95
        searchSimilarityThreshold = 0.188
        videoSimilarityThreshold = 0.93
    }

    func save() {
        guard let settings = settings else { return }

        settings.values.photoSimilarityThreshold = photoSimilarityThreshold
        settings.values.searchSimilarityThreshold = searchSimilarityThreshold
        settings.values.videoSimilarityThreshold = videoSimilarityThreshold
        settings.save()

        Task {
            await photoLibrary?.regroup()
        }

        isPresented = false
    }

    private func checkHasChanged() -> Bool {
        return settings?.values.photoSimilarityThreshold != photoSimilarityThreshold
            || settings?.values.searchSimilarityThreshold != searchSimilarityThreshold
            || settings?.values.videoSimilarityThreshold != videoSimilarityThreshold
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    SettingSliderCard(
                        title: "Процент похожести фотографий",
                        description: "Настройте порог схожести для группировки фотографий",
                        value: $photoSimilarityThreshold,
                        range: 0.0...1.0,
                        step: 0.01,
                        minLabel: "0%",
                        maxLabel: "100%",
                        currentValueText:
                            "Текущее значение: \(Int(photoSimilarityThreshold * 100))%"
                    )
                    .onChange(of: photoSimilarityThreshold) { _, _ in
                        hasChanged = checkHasChanged()
                    }

                    SettingSliderCard(
                        title: "Процент похожести поиска",
                        description: "Настройте порог схожести для поиска фотографий",
                        value: $searchSimilarityThreshold,
                        range: 0.15...0.20,
                        step: 0.001,
                        minLabel: "15%",
                        maxLabel: "20%",
                        currentValueText:
                            "Текущее значение: \(String(format: "%.1f", searchSimilarityThreshold * 100))%"
                    )
                    .onChange(of: searchSimilarityThreshold) { _, _ in
                        hasChanged = checkHasChanged()
                    }

                    SettingSliderCard(
                        title: "Процент похожести видео",
                        description: "Настройте порог схожести для группировки видео",
                        value: $videoSimilarityThreshold,
                        range: 0.0...1.0,
                        step: 0.01,
                        minLabel: "0%",
                        maxLabel: "100%",
                        currentValueText:
                            "Текущее значение: \(Int(videoSimilarityThreshold * 100))%"
                    )
                    .onChange(of: videoSimilarityThreshold) { _, _ in
                        hasChanged = checkHasChanged()
                    }

                    Button(action: {
                        withAnimation {
                            reset()
                        }
                    }) {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                            Text("Сбросить к значениям по умолчанию")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                }
                .padding(.top)
                .onAppear {
                    photoSimilarityThreshold = settings?.values.photoSimilarityThreshold ?? 0.95
                    searchSimilarityThreshold = settings?.values.searchSimilarityThreshold ?? 0.188
                    videoSimilarityThreshold = settings?.values.videoSimilarityThreshold ?? 0.93
                }
            }
            .navigationTitle("Настройки")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if hasChanged {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done", systemImage: "checkmark") {
                            save()
                        }
                    }
                }

                ToolbarItem(placement: .cancellationAction) {
                    Button("Close", systemImage: "xmark") {
                        isPresented = false
                    }
                }
            }
        }
    }
}

struct SettingSliderCard: View {
    let title: String
    let description: String
    @Binding var value: Float
    let range: ClosedRange<Float>
    let step: Float
    let minLabel: String
    let maxLabel: String
    let currentValueText: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)

            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)

            HStack {
                Text(minLabel)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Slider(
                    value: $value,
                    in: range,
                    step: step
                )
                .accentColor(.blue)

                Text(maxLabel)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Text(currentValueText)
                .font(.caption)
                .foregroundColor(.blue)
                .fontWeight(.medium)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}
