import SwiftUI

/// Colour theme applied to the storage card, derived from usage percentage.
private enum StorageTheme {
    /// 0 – 56 %: blue gradient, green progress bar
    case blue
    /// 56 – 86 %: orange gradient, #FF9500 progress bar
    case orange
    /// 86 – 100 %: red gradient, #E70000 progress bar
    case red

    init(progress: Double) {
        switch progress {
        case ..<0.56: self = .blue
        case ..<0.86: self = .orange
        default:      self = .red
        }
    }

    /// Card background gradient (angle ~11.23°, mapped to start/end points)
    var gradient: LinearGradient {
        switch self {
        case .blue:
            return LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.506, green: 0.596, blue: 0.969), // #8098F7
                    Color(red: 0.714, green: 0.718, blue: 0.847), // #B6B7D8
                    Color(red: 0.463, green: 0.451, blue: 0.835)  // #7673D5
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .orange:
            // linear-gradient(11.23deg, #F7B780 3.65%, #D8C7B6 47.24%, #D59073 90.83%)
            return LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.969, green: 0.718, blue: 0.502), // #F7B780
                    Color(red: 0.847, green: 0.780, blue: 0.714), // #D8C7B6
                    Color(red: 0.835, green: 0.565, blue: 0.451)  // #D59073
                ]),
                startPoint: .bottomLeading,
                endPoint: .topTrailing
            )
        case .red:
            // linear-gradient(11.23deg, #F09CA6 3.65%, #D8BFB6 47.24%, #D57380 90.83%)
            return LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.941, green: 0.612, blue: 0.651), // #F09CA6
                    Color(red: 0.847, green: 0.749, blue: 0.714), // #D8BFB6
                    Color(red: 0.835, green: 0.451, blue: 0.502)  // #D57380
                ]),
                startPoint: .bottomLeading,
                endPoint: .topTrailing
            )
        }
    }

    /// Progress bar fill colour
    var progressBarColor: Color {
        switch self {
        case .blue:   return AppColors.progressBarFillGreen
        case .orange: return Color(red: 1.0, green: 0.584, blue: 0.0)   // #FF9500
        case .red:    return Color(red: 0.906, green: 0.0,   blue: 0.0) // #E70000
        }
    }
}

/// High-level component: the "Storage used" statistics card shown on the Main screen.
/// Displays used/total storage, a progress bar, and action buttons.
/// Theme (blue / orange / red) is chosen automatically based on the usage percentage:
///   0–56 % → blue, 56–86 % → orange, 86–100 % → red.
/// When `isEmpty` is true (clean gallery), shows a smaller card with only "See full report".
struct StorageStatisticsCard: View {
    let usedGB: Double
    let totalGB: Double
    let isEmpty: Bool
    let onRecover: () -> Void
    let onSeeReport: () -> Void

    init(
        usedGB: Double,
        totalGB: Double,
        isEmpty: Bool = false,
        onRecover: @escaping () -> Void,
        onSeeReport: @escaping () -> Void
    ) {
        self.usedGB = usedGB
        self.totalGB = totalGB
        self.isEmpty = isEmpty
        self.onRecover = onRecover
        self.onSeeReport = onSeeReport
    }

    private var progress: Double { usedGB / totalGB }
    private var theme: StorageTheme { StorageTheme(progress: progress) }
    private var cardHeight: CGFloat { isEmpty ? 274 : 340 }

    var body: some View {
        ZStack {
            // Card gradient background — colour depends on usage level
            theme.gradient
                .cornerRadius(50)
                .shadow(color: Color.black.opacity(0.08), radius: 24, y: 8)

            VStack(alignment: .leading, spacing: 0) {
                Text("Storage used:")
                    .font(AppFonts.sectionHeaderTitle)
                    .foregroundColor(.white)
                    .padding(.top, 22)
                    .padding(.leading, 24)

                Spacer(minLength: 24)

                HStack(alignment: .bottom, spacing: 0) {
                    Text("\(Int(usedGB)) GB")
                        .font(.custom("Geologica", size: 52).weight(.medium))
                        .foregroundColor(.white)
                        .padding(.leading, 24)

                    Spacer()

                    Text("/\(Int(totalGB)) GB")
                        .font(.custom("Geologica", size: 20).weight(.regular))
                        .foregroundColor(Color.white.opacity(0.5))
                        .padding(.trailing, 24)
                }

                Spacer(minLength: 8)

                ProgressBar(progress: progress, fillColor: theme.progressBarColor)
                    .frame(width: 310, height: 10)
                    .padding(.leading, 24)

                Spacer(minLength: 30)

                if !isEmpty {
                    AppButton(title: "Recover \(Int(totalGB - usedGB)) GB", icon: "plus.circle", action: onRecover)
                        .padding(.horizontal, 24)
                        .padding(.top, 8)
                }

                AppButton(title: "See full report", style: .secondary, action: onSeeReport)
                    .padding(.horizontal, 24)
                    .padding(.top, 8)

                Spacer()
            }
            .frame(width: 358, height: cardHeight)
        }
        .frame(width: 358, height: cardHeight)
    }
}

#Preview {
    ZStack {
        Color.gray.opacity(0.3).ignoresSafeArea()
        ScrollView {
            VStack(spacing: 24) {
                // Blue theme: (0–56 %)
                StorageStatisticsCard(
                    usedGB: 125,
                    totalGB: 256,
                    onRecover: {},
                    onSeeReport: {}
                )
                // Orange theme: (56–86 %)
                StorageStatisticsCard(
                    usedGB: 179,
                    totalGB: 256,
                    onRecover: {},
                    onSeeReport: {}
                )
                // Red theme: (86–100 %)
                StorageStatisticsCard(
                    usedGB: 236,
                    totalGB: 256,
                    onRecover: {},
                    onSeeReport: {}
                )
                // isEmpty variant (blue)
                StorageStatisticsCard(
                    usedGB: 125,
                    totalGB: 256,
                    isEmpty: true,
                    onRecover: {},
                    onSeeReport: {}
                )
            }
            .padding(.vertical, 32)
        }
    }
}
