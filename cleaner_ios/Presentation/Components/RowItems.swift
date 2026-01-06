import SwiftUI

struct RowItems<Item: Identifiable & Equatable, Content: View>: View {
    let items: [Item]
    let selectedItems: [Item]
    var namespace: Namespace.ID

    @ViewBuilder let content: (Item) -> Content
    let onSelect: ((Item) -> Void)?
    let onTap: ((Item) -> Void)?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 1) {
                ForEach(items, id: \.id) { item in
                    content(item)
                        .frame(width: 150, height: 200)
                        .id(item.id)
                        .matchedTransitionSource(id: item.id, in: namespace)
                        .clipped()
                        .overlay(
                            Group {
                                if selectedItems.contains(item) {
                                    Color.white.opacity(0.5)
                                }
                            }
                            .transaction { $0.animation = nil }
                        )
                        .onTapGesture {
                            if selectedItems.isEmpty {
                                onTap?(item)
                            } else {
                                withAnimation {
                                    onSelect?(item)
                                }
                            }
                        }
                        .highPriorityGesture(
                            LongPressGesture(minimumDuration: 0.3)
                                .onEnded { _ in
                                    withAnimation {
                                        onSelect?(item)
                                    }
                                }
                        )
                }
            }
            .scrollTargetLayout()
        }
        .scrollClipDisabled(true)
        .scrollTargetBehavior(.viewAligned)
    }
}
