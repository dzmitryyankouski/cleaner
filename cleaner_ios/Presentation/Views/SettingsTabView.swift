import SwiftUI

// MARK: - Settings Tab View

struct SettingsTabView: View {
    
    // MARK: - Properties
    
    @StateObject var viewModel: SettingsViewModel
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Photo Similarity Settings
                    SettingSliderCard(
                        title: "Процент похожести фотографий",
                        description: "Настройте порог схожести для группировки фотографий",
                        value: $viewModel.settings.photoSimilarityThreshold,
                        range: 0.0...1.0,
                        step: 0.01,
                        minLabel: "0%",
                        maxLabel: "100%",
                        currentValueText: "Текущее значение: \(viewModel.formatAsPercentage(viewModel.settings.photoSimilarityThreshold))%",
                        onValueChanged: { newValue in
                            viewModel.updatePhotoSimilarity(newValue)
                        }
                    )
                    
                    // Search Similarity Settings
                    SettingSliderCard(
                        title: "Процент похожести поиска",
                        description: "Настройте порог схожести для поиска фотографий",
                        value: $viewModel.settings.searchSimilarityThreshold,
                        range: 0.15...0.20,
                        step: 0.001,
                        minLabel: "15%",
                        maxLabel: "20%",
                        currentValueText: "Текущее значение: \(viewModel.formatAsPercentage(viewModel.settings.searchSimilarityThreshold))%",
                        onValueChanged: { newValue in
                            viewModel.updateSearchSimilarity(newValue)
                        }
                    )
                    
                    // Video Similarity Settings
                    SettingSliderCard(
                        title: "Процент похожести видео",
                        description: "Настройте порог схожести для группировки видео",
                        value: $viewModel.settings.videoSimilarityThreshold,
                        range: 0.0...1.0,
                        step: 0.01,
                        minLabel: "0%",
                        maxLabel: "100%",
                        currentValueText: "Текущее значение: \(viewModel.formatAsPercentage(viewModel.settings.videoSimilarityThreshold))%",
                        onValueChanged: { newValue in
                            viewModel.updateVideoSimilarity(newValue)
                        }
                    )
                    
                    // Reset Button
                    Button(action: {
                        withAnimation {
                            viewModel.resetToDefaults()
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
            }
            .navigationTitle("Настройки")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Setting Slider Card

struct SettingSliderCard: View {
    let title: String
    let description: String
    @Binding var value: Float
    let range: ClosedRange<Float>
    let step: Float
    let minLabel: String
    let maxLabel: String
    let currentValueText: String
    let onValueChanged: (Float) -> Void
    
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
                    value: Binding(
                        get: { value },
                        set: { newValue in
                            value = newValue
                            onValueChanged(newValue)
                        }
                    ),
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

// MARK: - Preview

#Preview {
    SettingsTabView(
        viewModel: SettingsViewModel(
            settingsStorage: UserDefaultsSettingsStorage()
        )
    )
}

