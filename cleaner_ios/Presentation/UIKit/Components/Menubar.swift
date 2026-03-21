import SwiftUI

// MARK: - Menubar
/// Custom menubar with 4 options, styled as per Figma/CSS
struct Menubar: View {
    @Binding var selectedIndex: Int

    let items: [(icon: String, label: String)] = [
        ("rectangle.grid.2x2", "Main"),
        ("arrow.down.circle", "Compress"),
        ("magnifyingglass", "AI search"),
        ("person.crop.circle", "Profile")
    ]

    var body: some View {
        ZStack {
            // BG layer
            RoundedRectangle(cornerRadius: 296)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.969, green: 0.969, blue: 0.969), // #F7F7F7
                            Color.white.opacity(0.5),
                            Color(red: 0.2, green: 0.2, blue: 0.2, opacity: 0.05)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 390, height: 95)
                .shadow(color: Color.black.opacity(0.08), radius: 24, y: 8)
            // Glass effect
            RoundedRectangle(cornerRadius: 296)
                .fill(Color.black.opacity(0.004))
                .frame(width: 390, height: 95)
            // Blur layer (mocked)
            RoundedRectangle(cornerRadius: 1000)
                .fill(Color.black.opacity(0.04))
                .frame(width: 340, height: 54)
                .blur(radius: 10)
                .offset(y: 10)
            // Tab bar buttons
            HStack(spacing: 16) {
                ForEach(0..<items.count, id: \ .self) { idx in
                    let isActive = selectedIndex == idx
                    VStack(spacing: 1) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 100)
                                .fill(isActive ? AppColors.buttonPrimaryBackground : Color(red: 0.929, green: 0.929, blue: 0.929))
                                .frame(width: 92.5, height: 54)
                            Image(systemName: items[idx].icon)
                                .resizable()
                                .frame(width: 28, height: 28)
                                .foregroundColor(isActive ? AppColors.buttonPrimaryText : .black)
                        }
                        Text(items[idx].label)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(isActive ? AppColors.buttonPrimaryBackground : .black)
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 8)
                    .onTapGesture { selectedIndex = idx }
                }
            }
            .frame(width: 340, height: 54)
            .padding(.bottom, 25)
        }
        .frame(width: 390, height: 95)
        .padding(.bottom, 33)
    }
}

#Preview {
    @State var selected = 0
    return Menubar(selectedIndex: $selected)
}

