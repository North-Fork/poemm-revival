import Foundation
import Combine

/// Reads the real-world clock every 30 seconds and publishes interpolated
/// PhaseProperties across the 30-minute transition window before each phase boundary.
final class TimePhaseManager: ObservableObject {

    @Published private(set) var interpolatedProperties: PhaseProperties = .defaults(for: .morning)
    @Published private(set) var currentPhase: TimePhase = .morning

    private let transitionWindowMinutes: Double
    private var timer: Timer?

    init(transitionWindowMinutes: Double = 30) {
        self.transitionWindowMinutes = transitionWindowMinutes
        evaluate()
        startTimer()
    }

    deinit { timer?.invalidate() }

    // MARK: - Timer

    private func startTimer() {
        let t = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.evaluate()
        }
        t.tolerance = 5.0
        timer = t
    }

    // MARK: - Evaluation

    func evaluate(date: Date = Date()) {
        let (phase, next, blend) = phaseAndBlend(for: date)
        currentPhase = phase
        let from = PhaseProperties.defaults(for: phase)
        let to   = PhaseProperties.defaults(for: next)
        interpolatedProperties = PhaseProperties.interpolate(from: from, to: to, t: blend)
    }

    // MARK: - Phase + Blend Calculation

    /// Returns the active phase, the next phase, and a blend factor 0→1
    /// where 1 means "fully transitioned into next."
    func phaseAndBlend(for date: Date) -> (current: TimePhase, next: TimePhase, blend: Double) {
        let cal = Calendar.current
        let hour   = cal.component(.hour,   from: date)
        let minute = cal.component(.minute, from: date)
        let minuteOfDay = Double(hour * 60 + minute)

        let phase = resolve(hour: hour)
        let next  = successor(of: phase)

        let endMin = endMinuteOfDay(for: phase)
        var remaining = endMin - minuteOfDay
        if remaining < 0 { remaining += 24 * 60 }  // midnight wrap for night

        let blend: Double
        if remaining <= transitionWindowMinutes {
            blend = 1.0 - (remaining / transitionWindowMinutes)
        } else {
            blend = 0.0
        }
        return (phase, next, max(0, min(1, blend)))
    }

    // MARK: - Helpers

    private func resolve(hour: Int) -> TimePhase {
        switch hour {
        case 23, 0, 1, 2, 3, 4: return .night
        case 5, 6, 7:            return .dawn
        case 8, 9, 10, 11:       return .morning
        case 12, 13, 14, 15, 16: return .afternoon
        case 17, 18, 19:         return .dusk
        case 20, 21, 22:         return .evening
        default:                 return .night
        }
    }

    private func successor(of phase: TimePhase) -> TimePhase {
        let ordered = TimePhase.ordered
        guard let idx = ordered.firstIndex(of: phase) else { return .dawn }
        return ordered[(idx + 1) % ordered.count]
    }

    /// End of phase in minutes-of-day (24-hour). Night ends at 5 × 60 = 300.
    private func endMinuteOfDay(for phase: TimePhase) -> Double {
        switch phase {
        case .night:     return  5 * 60
        case .dawn:      return  8 * 60
        case .morning:   return 12 * 60
        case .afternoon: return 17 * 60
        case .dusk:      return 20 * 60
        case .evening:   return 23 * 60
        }
    }
}
