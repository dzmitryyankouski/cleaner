import SwiftUI

struct SearchView: View {
    @State private var searchText: String = ""
    @State private var resultText: String = ""

    @StateObject private var viewModel = SearchViewModel()

    var body: some View {
        VStack(spacing: 20) {
            TextField("Введите текст для поиска", text: $searchText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)

            Button(action: {
                // Здесь может быть логика поиска
                resultText = "Вы ввели: \(searchText)"
            }) {
                Text("Поиск")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding(.horizontal)

            if !resultText.isEmpty {
                Text(resultText)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
            }

            Spacer()
        }
        .padding(.top, 40)
    }
}

#Preview {
    SearchView()
}
