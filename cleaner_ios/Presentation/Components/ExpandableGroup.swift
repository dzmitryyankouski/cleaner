import SwiftUI

private enum ExpandableGroupTokens {
    static let badgeBackground = Color(red: 155 / 255, green: 163 / 255, blue: 217 / 255)
    static let headerAccent = Color(red: 69 / 255, green: 36 / 255, blue: 1)
    static let subTitleColor = Color(red: 0x76/255, green: 0x6D/255, blue: 0xA6/255)
}

/// Expandable section with title, badge, and collapsible content (Figma).
public struct ExpandableGroup<Content: View>: View {
    let title: String
    let subTitle: String
    let badgeText: String
    @ViewBuilder private let content: () -> Content

    @State private var isExpanded: Bool

    public init(
        title: String,
        subTitle: String,
        badgeText: String,
        isInitiallyExpanded: Bool = true,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.subTitle = subTitle
        self.badgeText = badgeText
        self._isExpanded = State(initialValue: isInitiallyExpanded)
        self.content = content
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            if isExpanded {
                content()
                    .padding(.top, 20)
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 34, style: .continuous))
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(AppFonts.geologica(size: 20, wght: 500))
                    .foregroundColor(.black)

                Text(subTitle)
                    .font(AppFonts.geologica(size: 14, wght: 300))
                    .foregroundColor(ExpandableGroupTokens.subTitleColor)
            }

            if !badgeText.isEmpty {
                Text(badgeText)
                    .font(AppFonts.geologica(size: 12, wght: 400))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(ExpandableGroupTokens.badgeBackground)
                    .clipShape(Capsule())
            }

            Spacer(minLength: 8)

            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    isExpanded.toggle()
                }
            } label: {
                Image(systemName: isExpanded
                    ? "arrow.up.right.and.arrow.down.left"
                    : "arrow.down.left.and.arrow.up.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(ExpandableGroupTokens.headerAccent)
                    .contentTransition(.identity)
                    .transaction { $0.animation = nil }
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .contentShape(Circle())
            .clipShape(Circle())
            .glassEffect(.regular.tint(Color.white.opacity(0.7)).interactive())
            .accessibilityLabel(isExpanded ? "Collapse" : "Expand")
        }
    }

}
