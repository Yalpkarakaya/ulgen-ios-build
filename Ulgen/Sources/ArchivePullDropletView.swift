import SwiftUI

/// 1:1 Euler Spring-Damper Liquid Droplet for Bottom Archive Pull.
/// Derived from Android `ArchivePullDroplet.kt` and `index.html` lines 45832-46069.
/// - Euler numerical integration (kY=130, dY=15, kR=150, dR=16, kW=150, dW=16).
/// - Release multiplier: 2.25x spring, 1.5x damping.
/// - Exact Bézier path for inverted bottom droplet (viewBox 0 0 72 120).
/// - Exact 1:1 SVG Archive Chest Icon (line 36592) in Color(#048058). ZERO text!
public struct ArchivePullDropletView: View {
    public var pullProgress: CGFloat // 0.0 to 1.0+
    public var isArmed: Bool
    public var isDarkMode: Bool

    @State private var currentAY: CGFloat = 120.0
    @State private var currentVy: CGFloat = 0.0
    @State private var currentAR: CGFloat = 21.6
    @State private var currentVr: CGFloat = 0.0
    @State private var currentAW: CGFloat = 26.4
    @State private var currentVw: CGFloat = 0.0
    @State private var currentOpacity: CGFloat = 0.0

    public init(pullProgress: CGFloat, isArmed: Bool = false, isDarkMode: Bool = false) {
        self.pullProgress = pullProgress
        self.isArmed = isArmed
        self.isDarkMode = isDarkMode
    }

    public var body: some View {
        TimelineView(.animation(paused: pullProgress <= 0 && !isArmed && currentOpacity <= 0.01 && abs(currentAY - 120.0) < 0.5)) { timeline in
            Canvas { context, size in
                let scale = size.width / 72.0
                let cx = 36.0 * scale
                let ay = currentAY * scale
                let ar = max(1.0, currentAR * scale)
                let aw = max(0.0, currentAW * scale)
                let h = 120.0 * scale

                guard currentOpacity > 0.005 else { return }

                var dropletPath = Path()
                if aw <= 0.1 * scale {
                    dropletPath.addEllipse(in: CGRect(x: cx - ar, y: ay - ar, width: ar * 2.0, height: ar * 2.0))
                } else {
                    let progressRatio = min(1.0, max(0.0, (120.0 - currentAY - 22.0) / 53.0))
                    let wNeck = aw * (1.0 - progressRatio * 0.45)

                    dropletPath.move(to: CGPoint(x: cx - aw, y: h))
                    dropletPath.addCurve(
                        to: CGPoint(x: cx - ar, y: ay),
                        control1: CGPoint(x: cx - aw, y: h - (h - ay) * 0.3),
                        control2: CGPoint(x: cx - wNeck, y: h - (h - ay) * 0.55)
                    )
                    dropletPath.addArc(
                        center: CGPoint(x: cx, y: ay),
                        radius: ar,
                        startAngle: .degrees(180),
                        endAngle: .degrees(0),
                        clockwise: false
                    )
                    dropletPath.addCurve(
                        to: CGPoint(x: cx + aw, y: h),
                        control1: CGPoint(x: cx + wNeck, y: h - (h - ay) * 0.55),
                        control2: CGPoint(x: cx + aw, y: h - (h - ay) * 0.3)
                    )
                    dropletPath.closeSubpath()
                }

                // Fill Brush
                let glassBg = isDarkMode ? Color(hex: "#1E1B18").opacity(0.95) : Color(hex: "#FEFCE8").opacity(0.98)
                context.fill(dropletPath, with: .color(glassBg))

                // Border
                let glassBorder = isDarkMode ? Color.white.opacity(0.4) : Color(hex: "#048058").opacity(0.25)
                context.stroke(dropletPath, with: .color(glassBorder), lineWidth: 1.5)

                // SVG Archive Chest Icon (1:1 with index.html lines 36592 & 46063-46068)
                let isIdle = pullProgress <= 0 && !isArmed
                let iconScale = isIdle ? min(1.0, max(0.6, 0.6 + ((120.0 - currentAY) / 75.0) * 0.4)) : 1.0
                let iconAlpha = isIdle ? min(1.0, max(0.0, ((120.0 - currentAY) - 10.0) / 45.0)) : 1.0

                let unit = (18.0 / 24.0) * scale * iconScale
                let originX = cx - 12.0 * unit
                let originY = ay - 12.0 * unit
                let strokeW = 2.0 * iconScale
                let accentColor = Color(hex: "#048058").opacity(currentOpacity * iconAlpha)

                // 1. Box Body: polyline 21 8 21 21 3 21 3 8
                var bodyPath = Path()
                bodyPath.move(to: CGPoint(x: originX + 21.0 * unit, y: originY + 8.0 * unit))
                bodyPath.addLine(to: CGPoint(x: originX + 21.0 * unit, y: originY + 21.0 * unit))
                bodyPath.addLine(to: CGPoint(x: originX + 3.0 * unit, y: originY + 21.0 * unit))
                bodyPath.addLine(to: CGPoint(x: originX + 3.0 * unit, y: originY + 8.0 * unit))
                context.stroke(bodyPath, with: .color(accentColor), style: StrokeStyle(lineWidth: strokeW, lineCap: .round, lineJoin: .round))

                // 2. Box Lid: rect x=1 y=3 width=22 height=5 rx=1
                let lidRect = CGRect(x: originX + 1.0 * unit, y: originY + 3.0 * unit, width: 22.0 * unit, height: 5.0 * unit)
                let lidPath = Path(roundedRect: lidRect, cornerRadius: 1.0 * unit)
                context.stroke(lidPath, with: .color(accentColor), style: StrokeStyle(lineWidth: strokeW, lineCap: .round, lineJoin: .round))

                // 3. Notch Handle: line x1=10 y1=12 x2=14 y2=12
                var notchPath = Path()
                notchPath.move(to: CGPoint(x: originX + 10.0 * unit, y: originY + 12.0 * unit))
                notchPath.addLine(to: CGPoint(x: originX + 14.0 * unit, y: originY + 12.0 * unit))
                context.stroke(notchPath, with: .color(accentColor), style: StrokeStyle(lineWidth: strokeW, lineCap: .round))
            }
            .frame(width: 72, height: 120)
            .opacity(currentOpacity)
            .onChange(of: timeline.date) { _ in
                stepPhysics(dt: 0.016)
            }
        }
    }

    private func stepPhysics(dt: CGFloat) {
        let prog = pullProgress
        let armed = isArmed

        let state: String
        if armed {
            state = "ARMED"
        } else if prog >= 1.0 {
            state = "READY"
        } else if prog > 0 {
            state = "PULLING"
        } else {
            state = "IDLE"
        }

        let rawP = min(1.0, max(0.0, prog))
        let targetAY: CGFloat
        let targetAR: CGFloat
        let targetAW: CGFloat
        let targetAOpacity: CGFloat

        switch state {
        case "PULLING":
            targetAY = 98.0 - rawP * 53.0
            targetAR = 21.6 - rawP * 6.0
            targetAW = 26.4 - rawP * 15.6
            targetAOpacity = rawP > 0 ? 1.0 : 0.0
        case "ARMED", "READY":
            targetAY = 58.0
            targetAR = 25.2
            targetAW = 0.0
            targetAOpacity = 1.0
        default: // IDLE
            targetAY = 120.0
            targetAR = 21.6
            targetAW = 26.4
            targetAOpacity = currentAY < 118.0 ? 1.0 : 0.0
        }

        var akY: CGFloat = 130.0
        var adY: CGFloat = 15.0
        var akR: CGFloat = 150.0
        var adR: CGFloat = 16.0
        var akW: CGFloat = 150.0
        var adW: CGFloat = 16.0

        if state == "IDLE" {
            akY *= 2.25
            adY *= 1.5
            akR *= 2.25
            adR *= 1.5
            akW *= 2.25
            adW *= 1.5
        }

        let fAY = -akY * (currentAY - targetAY) - adY * currentVy
        currentVy += fAY * dt
        currentAY += currentVy * dt

        let fAR = -akR * (currentAR - targetAR) - adR * currentVr
        currentVr += fAR * dt
        currentAR += currentVr * dt

        let fAW = -akW * (currentAW - targetAW) - adW * currentVw
        currentVw += fAW * dt
        currentAW += currentVw * dt

        var newOpacity = currentOpacity + (targetAOpacity - currentOpacity) * 0.2
        if abs(newOpacity - targetAOpacity) < 0.01 { newOpacity = targetAOpacity }
        currentOpacity = newOpacity

        if state == "IDLE" && abs(currentAY - targetAY) < 0.5 && abs(currentVy) < 0.5 && newOpacity < 0.05 {
            currentOpacity = 0.0
            currentAY = 120.0
            currentVy = 0.0
            currentAR = 21.6
            currentVr = 0.0
            currentAW = 26.4
            currentVw = 0.0
        }
    }
}
