import SwiftUI

struct PickerHeader: View {
    @Binding var selectedTab: Int
    let tabs: [String]

    var body: some View {
        VStack(spacing: 0) {
            // Picker("Табы", selection: $selectedTab) {
            //     ForEach(tabs.indices, id: \.self) { index in
            //         Text(tabs[index])
            //             .padding(.vertical, 2)
            //             .tag(index)
            //     }
            // }
            // .pickerStyle(SegmentedPickerStyle())
            // .frame(maxWidth: 300)
            // .glassEffect()
        }
        .id(selectedTab) // Оптимизация: SwiftUI не будет пересоздавать view при изменении binding
    }
}
