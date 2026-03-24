import SwiftUI

struct SparkleIcon: View {
    var body: some View {
        ZStack {
            Path { path in
                path.move(to: CGPoint(x: 7.667, y: 3.833))
                path.addLine(to: CGPoint(x: 7.667, y: 15.333))
                path.move(to: CGPoint(x: 1.917, y: 9.583))
                path.addLine(to: CGPoint(x: 13.417, y: 9.583))
                path.move(to: CGPoint(x: 7.667, y: 30.667))
                path.addLine(to: CGPoint(x: 7.667, y: 42.167))
                path.move(to: CGPoint(x: 1.917, y: 36.417))
                path.addLine(to: CGPoint(x: 13.417, y: 36.417))
                path.move(to: CGPoint(x: 13.417, y: 23))
                path.addCurve(to: CGPoint(x: 28.75, y: 38.333), control1: CGPoint(x: 22.361, y: 24.278), control2: CGPoint(x: 27.473, y: 29.389))
                path.addCurve(to: CGPoint(x: 44.084, y: 23), control1: CGPoint(x: 30.028, y: 29.389), control2: CGPoint(x: 35.139, y: 24.278))
                path.addCurve(to: CGPoint(x: 28.75, y: 7.667), control1: CGPoint(x: 35.139, y: 21.722), control2: CGPoint(x: 30.028, y: 16.611))
                path.addCurve(to: CGPoint(x: 13.417, y: 23), control1: CGPoint(x: 27.473, y: 16.611), control2: CGPoint(x: 22.361, y: 21.722))
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
    SparkleIcon()
}
