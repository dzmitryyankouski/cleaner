import SwiftUI

/// Sheet shown when the user taps the "?" button on the Storage Usage card.
struct StorageUsageInfoView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack(alignment: .topTrailing) {
            // ── Full-screen gradient background ──────────────────────────
            LinearGradient(
                stops: [
                    .init(color: Color(hex: "#8098F7"), location: 0.0365),
                    .init(color: Color(hex: "#B6B7D8"), location: 0.4724),
                    .init(color: Color(hex: "#7673D5"), location: 0.9083)
                ],
                startPoint: UnitPoint(x: 0.14, y: 0),
                endPoint: UnitPoint(x: 0.86, y: 1)
            )
            .ignoresSafeArea()

            // ── Content ──────────────────────────────────────────────────
            VStack(spacing: 0) {
                // Title
                Text("How storage is calculated")
                    .font(.custom("Geologica", size: 28).weight(.medium))
                    .tracking(-0.28)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
                    .padding(.top, 80)

                // Body text 1
                Text("We group your files by type to show what takes up space. Some files may appear in multiple categories. For example, a screenshot can also be counted as a duplicate")
                    .font(.custom("Geologica", size: 14).weight(.light))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 32)
                    .padding(.top, 12)

                // Body text 2
                Text("The Other category includes system files and data that can't be cleaned")
                    .font(.custom("Geologica", size: 14).weight(.light))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 52)
                    .padding(.top, 18)

                // Question-mark image with circle
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.5), lineWidth: 2)
                        .frame(width: 180, height: 180)
                    Image("storage-report.question-mark")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 140, height: 140)
                }
                .padding(.top, 32)

                Spacer(minLength: 24)

                // ── Bottom button ────────────────────────────────────────
                Button(action: { dismiss() }) {
                    HStack {
                        Text("Got it")
                            .font(.custom("Geologica", size: 17).weight(.semibold))
                            .foregroundColor(.white)
                        Image(systemName: "arrow.right")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 58)
                    .background(Color(hex: "#4524FF"))
                    .clipShape(Capsule())
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 34)
            }
            .frame(maxWidth: .infinity)

            // ── Close button — top-right ─────────────────────────────────
            Button(action: { dismiss() }) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.3))
                        .frame(width: 44, height: 44)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            .padding(.trailing, 16)
            .padding(.top, 16)
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.gray.ignoresSafeArea()
        StorageUsageInfoView()
    }
}
