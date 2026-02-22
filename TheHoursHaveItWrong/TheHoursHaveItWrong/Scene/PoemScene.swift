import SpriteKit
import Combine

/// Root SpriteKit scene.
///
/// Uses .resizeFill so SpriteKit sets scene.size from the actual rendered view bounds.
/// All node setup is deferred to didChangeSize(_:) so we always have real dimensions.
final class PoemScene: SKScene {

    // MARK: - Phase Manager

    var phaseManager: TimePhaseManager? {
        didSet {
            guard let manager = phaseManager else { return }
            currentProperties = manager.interpolatedProperties
            applyProperties(manager.interpolatedProperties, phase: manager.currentPhase)
            subscribeToPhaseManager()
        }
    }

    // MARK: - Nodes

    private var worldNode: SKNode?
    private var backgroundNode: BackgroundNode?
    private var wordNodes: [WordNode] = []
    private var activeAttractors: [ObjectIdentifier: AttractorNode] = [:]

    // MARK: - State

    private var currentProperties: PhaseProperties = .defaults(for: .morning)
    private var currentPhase: TimePhase = .morning
    private var cancellables = Set<AnyCancellable>()
    private let appProps = AppProperties.shared
    private var didBuildContent = false

    // MARK: - P8 Activity Meter

    /// 0 = idle, 1 = fully active. Pumped by touch-begins, decays over ~30 s.
    private var activityMeter: CGFloat = 0
    private let activityDecayRate: CGFloat = 1.0 / (30.0 * 60.0)

    // MARK: - Lifecycle

    override func didMove(to view: SKView) {
        physicsWorld.gravity = .zero
        backgroundColor = .black
        view.isMultipleTouchEnabled = true
        // Node setup happens in didChangeSize once we have real dimensions.
    }

    /// Called by SpriteKit whenever the scene's size is updated by the view.
    /// With .resizeFill this fires after SwiftUI lays out the SKView.
    override func didChangeSize(_ oldSize: CGSize) {
        guard size.width > 50 && size.height > 50 else { return }
        guard !didBuildContent else { return }
        didBuildContent = true
        buildContent()
    }

    private func buildContent() {
        // worldNode sits at the true center of the scene.
        // With anchor (0,0) — SpriteKit's actual default — this is (w/2, h/2).
        // With anchor (0.5,0.5) it would be (0,0), but we add size/2 either way
        // so the math is correct regardless of which anchor SpriteKit uses.
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let world = SKNode()
        world.position = center
        addChild(world)
        worldNode = world

        let bg = BackgroundNode(size: size)
        world.addChild(bg)
        backgroundNode = bg

        let poemWords = PoemLoader.load()
        for word in poemWords {
            let node = WordNode(word: word, fontSize: appProps.fontSize, fontName: appProps.fontName)
            node.homePosition   = randomHome(for: word.phase)
            node.position       = node.homePosition
            node.wanderTarget   = node.homePosition
            node.currentOpacity = 0
            node.alpha          = 0
            world.addChild(node)
            wordNodes.append(node)
        }

        // Apply whatever phase properties arrived before content was ready.
        applyProperties(currentProperties, phase: currentPhase)
    }

    // MARK: - Phase Subscription

    private func subscribeToPhaseManager() {
        cancellables.removeAll()
        guard let manager = phaseManager else { return }
        manager.$interpolatedProperties
            .receive(on: RunLoop.main)
            .sink { [weak self] props in
                guard let self else { return }
                self.applyProperties(props, phase: manager.currentPhase)
            }
            .store(in: &cancellables)
    }

    private func applyProperties(_ props: PhaseProperties, phase: TimePhase) {
        currentProperties = props
        currentPhase = phase
        for node in wordNodes {
            node.applyPhaseVisibility(currentPhase: phase, properties: props)
        }
    }

    // MARK: - Render Loop

    override func update(_ currentTime: TimeInterval) {
        guard let world = worldNode else { return }

        // P8: decay the activity meter each frame.
        activityMeter = max(0, activityMeter - activityDecayRate)

        let attractors = Array(activeAttractors.values)

        for node in wordNodes {
            node.update(properties: currentProperties, attractors: attractors, screenSize: size)
        }

        // P8: background warms toward ember as activity rises.
        backgroundNode?.updateIfNeeded(
            topColor:    currentProperties.backgroundTopColor.warmed(by: activityMeter),
            bottomColor: currentProperties.backgroundBottomColor.warmed(by: activityMeter),
            size:        size
        )
    }

    // MARK: - Touch Handling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let world = worldNode else { return }
        for touch in touches {
            // P8: each new touch finger pumps the warmth meter.
            activityMeter = min(1.0, activityMeter + 0.25)
            let att = AttractorNode()
            att.position = touch.location(in: world)
            world.addChild(att)
            activeAttractors[ObjectIdentifier(touch)] = att
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let world = worldNode else { return }
        for touch in touches {
            activeAttractors[ObjectIdentifier(touch)]?.position = touch.location(in: world)
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) { deactivate(touches) }
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) { deactivate(touches) }

    private func deactivate(_ touches: Set<UITouch>) {
        for touch in touches {
            let key = ObjectIdentifier(touch)
            activeAttractors[key]?.removeFromParent()
            activeAttractors.removeValue(forKey: key)
        }
    }

    // MARK: - Home Positions (worldNode space: origin = screen center)

    private func randomHome(for phase: TimePhase) -> CGPoint {
        let hw = size.width  / 2
        let hh = size.height / 2
        switch phase {
        case .night:
            return CGPoint(x: .random(in: -hw*0.25 ... hw*0.25),
                           y: .random(in: -hh*0.25 ... hh*0.25))
        case .dawn:
            return CGPoint(x: .random(in: -hw*0.45 ... hw*0.45),
                           y: .random(in:  hh*0.05 ... hh*0.45))
        case .morning:
            return CGPoint(x: .random(in: -hw*0.42 ... hw*0.42),
                           y: .random(in: -hh*0.42 ... hh*0.42))
        case .afternoon:
            return CGPoint(x: .random(in: -hw*0.45 ... hw*0.45),
                           y: .random(in: -hh*0.45 ... hh*0.10))
        case .dusk:
            if Bool.random() {
                let side: CGFloat = Bool.random() ? 1 : -1
                return CGPoint(x: side * .random(in: hw*0.25 ... hw*0.45),
                               y: .random(in: -hh*0.45 ... hh*0.45))
            } else {
                let side: CGFloat = Bool.random() ? 1 : -1
                return CGPoint(x: .random(in: -hw*0.45 ... hw*0.45),
                               y: side * .random(in: hh*0.25 ... hh*0.45))
            }
        case .evening:
            return CGPoint(x: .random(in: -hw*0.30 ... hw*0.30),
                           y: .random(in: -hh*0.30 ... hh*0.30))
        }
    }
}
