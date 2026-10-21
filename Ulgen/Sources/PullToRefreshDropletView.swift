import SwiftUI

/// 1:1 Euler Spring-Damper Liquid Droplet for Pull-To-Refresh.
/// Derived from Android `PullToRefreshDroplet.kt` and `index.html` lines 45820-46022.
/// - Euler numerical integration (kY=130, dY=15, kR=150, dR=16, kW=150, dW=16).
/// - Release multiplier: 2.25x spring, 1.5x damping.
/// - Dynamic Bézier path morphing with neck contraction and detachment.
public struct PullToRefreshDropletView: View {
    public var pullProgress: CGFloat // 0.0 to 1.0+
    public var isRefreshing: Bool
    public var isDarkMode: Bool

    @State private var currentY: CGFloat = 0.0
    @State private var currentVy: CGFloat = 0.0
    @State private var currentR: CGFloat = 21.6
    @State private var currentVr: CGFloat = 0.0
    @State private var currentW: CGFloat = 26.4
    @State private var currentVw: CGFloat = 0.0
    @State private var currentOpacity: CGFloat = 0.0
    @State private var rotationDegrees: Double = 0.0

    public init(pullProgress: CGFloat, isRefreshing: Bool = false, isDarkMode: Bool = false) {
        self.pullProgress = pullProgress
        self.isRefreshing = isRefreshing
        self.isDarkMode = isDarkMode
    }

    public var body: some View {
        TimelineView(.animation(paused: pullProgress <= 0 && !isRefreshing && currentOpacity <= 0.01 && abs(currentY) < 0.5)) { timeline in
            Canvas { context, size in
                let scale = size.width / 72.0
                let cx = 36.0 * scale
                let y = currentY * scale
                let r = max(1.0, currentR * scale)
                let w = max(0.0, currentW * scale)

                guard currentOpacity > 0.005 else { return }

                var dropletPath = Path()
                if w <= 0.1 * scale {
                    dropletPath.addEllipse(in: CGRect(x: cx - r, y: y - r, width: r * 2.0, height: r * 2.0))
                } else {
                    let progress = min(1.0, max(0.0, (currentY - 22.0) / 98.0))
                    let wNeck = w * (1.0 - progress * 0.45)

                    dropletPath.move(to: CGPoint(x: cx - w, y: 0.0))
                    dropletPath.addCurve(
                        to: CGPoint(x: cx - r, y: y),
                        control1: CGPoint(x: cx - w, y: y * 0.3),
                        control2: CGPoint(x: cx - wNeck, y: y * 0.55)
                    )
                    dropletPath.addArc(
                        center: CGPoint(x: cx, y: y),
                        radius: r,
                        startAngle: .degrees(180),
                        endAngle: .degrees(0),
                        clockwise: true
                    )
                    dropletPath.addCurve(
                        to: CGPoint(x: cx + w, y: 0.0),
                        control1: CGPoint(x: cx + wNeck, y: y * 0.55),
                        control2: CGPoint(x: cx + w, y: y * 0.3)
                    )
                    dropletPath.closeSubpath()
                }

                // Fill
                let glassBg = isDarkMode ? Color(hex: "#1E1B18").opacity(0.95) : Color(hex: "#FEFCE8").opacity(0.98)
                context.fill(dropletPath, with: .color(glassBg))

                // Border
                let glassBorder = isDarkMode ? Color.white.opacity(0.4) : Color(hex: "#A16207").opacity(0.25)
                context.stroke(dropletPath, with: .color(glassBorder), lineWidth: 1.5)

                // Spinner
                let isIdle = pullProgress <= 0 && !isRefreshing
                let spinScale = isIdle ? min(1.0, max(0.6, 0.6 + (currentY / 75.0) * 0.4)) : 1.0
                let spinAlpha = isIdle ? min(1.0, max(0.0, (currentY - 10.0) / 45.0)) : 1.0

                let spinnerRadius = 10.0 * scale * spinScale
                let accentColor = (isDarkMode ? Color(hex: "#D97706") : Color(hex: "#A16207")).opacity(currentOpacity * spinAlpha)

                let sweepAngle: Double = isRefreshing ? 270.0 : Double(min(1.0, max(0.0, pullProgress)) * 270.0)

                var spinnerPath = Path()
                let startAngle = isRefreshing ? rotationDegrees : -90.0
                spinnerPath.addArc(
                    center: CGPoint(x: cx, y: y),
                    radius: spinnerRadius,
                    startAngle: .degrees(startAngle),
                    endAngle: .degrees(startAngle + sweepAngle),
                    clockwise: false
                )
                context.stroke(spinnerPath, with: .color(accentColor), style: StrokeStyle(lineWidth: 3.0 * spinScale, lineCap: .round))
            }
            .frame(width: 72, height: 160)
            .opacity(currentOpacity)
            .onChange(of: timeline.date) { _ in
                stepPhysics(dt: 0.016)
                if isRefreshing {
                    rotationDegrees = (rotationDegrees + 6.0).truncatingRemainder(dividingBy: 360.0)
                }
            }
        }
    }

    private func stepPhysics(dt: CGFloat) {
        let prog = pullProgress
        let refreshing = isRefreshing

        let state: String
        if refreshing {
            state = "REFRESHING"
        } else if prog >= 1.0 {
            state = "ARMED"
        } else if prog > 0 {
            state = "PULLING"
        } else {
            state = "IDLE"
        }

        let rawP = min(1.0, max(0.0, prog))
        let targetY: CGFloat
        let targetR: CGFloat
        let targetW: CGFloat
        let targetOpacity: CGFloat

        switch state {
        case "PULLING":
            targetY = 22.0 + rawP * 98.0
            targetR = 21.6 - rawP * 6.0
            targetW = 26.4 - rawP * 15.6
            targetOpacity = rawP > 0 ? 1.0 : 0.0
        case "ARMED", "READY", "REFRESHING":
            targetY = 85.0
            targetR = 25.2
            targetW = 0.0
            targetOpacity = 1.0
        default: // IDLE
            targetY = 0.0
            targetR = 21.6
            targetW = 26.4
            targetOpacity = currentY > 2.0 ? 1.0 : 0.0
        }

        var kY: CGFloat = 130.0
        var dY: CGFloat = 15.0
        var kR: CGFloat = 150.0
        var adR: CGFloat = 16.0
        var kW: CGFloat = 150.0
        var adW: CGFloat = 16.0

        if state == "IDLE" {
            kY *= 2.25
            dY *= 1.5
            kR *= 2.25
            adR *= 1.5
            kW *= 2.25
            adW *= 1.5
        }

        let fY = -kY * (currentY - targetY) - dY * currentVy
        currentVy += fY * dt
        currentY += currentVy * dt

        let fR = -kR * (currentR - targetR) - adR * currentVr
        currentVr += fR * dt
        currentR += currentVr * dt

        let fW = -kW * (currentW - targetW) - adW * currentVw
        currentVw += fW * dt
        currentW += currentVw * dt

        var newOpacity = currentOpacity + (targetOpacity - currentOpacity) * 0.25
        if abs(newOpacity - targetOpacity) < 0.01 { newOpacity = targetOpacity }
        currentOpacity = newOpacity

        if state == "IDLE" && (abs(currentY - targetY) < 1.5 || newOpacity < 0.05) {
            currentOpacity = 0.0
            currentY = 0.0
            currentVy = 0.0
            currentR = 21.6
            currentVr = 0.0
            currentW = 26.4
            currentVw = 0.0
        }
    }
}
