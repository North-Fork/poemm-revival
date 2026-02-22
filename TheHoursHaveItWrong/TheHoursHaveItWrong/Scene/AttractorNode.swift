import SpriteKit

/// An invisible marker node placed at each active touch location.
/// Words query the positions of all live AttractorNodes each frame in WordNode.update().
/// Keyed by ObjectIdentifier(touch) in PoemScene.activeAttractors — mirrors the
/// NSMutableDictionary *ctrlPts pattern from the original Objective-C PoEMM apps.
final class AttractorNode: SKNode {
    // All behavior is in WordNode.update() — this node is position only.
}
