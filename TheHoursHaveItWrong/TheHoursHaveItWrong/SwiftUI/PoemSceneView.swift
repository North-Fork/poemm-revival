import SwiftUI
import SpriteKit

/// UIViewRepresentable that hosts the SKView + PoemScene.
/// Accepts an explicit `size` from a GeometryReader so the scene is always
/// created with the correct laid-out dimensions — not UIScreen.main.bounds,
/// which can be unreliable in Xcode 16 / iOS 18 simulator setups.
struct PoemSceneView: UIViewRepresentable {

    let phaseManager: TimePhaseManager
    let size: CGSize

    func makeUIView(context: Context) -> SKView {
        let skView = SKView(frame: CGRect(origin: .zero, size: size))
        skView.isMultipleTouchEnabled = true
        skView.ignoresSiblingOrder = true
        skView.showsFPS       = false
        skView.showsNodeCount = false

        let scene = PoemScene(size: size)
        scene.scaleMode = .aspectFill

        skView.presentScene(scene)
        scene.phaseManager = phaseManager

        return skView
    }

    func updateUIView(_ uiView: SKView, context: Context) {
        // Phase updates flow through Combine inside PoemScene.
    }
}
