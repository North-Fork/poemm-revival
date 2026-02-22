import SwiftUI
import SpriteKit

/// UIViewRepresentable that hosts the SKView + PoemScene.
/// The phase manager is passed in once at creation; all subsequent updates
/// flow through the Combine subscription inside PoemScene.
struct PoemSceneView: UIViewRepresentable {

    let phaseManager: TimePhaseManager

    func makeUIView(context: Context) -> SKView {
        let skView = SKView()
        skView.isMultipleTouchEnabled = true
        skView.ignoresSiblingOrder = true

        // Enable during development to monitor frame rate
        skView.showsFPS       = false
        skView.showsNodeCount = false

        let scene = PoemScene(size: UIScreen.main.bounds.size)
        scene.scaleMode = .aspectFill

        // Present scene first so didMove(to:) builds the word nodes,
        // then assign the manager so applyProperties has nodes to act on.
        skView.presentScene(scene)
        scene.phaseManager = phaseManager

        return skView
    }

    func updateUIView(_ uiView: SKView, context: Context) {
        // Phase updates are handled via Combine inside PoemScene — no action needed here.
    }
}
