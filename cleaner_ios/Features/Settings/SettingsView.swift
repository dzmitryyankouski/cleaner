import SwiftUI

struct SettingsView: View {
    @StateObject private var photoService = PhotoService.shared
    @StateObject private var videoService = VideoService.shared
    
    var body: some View {
        NavigationView {
            ScrollView {
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
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Процент похожести видео")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Text("Настройте порог схожести для группировки видео")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            HStack {
                                Text("0%")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Slider(
                                    value: Binding(
                                        get: { videoService.similarVideosPercent },
                                        set: { videoService.similarVideosPercent = $0 }
                                    ),
                                    in: 0.0...1.0,
                                    step: 0.01
                                )
                                .accentColor(.blue)
                                
                                Text("100%")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Text("Текущее значение: \(String(format: "%.1f", videoService.similarVideosPercent * 100))%")
                                .font(.caption)
                                .foregroundColor(.blue)
                                .fontWeight(.medium)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    .padding(.top)
                }
            }
            .navigationTitle("Настройки")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    SettingsView()
}
