import SwiftUI

struct FilesView: View {
    var body: some View {
        NavigationView {
            VStack {
                Spacer()
                
                Image(systemName: "folder")
                    .font(.system(size: 60))
                    .foregroundColor(.gray)
                
                Text("Файлы")
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundColor(.gray)
                
                Text("Здесь будут отображаться файлы")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle("Файлы")
        }
    }
}

#Preview {
    FilesView()
}
