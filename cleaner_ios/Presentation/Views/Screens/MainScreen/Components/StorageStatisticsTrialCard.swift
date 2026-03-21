import SwiftUI

struct TrialFeature {
    let text: String
    let isActive: Bool
}

struct StorageStatisticsTrialCard: View {
    let usedGB: Double
    let totalGB: Double
    let recoverGB: Double
    let onRecover: () -> Void
    let onGetPro: () -> Void
    let features: [TrialFeature]

    private var progress: Double { usedGB / totalGB }
    private var activeCount: Int { features.filter { $0.isActive }.count }
    private var isProUpsellMode: Bool { activeCount >= 4 }
    private var recoverLabel: String { "Recover \(Int(recoverGB)) GB" }

    var body: some View {
        ZStack {
            // Gradient background
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
            .frame(width: 358, height: 526)
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

                    Text("/ \(Int(totalGB)) GB")
                        .font(.custom("Geologica", size: 20).weight(.regular))
                        .foregroundColor(Color.white.opacity(0.5))
                        .padding(.trailing, 24)
                }

                Spacer(minLength: 8)

                // Progress bar
                ProgressBar(progress: progress, fillColor: Color(red: 0, green: 0.773, blue: 0.165))
                    .frame(width: 310, height: 10)
                    .padding(.leading, 24)

                Spacer(minLength: 24)

                // Features list
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(features.indices, id: \.self) { idx in
                        let feature = features[idx]
                        TrialFeatureRow(text: feature.text, isActive: feature.isActive)
                    }
                }
                .padding(.top, 8)
                .padding(.leading, 24)
                .padding(.trailing, 24)

                Spacer(minLength: 24)

                // Buttons — swap order, style and icons based on how many features are active
                if isProUpsellMode {
                    // 4+ active: PRO is the primary CTA (top), Recover is secondary with lock icon
                    AppButton(title: "Get PRO version", style: .primary, action: onGetPro) {
                        DiamondShape()
                            .fill(Color.white, style: FillStyle(eoFill: true))
                            .frame(width: 22, height: 22)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 8)

                    AppButton(
                        title: recoverLabel,
                        style: .secondary,
                        icon: "lock",
                        action: onRecover
                    )
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
                } else {
                    // 1-3 active: Recover is the primary CTA (top), Get PRO is secondary with diamond
                    AppButton(title: recoverLabel, style: .primary, icon: "plus.circle", action: onRecover)
                        .padding(.horizontal, 24)
                        .padding(.top, 8)

                    AppButton(title: "Get PRO version", style: .secondary, action: onGetPro) {
                        DiamondShape()
                            .fill(Color.white, style: FillStyle(eoFill: true))
                            .frame(width: 22, height: 22)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
                }

                Spacer()
            }
            .frame(width: 358, height: 526)
        }
        .frame(width: 358, height: 526)
    }
}

private struct TrialFeatureRow: View {
    let text: String
    let isActive: Bool

    var body: some View {
        HStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(Color(red: 0, green: 0.773, blue: 0.165)) // #00C52A
                    .frame(width: 16, height: 16)
                    .opacity(isActive ? 0.6 : 1.0)
                if isActive {
                    TickShape()
                        .stroke(Color.white, style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
                        .frame(width: 7, height: 6)
                        .opacity(0.6)
                }
            }
            Text(text)
                .font(.custom("Geologica", size: 16).weight(.light))
                .foregroundColor(.white)
                .opacity(isActive ? 0.6 : 1.0)
        }
    }
}


#Preview {
    ZStack {
        Color.gray.opacity(0.3).ignoresSafeArea()
        StorageStatisticsTrialCard(
            usedGB: 68,
            totalGB: 256,
            recoverGB: 34,
            onRecover: {},
            onGetPro: {},
            features: [
                TrialFeature(text: "Activate trial mode", isActive: true),
                TrialFeature(text: "Clean up to 200 MB manually", isActive: true),
                TrialFeature(text: "Run your first 500 MB AI cleanup", isActive: true),
                TrialFeature(text: "Compress up to 100 MB", isActive: true),
                TrialFeature(text: "Get PRO for unlimited cleanup", isActive: false)
            ]
        )
    }
}
