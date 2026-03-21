import SwiftUI

/// High-level component: the "Storage used" statistics card shown on the Main screen.
/// Displays used/total storage, a progress bar, and action buttons.
struct StorageStatisticsCard: View {
    let usedGB: Double
    let totalGB: Double
    let onRecover: () -> Void
    let onSeeReport: () -> Void

    private var progress: Double { usedGB / totalGB }

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

                AppButton(title: "Recover \(Int(totalGB - usedGB)) GB", icon: "plus.circle", action: onRecover)
                    .padding(.horizontal, 24)
                    .padding(.top, 8)

                AppButton(title: "See full report", style: .secondary, action: onSeeReport)
                    .padding(.horizontal, 24)
                    .padding(.top, 8)

                Spacer()
            }
            .frame(width: 358, height: 340)
        }
        .frame(width: 358, height: 340)
    }
}

#Preview {
    ZStack {
        Color.gray.opacity(0.3).ignoresSafeArea()
        StorageStatisticsCard(
            usedGB: 125,
            totalGB: 256,
            onRecover: {},
            onSeeReport: {}
        )
    }
}

