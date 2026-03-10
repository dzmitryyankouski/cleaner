import SwiftUI

private struct SelectionOverlay: View {
    let show: Bool

    var body: some View {
        Group {
            if show {
                Color.white.opacity(0.3)
                    .overlay(selectionCheckmark)
            }
        }
        .transaction { $0.animation = nil }
    }

    private var selectionCheckmark: some View {
        ZStack {
            Circle()
                .fill(Color(red: 69 / 255, green: 36 / 255, blue: 255 / 255))
                .frame(width: 22, height: 22)
            Image(systemName: "checkmark")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.white)
        }
        .padding(6)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
    }
}

struct Grid<Content: View>: View {
    let items: [MediaItem]
    var columns: Int = 3
    var spacing: CGFloat = 6
    var namespace: Namespace.ID
    @Binding var selectedItem: MediaItem?

    var onTap: (MediaItem) -> Void
    var onLongPress: (MediaItem) -> Void
    var cellAspectRatio: (MediaItem) -> CGFloat

    @ViewBuilder let content: (MediaItem) -> Content

    @Environment(\.mediaLibrary) var mediaLibrary

    init(
        items: [MediaItem],
        columns: Int = 3,
        spacing: CGFloat = 6,
        namespace: Namespace.ID,
        selectedItem: Binding<MediaItem?>,
        onTap: @escaping (MediaItem) -> Void,
        onLongPress: @escaping (MediaItem) -> Void,
        cellAspectRatio: @escaping (MediaItem) -> CGFloat = { item in
            switch item {
            case .photo: return 1
            case .video: return 0.5
            }
        },
        @ViewBuilder content: @escaping (MediaItem) -> Content
    ) {
        self.items = items
        self.columns = columns
        self.spacing = spacing
        self.namespace = namespace
        _selectedItem = selectedItem
        self.onTap = onTap
        self.onLongPress = onLongPress
        self.cellAspectRatio = cellAspectRatio
        self.content = content
    }

    var body: some View {
        Group {
            if items.isEmpty {
                EmptyView()
            } else {
                GeometryReader { geometry in
                    let availableWidth = geometry.size.width
                    let cellSize = (availableWidth - spacing * CGFloat(columns - 1)) / CGFloat(columns)
                    let gridColumns = Array(repeating: GridItem(.flexible(), spacing: spacing), count: columns)

                    LazyVGrid(columns: gridColumns, spacing: spacing) {
                        ForEach(items, id: \.id) { item in
                            content(item)
                                .frame(width: cellSize, height: cellSize)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                .overlay(
                                    SelectionOverlay(show: mediaLibrary?.isSelected(item) ?? false)
                                )
                                .onTapGesture { onTap(item) }
                                .highPriorityGesture(
                                    LongPressGesture(minimumDuration: 0.3)
                                        .onEnded { _ in onLongPress(item) }
                                )
                                .id(item.id)
                                .matchedTransitionSource(id: item.id, in: namespace)
                        }
                    }
                }
            }
        }
    }
}
