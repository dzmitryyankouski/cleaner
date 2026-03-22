import SwiftUI

/// High-level component: the "Storage used" statistics card shown on the Main screen.
/// Displays used/total storage, a progress bar, and action buttons.
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
    private var cardHeight: CGFloat { isEmpty ? 274 : 340 }

    var body: some View {
        ZStack {
            // Card gradient background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.506, green: 0.596, blue: 0.969), // #8098F7
                    Color(red: 0.714, green: 0.718, blue: 0.847), // #B6B7D8
                    Color(red: 0.463, green: 0.451, blue: 0.835)  // #7673D5
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
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

                ProgressBar(progress: progress, fillColor: AppColors.progressBarFillGreen)
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
        VStack(spacing: 24) {
            StorageStatisticsCard(
                usedGB: 125,
                totalGB: 256,
                onRecover: {},
                onSeeReport: {}
            )
            StorageStatisticsCard(
                usedGB: 125,
                totalGB: 256,
                isEmpty: true,
                onRecover: {},
                onSeeReport: {}
            )
        }
    }
}
