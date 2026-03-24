import SwiftUI
/// A reusable checkmark/tick icon shape matching the Figma SVG (viewBox 0 0 7 6).
/// Use with .stroke() for the correct appearance.
struct TickShape: Shape {
    func path(in rect: CGRect) -> Path {
        // SVG: M0.75 3.12037L2.52778 5.19444L6.08333 0.75
        var path = Path()
        let x0 = rect.minX + rect.width * (0.75 / 7.0)
        let y0 = rect.minY + rect.height * (3.12037 / 6.0)
        let x1 = rect.minX + rect.width * (2.52778 / 7.0)
        let y1 = rect.minY + rect.height * (5.19444 / 6.0)
        let x2 = rect.minX + rect.width * (6.08333 / 7.0)
        let y2 = rect.minY + rect.height * (0.75 / 6.0)
        path.move(to: CGPoint(x: x0, y: y0))
        path.addLine(to: CGPoint(x: x1, y: y1))
        path.addLine(to: CGPoint(x: x2, y: y2))
        return path
    }
}
#Preview {
    ZStack {
        Color.green.ignoresSafeArea()
        TickShape()
            .stroke(Color.white, style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
            .frame(width: 28, height: 24)
    }
}
