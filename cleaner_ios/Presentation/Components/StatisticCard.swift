import SwiftUI

// MARK: - Statistic Card View

/// Компонент для отображения статистики
struct StatisticCard<Content: View>: View {
    @ViewBuilder let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        HStack {
            content
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(25)
    }
}

struct StatisticItem: View {
    let label: String
    let value: String
    let alignment: HorizontalAlignment
    
    var body: some View {
        Group {
            if alignment == .center || alignment == .trailing {
                Spacer()
            }
        }
        VStack(alignment: alignment) {
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
        }
        Group {
            if alignment == .center || alignment == .leading {
                Spacer()
            }
        }
    }
}
