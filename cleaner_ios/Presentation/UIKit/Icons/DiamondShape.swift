import SwiftUI

/// A reusable gem/diamond icon shape matching the Figma SVG (viewBox 0 0 22 22).
/// Use with FillStyle(eoFill: true) to get the correct facet cutouts.
struct DiamondShape: Shape {
    func path(in rect: CGRect) -> Path {
        let sw: CGFloat = 22
        let sh: CGFloat = 22
        let sx = { (x: CGFloat) in rect.minX + x / sw * rect.width }
        let sy = { (y: CGFloat) in rect.minY + y / sh * rect.height }
        let pt = { (x: CGFloat, y: CGFloat) in CGPoint(x: sx(x), y: sy(y)) }

        var p = Path()

        // Subpath 1: outer silhouette
        p.move(to: pt(5.37853, 1))
        p.addCurve(to: pt(3.88107, 1.80632),
                   control1: pt(5.08218, 1.0001),
                   control2: pt(4.26797, 1.35507))
        p.addLine(to: pt(0.189847, 7.36993))
        p.addCurve(to: pt(0.11991, 8.51326),
                   control1: pt(-0.0353903, 7.71107),
                   control2: pt(-0.0621308, 8.14731))
        p.addCurve(to: pt(8.37656, 19.1422),
                   control1: pt(2.14106, 12.5732),
                   control2: pt(4.94811, 16.1867))
        p.addLine(to: pt(10.1764, 20.6939))
        p.addCurve(to: pt(10.9997, 21),
                   control1: pt(10.4057, 20.8914),
                   control2: pt(10.6977, 21))
        p.addCurve(to: pt(11.823, 20.6939),
                   control1: pt(11.3017, 21),
                   control2: pt(11.5937, 20.8914))
        p.addLine(to: pt(13.6228, 19.1433))
        p.addCurve(to: pt(21.8805, 8.51326),
                   control1: pt(17.0518, 16.1876),
                   control2: pt(19.8592, 12.5736))
        p.addCurve(to: pt(18.1163, 1.80632),
                   control1: pt(22.0626, 8.14731),
                   control2: pt(22.0348, 7.71107))
        p.addCurve(to: pt(16.6198, 1.00103),
                   control1: pt(17.952, 1.55873),
                   control2: pt(17.2074, 1.07476))
        p.closeSubpath()

        // Subpath 2: left top facet
        p.move(to: pt(5.16461, 2.66536))
        p.addLine(to: pt(7.78518, 2.55062))
        p.addLine(to: pt(5.81564, 7.30171))
        p.addLine(to: pt(2.09768, 7.29034))
        p.closeSubpath()

        // Subpath 3: right top facet
        p.move(to: pt(19.9007, 7.29034))
        p.addLine(to: pt(18.4546, 7.44333))
        p.addLine(to: pt(16.2845, 7.63974))
        p.addLine(to: pt(16.1827, 7.30171))
        p.addLine(to: pt(14.2132, 2.55062))
        p.addLine(to: pt(16.6198, 2.55062))
        p.addLine(to: pt(16.7411, 2.58105))
        p.addLine(to: pt(16.8338, 2.66536))
        p.closeSubpath()

        // Subpath 4: center top facet
        p.move(to: pt(9.45646, 2.55062))
        p.addLine(to: pt(12.5419, 2.55062))
        p.addLine(to: pt(14.6935, 7.74002))
        p.addLine(to: pt(7.30488, 7.74002))
        p.closeSubpath()

        // Subpath 5: left lower facet
        p.move(to: pt(2.03083, 8.84199))
        p.addLine(to: pt(3.38328, 8.98568))
        p.addLine(to: pt(6.01002, 9.21517))
        p.addLine(to: pt(9.22403, 17.8304))
        p.closeSubpath()

        // Subpath 6: right lower facet
        p.move(to: pt(19.9686, 8.84199))
        p.addLine(to: pt(18.6161, 8.98568))
        p.addLine(to: pt(15.9894, 9.21517))
        p.addLine(to: pt(12.7754, 17.8304))
        p.closeSubpath()

        // Subpath 7: center lower facet
        p.move(to: pt(7.69365, 9.31131))
        p.addLine(to: pt(10.9992, 18.1746))
        p.addLine(to: pt(14.3058, 9.31131))
        p.closeSubpath()

        return p
    }
}

#Preview {
    ZStack {
        Color.purple.opacity(0.6).ignoresSafeArea()
        DiamondShape()
            .fill(Color.white, style: FillStyle(eoFill: true))
            .frame(width: 44, height: 44)
    }
}

