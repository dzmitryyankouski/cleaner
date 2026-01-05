import SwiftUI
import Photos

struct ThumbnailIndicator<Item: Identifiable & Equatable, Content: View>: View {
    let items: [Item]
    @Binding var selectedItem: Item?
    @ViewBuilder let content: (Item) -> Content
    
    private let spacing: CGFloat = 8
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: spacing) {
                    ForEach(items, id: \.id) { item in
                        content(item)
                            .frame(width: item.id == selectedItem?.id ? 50 : 30, height: 50)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                            .id(item.id)
                            .onTapGesture {
                                selectedItem = item
                            }
                            .animation(.easeInOut(duration: 0.2), value: selectedItem?.id)
                    }
                }
                .padding(.horizontal, spacing)
            }
            .frame(height: 50)
            .onChange(of: selectedItem) { newValue in
                if let newValue = newValue {
                    withAnimation {
                        proxy.scrollTo(newValue.id, anchor: .center)
                    }
                }
            }
        }
    }
}
