import SwiftUI

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    
    init(icon: String, title: String, message: String) {
        self.icon = icon
        self.title = title
        self.message = message
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 50))
                .foregroundColor(.secondary)
            
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}
