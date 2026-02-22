import SpriteKit
import Combine

/// Root SpriteKit scene. Owns the render loop, touch dispatch, and phase subscription.
/// Set phaseManager AFTER calling skView.presentScene(scene) so that didMove(to:) has
/// already built the word nodes before applyProperties is called.
final class PoemScene: SKScene {

    // MARK: - Phase Manager (set externally by PoemSceneView)

    var phaseManager: TimePhaseManager? {
        didSet {
            guard let manager = phaseManager else { return }
            applyProperties(manager.interpolatedProperties, phase: manager.currentPhase)
            subscribeToPhaseManager()
        }
    }

    // MARK: - Nodes

    private var backgroundNode: BackgroundNode!
    private var wordNodes: [WordNode] = []
    private var activeAttractors: [ObjectIdentifier: AttractorNode] = [:]

    // MARK: - State

    private var currentProperties: PhaseProperties = .defaults(for: .morning)
    private var cancellables = Set<AnyCancellable>()
    private let appProps = AppProperties.shared

    // MARK: - Scene Lifecycle

    override func didMove(to view: SKView) {
        physicsWorld.gravity = .zero
        backgroundColor = .black
        view.isMultipleTouchEnabled = true
        setupBackground()
        setupWords()
    }

    // MARK: - Setup

    private func setupBackground() {
        backgroundNode = BackgroundNode(size: size)
        addChild(backgroundNode)
    }

    private func setupWords() {
        let poemWords = PoemLoader.load()
        for word in poemWords {
            let node = WordNode(word: word, fontSize: appProps.fontSize, fontName: appProps.fontName)
            node.homePosition  = randomHomePosition(for: word.phase)
            node.position      = node.homePosition
            node.wanderTarget  = node.homePosition
            node.currentOpacity = 0
            node.alpha          = 0
            addChild(node)
            wordNodes.append(node)
        }
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
        for node in wordNodes {
            node.applyPhaseVisibility(currentPhase: phase, properties: props)
        }
    }

    // MARK: - Render Loop

    override func update(_ currentTime: TimeInterval) {
        let attractors = Array(activeAttractors.values)
        let sceneSize  = size

        for node in wordNodes {
            node.update(properties: currentProperties, attractors: attractors, screenSize: sceneSize)
        }

        backgroundNode?.updateIfNeeded(
            topColor:    currentProperties.backgroundTopColor,
            bottomColor: currentProperties.backgroundBottomColor,
            size:        sceneSize
        )
    }

    // MARK: - Touch Handling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let attractor = AttractorNode()
            attractor.position = touch.location(in: self)
            addChild(attractor)
            activeAttractors[ObjectIdentifier(touch)] = attractor
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            activeAttractors[ObjectIdentifier(touch)]?.position = touch.location(in: self)
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        deactivate(touches)
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        deactivate(touches)
    }

    private func deactivate(_ touches: Set<UITouch>) {
        for touch in touches {
            let key = ObjectIdentifier(touch)
            activeAttractors[key]?.removeFromParent()
            activeAttractors.removeValue(forKey: key)
        }
    }

    // MARK: - Home Position Assignment
    //
    // SpriteKit scene origin is at center (anchorPoint = 0.5, 0.5 by default).
    // size.width / size.height are the full screen dimensions.
    // Positions range from (-w/2, -h/2) to (w/2, h/2).

    private func randomHomePosition(for phase: TimePhase) -> CGPoint {
        let w = size.width
        let h = size.height
        let hw = w / 2
        let hh = h / 2

        switch phase {
        case .night:
            // Tight cluster around center
            return CGPoint(
                x: CGFloat.random(in: -hw * 0.25 ... hw * 0.25),
                y: CGFloat.random(in: -hh * 0.25 ... hh * 0.25)
            )
        case .dawn:
            // Upper half — words are "rising"
            return CGPoint(
                x: CGFloat.random(in: -hw * 0.45 ... hw * 0.45),
                y: CGFloat.random(in:  hh * 0.05 ... hh * 0.45)
            )
        case .morning:
            // Full screen, energetic scatter
            return CGPoint(
                x: CGFloat.random(in: -hw * 0.42 ... hw * 0.42),
                y: CGFloat.random(in: -hh * 0.42 ... hh * 0.42)
            )
        case .afternoon:
            // Lower two-thirds — heavy, pooling down
            return CGPoint(
                x: CGFloat.random(in: -hw * 0.45 ... hw * 0.45),
                y: CGFloat.random(in: -hh * 0.45 ... hh * 0.10)
            )
        case .dusk:
            // Edge-biased — coming loose at the margins
            if Bool.random() {
                let side: CGFloat = Bool.random() ? 1 : -1
                return CGPoint(
                    x: side * CGFloat.random(in: hw * 0.25 ... hw * 0.45),
                    y: CGFloat.random(in: -hh * 0.45 ... hh * 0.45)
                )
            } else {
                let side: CGFloat = Bool.random() ? 1 : -1
                return CGPoint(
                    x: CGFloat.random(in: -hw * 0.45 ... hw * 0.45),
                    y: side * CGFloat.random(in: hh * 0.25 ... hh * 0.45)
                )
            }
        case .evening:
            // Moderate, retreating inward
            return CGPoint(
                x: CGFloat.random(in: -hw * 0.30 ... hw * 0.30),
                y: CGFloat.random(in: -hh * 0.30 ... hh * 0.30)
            )
        }
    }
}
