import UIKit

// MARK: - TimePhase

enum TimePhase: String, CaseIterable {
    case night
    case dawn
    case morning
    case afternoon
    case dusk
    case evening

    /// Ordered for successor lookup (night wraps around from evening)
    static let ordered: [TimePhase] = [.night, .dawn, .morning, .afternoon, .dusk, .evening]
}

// MARK: - PhaseProperties

struct PhaseProperties {
    var backgroundTopColor: UIColor
    var backgroundBottomColor: UIColor
    var wordColor: UIColor
    var wordOpacityRange: ClosedRange<CGFloat>
    var driftSpeed: CGFloat
    var driftFriction: CGFloat
    var driftRadius: CGFloat
    var gravityBias: CGVector
    var attractorStrength: CGFloat
    var attractorRadius: CGFloat
    var attractorFriction: CGFloat
    var releaseDecayFrames: Int

    // MARK: Phase Defaults

    static let night = PhaseProperties(
        backgroundTopColor:    UIColor(red: 0.04, green: 0.04, blue: 0.08, alpha: 1),
        backgroundBottomColor: UIColor(red: 0.02, green: 0.02, blue: 0.05, alpha: 1),
        wordColor:             UIColor(red: 0.50, green: 0.55, blue: 0.65, alpha: 1),
        wordOpacityRange:      0.05...0.35,
        driftSpeed:            0.08,
        driftFriction:         0.92,
        driftRadius:           80,
        gravityBias:           .zero,
        attractorStrength:     1.2,
        attractorRadius:       180,
        attractorFriction:     0.85,
        releaseDecayFrames:    90
    )

    static let dawn = PhaseProperties(
        backgroundTopColor:    UIColor(red: 0.05, green: 0.08, blue: 0.25, alpha: 1),
        backgroundBottomColor: UIColor(red: 0.60, green: 0.35, blue: 0.15, alpha: 1),
        wordColor:             UIColor(red: 0.95, green: 0.80, blue: 0.45, alpha: 1),
        wordOpacityRange:      0.25...0.75,
        driftSpeed:            0.15,
        driftFriction:         0.93,
        driftRadius:           130,
        gravityBias:           CGVector(dx: 0, dy: 0.03),   // upward
        attractorStrength:     1.5,
        attractorRadius:       200,
        attractorFriction:     0.87,
        releaseDecayFrames:    75
    )

    static let morning = PhaseProperties(
        backgroundTopColor:    UIColor(red: 0.12, green: 0.16, blue: 0.22, alpha: 1),
        backgroundBottomColor: UIColor(red: 0.08, green: 0.12, blue: 0.18, alpha: 1),
        wordColor:             UIColor(red: 1.00, green: 1.00, blue: 1.00, alpha: 1),
        wordOpacityRange:      0.50...1.00,
        driftSpeed:            0.25,
        driftFriction:         0.90,
        driftRadius:           200,
        gravityBias:           .zero,
        attractorStrength:     2.0,
        attractorRadius:       220,
        attractorFriction:     0.82,
        releaseDecayFrames:    60
    )

    static let afternoon = PhaseProperties(
        backgroundTopColor:    UIColor(red: 0.22, green: 0.15, blue: 0.05, alpha: 1),
        backgroundBottomColor: UIColor(red: 0.12, green: 0.08, blue: 0.02, alpha: 1),
        wordColor:             UIColor(red: 0.95, green: 0.80, blue: 0.45, alpha: 1),
        wordOpacityRange:      0.40...0.85,
        driftSpeed:            0.18,
        driftFriction:         0.88,
        driftRadius:           150,
        gravityBias:           CGVector(dx: 0, dy: -0.025),  // downward / heavy
        attractorStrength:     1.6,
        attractorRadius:       200,
        attractorFriction:     0.84,
        releaseDecayFrames:    80
    )

    static let dusk = PhaseProperties(
        backgroundTopColor:    UIColor(red: 0.30, green: 0.10, blue: 0.25, alpha: 1),
        backgroundBottomColor: UIColor(red: 0.55, green: 0.25, blue: 0.10, alpha: 1),
        wordColor:             UIColor(red: 0.85, green: 0.60, blue: 0.80, alpha: 1),
        wordOpacityRange:      0.30...0.80,
        driftSpeed:            0.20,
        driftFriction:         0.91,
        driftRadius:           250,
        gravityBias:           .zero,
        attractorStrength:     1.8,
        attractorRadius:       210,
        attractorFriction:     0.83,
        releaseDecayFrames:    70
    )

    static let evening = PhaseProperties(
        backgroundTopColor:    UIColor(red: 0.05, green: 0.06, blue: 0.15, alpha: 1),
        backgroundBottomColor: UIColor(red: 0.02, green: 0.03, blue: 0.08, alpha: 1),
        wordColor:             UIColor(red: 0.55, green: 0.60, blue: 0.70, alpha: 1),
        wordOpacityRange:      0.10...0.55,
        driftSpeed:            0.10,
        driftFriction:         0.94,
        driftRadius:           100,
        gravityBias:           .zero,
        attractorStrength:     1.3,
        attractorRadius:       190,
        attractorFriction:     0.86,
        releaseDecayFrames:    85
    )

    static func defaults(for phase: TimePhase) -> PhaseProperties {
        switch phase {
        case .night:     return .night
        case .dawn:      return .dawn
        case .morning:   return .morning
        case .afternoon: return .afternoon
        case .dusk:      return .dusk
        case .evening:   return .evening
        }
    }

    // MARK: Linear Interpolation

    static func interpolate(from a: PhaseProperties, to b: PhaseProperties, t: Double) -> PhaseProperties {
        let ct = CGFloat(t)
        func lerp(_ x: CGFloat, _ y: CGFloat) -> CGFloat { x + (y - x) * ct }
        return PhaseProperties(
            backgroundTopColor:    a.backgroundTopColor.lerp(to: b.backgroundTopColor, t: ct),
            backgroundBottomColor: a.backgroundBottomColor.lerp(to: b.backgroundBottomColor, t: ct),
            wordColor:             a.wordColor.lerp(to: b.wordColor, t: ct),
            wordOpacityRange:      lerp(a.wordOpacityRange.lowerBound, b.wordOpacityRange.lowerBound) ... lerp(a.wordOpacityRange.upperBound, b.wordOpacityRange.upperBound),
            driftSpeed:            lerp(a.driftSpeed,         b.driftSpeed),
            driftFriction:         lerp(a.driftFriction,      b.driftFriction),
            driftRadius:           lerp(a.driftRadius,        b.driftRadius),
            gravityBias:           CGVector(
                                       dx: lerp(a.gravityBias.dx, b.gravityBias.dx),
                                       dy: lerp(a.gravityBias.dy, b.gravityBias.dy)
                                   ),
            attractorStrength:     lerp(a.attractorStrength,  b.attractorStrength),
            attractorRadius:       lerp(a.attractorRadius,    b.attractorRadius),
            attractorFriction:     lerp(a.attractorFriction,  b.attractorFriction),
            releaseDecayFrames:    Int(lerp(CGFloat(a.releaseDecayFrames), CGFloat(b.releaseDecayFrames)))
        )
    }
}

// MARK: - UIColor Linear Interpolation

extension UIColor {
    func lerp(to other: UIColor, t: CGFloat) -> UIColor {
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        other.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        return UIColor(
            red:   r1 + (r2 - r1) * t,
            green: g1 + (g2 - g1) * t,
            blue:  b1 + (b2 - b1) * t,
            alpha: a1 + (a2 - a1) * t
        )
    }

    /// P8 — Activity-Modulated Background.
    /// Shifts the color toward warm ember: red up, green slightly up, blue down.
    /// `activity` in [0, 1]; 0 = no change, 1 = full warmth.
    func warmed(by activity: CGFloat) -> UIColor {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        return UIColor(
            red:   min(1.0, r + 0.30 * activity),
            green: min(1.0, g + 0.10 * activity),
            blue:  max(0.0, b - 0.15 * activity),
            alpha: a
        )
    }
}
