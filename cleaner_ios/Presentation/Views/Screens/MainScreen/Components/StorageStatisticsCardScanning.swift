import SwiftUI

// MARK: - Decorative Sphere
// Renders sphere.svg appearance in pure SwiftUI:
// a pearlescent white/blue circle with a blue wave ribbon across the middle.
struct DecorativeSphere: View {
    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            ZStack {
                // Outer glow / halo
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(0.0),
                                Color(red: 0.72, green: 0.80, blue: 0.98).opacity(0.35)
                            ]),
                            center: .center,
                            startRadius: size * 0.42,
                            endRadius: size * 0.55
                        )
                    )
                    .frame(width: size * 1.1, height: size * 1.1)

                // Main sphere body — white/light-blue radial gradient
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(stops: [
                                .init(color: Color.white, location: 0.0),
                                .init(color: Color(red: 0.91, green: 0.93, blue: 0.99), location: 0.35),
                                .init(color: Color(red: 0.78, green: 0.83, blue: 0.97), location: 0.65),
                                .init(color: Color(red: 0.68, green: 0.74, blue: 0.95), location: 1.0)
                            ]),
                            center: UnitPoint(x: 0.38, y: 0.30),
                            startRadius: 0,
                            endRadius: size * 0.55
                        )
                    )
                    .frame(width: size, height: size)

                // Blue wave ribbon — elliptical shape across the middle
                Ellipse()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(stops: [
                                .init(color: Color(red: 0.20, green: 0.35, blue: 0.85).opacity(0.85), location: 0.0),
                                .init(color: Color(red: 0.40, green: 0.55, blue: 0.95).opacity(0.60), location: 0.5),
                                .init(color: Color(red: 0.20, green: 0.35, blue: 0.85).opacity(0.85), location: 1.0)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: size * 0.85, height: size * 0.22)
                    .rotationEffect(.degrees(-8))
                    .blendMode(.plusLighter)

                // Inner highlight stripe (lighter center of wave)
                Ellipse()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(0.0),
                                Color.white.opacity(0.45),
                                Color.white.opacity(0.0)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: size * 0.55, height: size * 0.07)
                    .rotationEffect(.degrees(-8))

                // Top specular highlight
                Ellipse()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(0.9),
                                Color.white.opacity(0.0)
                            ]),
                            center: .center,
                            startRadius: 0,
                            endRadius: size * 0.18
                        )
                    )
                    .frame(width: size * 0.35, height: size * 0.22)
                    .offset(x: -size * 0.12, y: -size * 0.25)
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .clipShape(Circle())
        }
    }
}

/// Storage card shown while the gallery scan is in progress.
/// Layout: "Scanning your gallery..." label (top-left) + decorative circle (top-right)
///         + GB numbers row + progress bar.
struct StorageStatisticsCardScanning: View {
    let usedGB: Double
    let totalGB: Double

    private var progress: Double { usedGB / totalGB }

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Card background — same gradient as other cards
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: Color(red: 0.501, green: 0.594, blue: 0.969), location: 0),
                    .init(color: Color(red: 0.715, green: 0.719, blue: 0.847), location: 0.5),
                    .init(color: Color(red: 0.464, green: 0.451, blue: 0.834), location: 1)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .cornerRadius(50)
            .shadow(color: Color.black.opacity(0.08), radius: 24, y: 8)

            // Decorative sphere (top-right) — rendered via DecorativeSphere (sphere.svg visual)
            DecorativeSphere()
                .frame(width: 96, height: 96)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .padding(.top, 22)
                .padding(.trailing, 24)

            VStack(alignment: .leading, spacing: 0) {
                // "Scanning your gallery..." — top-left, 124×90, font 28/Medium
                Text("Scanning your\ngallery...")
                    .font(.custom("Geologica", size: 28).weight(.medium))
                    .lineSpacing(2)
                    .tracking(-0.28)
                    .foregroundColor(.white)
                    .frame(width: 200, alignment: .leading)
                    .padding(.top, 22)
                    .padding(.leading, 24)

                Spacer(minLength: 0)

                // GB numbers row
                HStack(alignment: .bottom, spacing: 0) {
                    Text("\(Int(usedGB)) %")
                        .font(.custom("Geologica", size: 52).weight(.medium))
                        .tracking(-1.56)
                        .foregroundColor(.white)
                        .padding(.leading, 24)

                    Spacer()

                    Text("/\(Int(totalGB)) %")
                        .font(.custom("Geologica", size: 20).weight(.regular))
                        .tracking(-0.2)
                        .foregroundColor(Color.white.opacity(0.5))
                        .padding(.trailing, 24)
                }
                .padding(.bottom, 8)

                // Progress bar
                ProgressBar(progress: progress, fillColor: .white)
                    .frame(width: 310, height: 10)
                    .padding(.leading, 24)
                    .padding(.bottom, 30)
            }
        }
        .frame(width: 358, height: 274)
    }
}

#Preview {
    ZStack {
        Color.gray.opacity(0.3).ignoresSafeArea()
        StorageStatisticsCardScanning(usedGB: 46, totalGB: 100)
    }
}

#Preview("Sphere only") {
    ZStack {
        Color(red: 0.55, green: 0.65, blue: 0.90).ignoresSafeArea()
        DecorativeSphere()
            .frame(width: 200, height: 200)
    }
}

