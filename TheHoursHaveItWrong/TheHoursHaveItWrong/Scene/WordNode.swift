import SpriteKit

/// A poem word rendered as an SKLabelNode child.
/// Kinematics are integrated manually each frame: vel += acc; vel *= friction; pos += vel.
/// This mirrors the KineticObject / Word pattern used throughout the PoEMM Objective-C series.
final class WordNode: SKNode {

    let poemWord: PoemWord

    // MARK: - Kinematics

    var velocity: CGVector = .zero
    var homePosition: CGPoint = .zero
    var wanderTarget: CGPoint = .zero

    // MARK: - Opacity

    var currentOpacity: CGFloat = 0.5
    var targetOpacity: CGFloat = 0.5

    // MARK: - Touch release state

    private var isAttracted = false
    private var releaseCountdown = 0

    // MARK: - Label

    private let label: SKLabelNode

    // MARK: - Init

    init(word: PoemWord, fontSize: CGFloat, fontName: String) {
        self.poemWord = word
        self.label = SKLabelNode(text: word.text)
        super.init()
        label.fontName = fontName
        label.fontSize = fontSize
        label.verticalAlignmentMode   = .center
        label.horizontalAlignmentMode = .center
        addChild(label)
    }

    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) not implemented") }

    // MARK: - Per-Frame Update

    /// Called every frame from PoemScene.update(_:).
    func update(properties: PhaseProperties, attractors: [AttractorNode], screenSize: CGSize) {

        // ── 1. Find nearest attractor within attractorRadius ──────────────────
        var nearestAttractor: AttractorNode?
        var nearestDist = CGFloat.infinity
        for att in attractors {
            let d = dist(position, att.position)
            if d < properties.attractorRadius && d < nearestDist {
                nearestDist = d
                nearestAttractor = att
            }
        }

        // ── 2. Determine target position and friction ─────────────────────────
        let target: CGPoint
        let friction: CGFloat

        if let att = nearestAttractor {
            target = att.position
            friction = properties.attractorFriction
            isAttracted = true
            releaseCountdown = properties.releaseDecayFrames
        } else {
            if isAttracted {
                // Just released from touch — pick a fresh wander destination
                isAttracted = false
                pickNewWanderTarget(properties: properties)
            }
            if releaseCountdown > 0 {
                releaseCountdown -= 1
                // Blend friction smoothly from attractor friction back to drift friction
                let t = CGFloat(releaseCountdown) / CGFloat(properties.releaseDecayFrames)
                friction = properties.attractorFriction * t + properties.driftFriction * (1 - t)
            } else {
                friction = properties.driftFriction
            }
            // Refresh wander target when close enough
            if dist(position, wanderTarget) < 20 {
                pickNewWanderTarget(properties: properties)
            }
            target = wanderTarget
        }

        // ── 3. Compute acceleration toward target ─────────────────────────────
        let dx = target.x - position.x
        let dy = target.y - position.y
        let d  = max(0.001, hypot(dx, dy))
        let acc = CGVector(
            dx: (dx / d) * properties.driftSpeed,
            dy: (dy / d) * properties.driftSpeed
        )

        // ── 4. Integrate velocity ─────────────────────────────────────────────
        velocity.dx += acc.dx + properties.gravityBias.dx
        velocity.dy += acc.dy + properties.gravityBias.dy

        // ── 5. Apply friction ─────────────────────────────────────────────────
        velocity.dx *= friction
        velocity.dy *= friction

        // ── 6. Cap speed to prevent edge runaway ──────────────────────────────
        let speed = hypot(velocity.dx, velocity.dy)
        let maxSpeed: CGFloat = 18
        if speed > maxSpeed {
            velocity.dx = velocity.dx / speed * maxSpeed
            velocity.dy = velocity.dy / speed * maxSpeed
        }

        // ── 7. Integrate position ─────────────────────────────────────────────
        position.x += velocity.dx
        position.y += velocity.dy

        // ── 8. Soft boundary repulsion (60 pt margin) ─────────────────────────
        let margin: CGFloat = 60
        let halfW = screenSize.width  / 2
        let halfH = screenSize.height / 2
        let repulsion: CGFloat = 0.4

        if position.x < -halfW + margin { velocity.dx += repulsion }
        else if position.x >  halfW - margin { velocity.dx -= repulsion }
        if position.y < -halfH + margin { velocity.dy += repulsion }
        else if position.y >  halfH - margin { velocity.dy -= repulsion }

        // ── 9. Opacity lerp ───────────────────────────────────────────────────
        currentOpacity += (targetOpacity - currentOpacity) * 0.02
        alpha = currentOpacity

        // ── 10. Color ─────────────────────────────────────────────────────────
        label.fontColor = properties.wordColor
    }

    // MARK: - Phase Visibility

    /// Sets targetOpacity based on whether this word's phase is the current active phase.
    func applyPhaseVisibility(currentPhase: TimePhase, properties: PhaseProperties) {
        if poemWord.phase == currentPhase {
            targetOpacity = properties.wordOpacityRange.upperBound
        } else {
            // Inactive words fade to a subtle presence — about half the lower bound
            targetOpacity = properties.wordOpacityRange.lowerBound * 0.5
        }
    }

    // MARK: - Helpers

    private func pickNewWanderTarget(properties: PhaseProperties) {
        let angle  = CGFloat.random(in: 0 ..< 2 * .pi)
        let radius = CGFloat.random(in: 0 ... properties.driftRadius)
        wanderTarget = CGPoint(
            x: homePosition.x + cos(angle) * radius,
            y: homePosition.y + sin(angle) * radius
        )
    }

    private func dist(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
        hypot(b.x - a.x, b.y - a.y)
    }
}
