import SwiftUI

// MARK: - Settings Tab View

struct SettingsTabView: View {
    
    // MARK: - Properties
    
    @Environment(\.settings) private var settings

    @Binding var isPresented: Bool
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ScrollView {
                if let settings = settings {
                    SettingsContentView(settings: settings)
                } else {
                    VStack {
                        Text("Настройки недоступны")
                            .foregroundColor(.secondary)
                    }
                    .padding()
                }
            }
            .navigationTitle("Настройки")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close", systemImage: "xmark") {
                        isPresented = false
                    }
                }
            }
        }
    }
}

// MARK: - Settings Content View

private struct SettingsContentView: View {
    let settings: Settings
    @Bindable var values: SettingsModel
    
    init(settings: Settings) {
        self.settings = settings
        self.values = settings.values
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Photo Similarity Settings
            SettingSliderCard(
                title: "Процент похожести фотографий",
                description: "Настройте порог схожести для группировки фотографий",
                value: $values.photoSimilarityThreshold,
                range: 0.0...1.0,
                step: 0.01,
                minLabel: "0%",
                maxLabel: "100%",
                currentValueText: "Текущее значение: \(Int(values.photoSimilarityThreshold * 100))%"
            )
            .onChange(of: values.photoSimilarityThreshold) { _, _ in
                settings.save()
            }
            
            // Search Similarity Settings
            SettingSliderCard(
                title: "Процент похожести поиска",
                description: "Настройте порог схожести для поиска фотографий",
                value: $values.searchSimilarityThreshold,
                range: 0.15...0.20,
                step: 0.001,
                minLabel: "15%",
                maxLabel: "20%",
                currentValueText: "Текущее значение: \(String(format: "%.1f", values.searchSimilarityThreshold * 100))%"
            )
            .onChange(of: values.searchSimilarityThreshold) { _, _ in
                settings.save()
            }
            
            // Video Similarity Settings
            SettingSliderCard(
                title: "Процент похожести видео",
                description: "Настройте порог схожести для группировки видео",
                value: $values.videoSimilarityThreshold,
                range: 0.0...1.0,
                step: 0.01,
                minLabel: "0%",
                maxLabel: "100%",
                currentValueText: "Текущее значение: \(Int(values.videoSimilarityThreshold * 100))%"
            )
            .onChange(of: values.videoSimilarityThreshold) { _, _ in
                settings.save()
            }
                        
            // Reset Button
            Button(action: {
                withAnimation {
                    settings.resetToDefaults()
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
