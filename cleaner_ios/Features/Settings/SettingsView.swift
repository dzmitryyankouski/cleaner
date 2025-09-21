import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationView {
            VStack {
                Spacer()
                
                Image(systemName: "gearshape")
                    .font(.system(size: 60))
                    .foregroundColor(.gray)
                
                Text("Настройки")
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundColor(.gray)
                
                Text("Здесь будут настройки приложения")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle("Настройки")
        }
    }
}

#Preview {
    SettingsView()
}
