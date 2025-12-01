import SwiftUI

struct ProgressLoadingCard: View {
    let title: String
    let current: Int
    let total: Int
    let message: String?
    
    init(
        title: String,
        current: Int,
        total: Int,
        message: String? = nil
    ) {
        self.title = title
        self.current = current
        self.total = total
        self.message = message
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            ProgressView(value: Double(current), total: Double(total))
                .progressViewStyle(.linear)
                .padding(.horizontal)
            
            Text("\(current) из \(total)")
                .font(.caption)
                .foregroundColor(.secondary)
            
            if let message = message {
                Text(message)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(25)
        .padding(.horizontal)
    }
}
