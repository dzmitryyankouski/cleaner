import SwiftUI

struct SettingsView: View {
    @StateObject private var photoService = PhotoService.shared
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) { 
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Процент похожести фотографий")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text("Настройте порог схожести для группировки фотографий")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            Text("0%")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Slider(
                                value: Binding(
                                    get: { photoService.similarPhotosPercent },
                                    set: { photoService.similarPhotosPercent = $0 }
                                ),
                                in: 0.0...1.0,
                                step: 0.01
                            )
                            .accentColor(.blue)
                            
                            Text("100%")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Text("Текущее значение: \(String(format: "%.1f", photoService.similarPhotosPercent * 100))%")
                            .font(.caption)
                            .foregroundColor(.blue)
                            .fontWeight(.medium)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Процент похожести поиска")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text("Настройте порог схожести для поиска фотографий")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            Text("15%")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Slider(
                                value: Binding(
                                    get: { photoService.searchSimilarity },
                                    set: { photoService.searchSimilarity = $0 }
                                ),
                                in: 0.15...0.20,
                                step: 0.001
                            )
                            .accentColor(.blue)
                            
                            Text("20%")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Text("Текущее значение: \(String(format: "%.1f", photoService.searchSimilarity * 100))%")
                            .font(.caption)
                            .foregroundColor(.blue)
                            .fontWeight(.medium)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Настройка выбора модели
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Модель MobileCLIP")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text("Выберите модель для обработки изображений")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Picker("Модель", selection: Binding(
                            get: { photoService.selectedModel },
                            set: { photoService.switchModel(model: $0) }
                        )) {
                            Text("S0 (Быстрая)").tag("s0")
                            Text("S1 (Средняя)").tag("s1")
                            Text("S2 (Точная)").tag("s2")
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        
                        Text("Текущая модель: \(photoService.selectedModel.uppercased())")
                            .font(.caption)
                            .foregroundColor(.blue)
                            .fontWeight(.medium)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle("Настройки")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    SettingsView()
}
