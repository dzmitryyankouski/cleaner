import SwiftUI

struct SmartCleanupSelector: View {
    @State private var navigationPath = NavigationPath()

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ScrollView {
                SectionHeader(
                    title: "Smart recommendations",
                    subtitle: "Pick the options you'd like us to use to free up space on your iPhone"
                )

                Spacer()
            }
            .padding(.horizontal)
        }
        .navigationTitle("Smart cleanup")
        .navigationBarTitleDisplayMode(.inline)
    }
}
