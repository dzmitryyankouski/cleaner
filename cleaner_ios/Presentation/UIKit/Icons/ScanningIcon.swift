import SwiftUI

struct ScanningIcon: View {
    var body: some View {
        ZStack {
            // Outer search circle + line
            Path { path in
                // Search line: M43 43 L33.5558 33.5389
                path.move(to: CGPoint(x: 43, y: 43))
                path.addLine(to: CGPoint(x: 33.5558, y: 33.5389))
                // Search circle arc (approximated as a closed circle)
                path.addEllipse(in: CGRect(x: 3, y: 3, width: 35.7895, height: 35.7895))
            }
            .stroke(
                Color(red: 0.463, green: 0.427, blue: 0.647),
                style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
            )

            // Eye shape
            Path { path in
                path.move(to: CGPoint(x: 13.1395, y: 24.0958))
                path.addCurve(
                    to: CGPoint(x: 12, y: 21.15),
                    control1: CGPoint(x: 12.3798, y: 23.1091),
                    control2: CGPoint(x: 12, y: 22.6148)
                )
                path.addCurve(
                    to: CGPoint(x: 13.1395, y: 18.2042),
                    control1: CGPoint(x: 12, y: 19.6842),
                    control2: CGPoint(x: 12.3798, y: 19.1918)
                )
                path.addCurve(
                    to: CGPoint(x: 20.9375, y: 14),
                    control1: CGPoint(x: 14.6562, y: 16.2344),
                    control2: CGPoint(x: 17.1998, y: 14)
                )
                path.addCurve(
                    to: CGPoint(x: 28.7354, y: 18.2042),
                    control1: CGPoint(x: 24.6751, y: 14),
                    control2: CGPoint(x: 27.2187, y: 16.2344)
                )
                path.addCurve(
                    to: CGPoint(x: 29.8749, y: 21.15),
                    control1: CGPoint(x: 29.4951, y: 19.1927),
                    control2: CGPoint(x: 29.8749, y: 19.6851)
                )
                path.addCurve(
                    to: CGPoint(x: 28.7354, y: 24.0958),
                    control1: CGPoint(x: 29.8749, y: 22.6157),
                    control2: CGPoint(x: 29.4951, y: 23.1082)
                )
                path.addCurve(
                    to: CGPoint(x: 20.9375, y: 28.3),
                    control1: CGPoint(x: 27.2187, y: 26.0656),
                    control2: CGPoint(x: 24.6751, y: 28.3)
                )
                path.addCurve(
                    to: CGPoint(x: 13.1395, y: 24.0958),
                    control1: CGPoint(x: 17.1998, y: 28.3),
                    control2: CGPoint(x: 14.6562, y: 26.0656)
                )
                path.closeSubpath()
            }
            .stroke(
                Color(red: 0.463, green: 0.427, blue: 0.647),
                style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
            )

            // Pupil circle
            Path { path in
                path.addEllipse(in: CGRect(
                    x: 18.2568,
                    y: 18.4688,
                    width: 5.3625,
                    height: 5.3624
                ))
            }
            .stroke(
                Color(red: 0.463, green: 0.427, blue: 0.647),
                style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
            )
        }
        .frame(width: 46, height: 46)
    }
}

#Preview {
    ScanningIcon()
}

