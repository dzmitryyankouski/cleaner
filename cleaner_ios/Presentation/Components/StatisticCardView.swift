import SwiftUI

// MARK: - Statistic Card View

/// Компонент для отображения статистики
struct StatisticCardView: View {
    let statistics: [Statistic]
    
    struct Statistic {
        let label: String
        let value: String
        let alignment: HorizontalAlignment
        
        init(label: String, value: String, alignment: HorizontalAlignment = .leading) {
            self.label = label
            self.value = value
            self.alignment = alignment
        }
    }
    
    var body: some View {
        HStack {
            ForEach(Array(statistics.enumerated()), id: \.offset) { index, stat in
                VStack(alignment: stat.alignment) {
                    Text(stat.label)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(stat.value)
                        .font(.title3)
                        .fontWeight(.bold)
                }
                
                if index < statistics.count - 1 {
                    Spacer()
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Preview

#if DEBUG
struct StatisticCardView_Previews: PreviewProvider {
    static var previews: some View {
        StatisticCardView(statistics: [
            .init(label: "Всего фото", value: "1,234", alignment: .leading),
            .init(label: "Размер", value: "2.5 GB", alignment: .trailing)
        ])
        .padding()
    }
}
#endif

