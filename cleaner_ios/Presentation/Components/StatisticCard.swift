import SwiftUI

// MARK: - Statistic Card View

/// Компонент для отображения статистики
struct StatisticCard: View {
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
        .background(Color.gray.opacity(0.1))
        .cornerRadius(25)
    }
}
