import SpriteKit
import UIKit

/// Full-screen gradient background.
/// Rebuilds its SKTexture only when interpolated colors drift beyond a 0.5 % threshold —
/// at most once per 30-second timer tick, never every frame.
final class BackgroundNode: SKSpriteNode {

    private var lastTop:    UIColor = .black
    private var lastBottom: UIColor = .black
    private let threshold:  CGFloat = 0.005

    init(size: CGSize) {
        let tex = BackgroundNode.gradient(size: size, top: .black, bottom: .black)
        super.init(texture: tex, color: .clear, size: size)
        position  = .zero
        zPosition = -100
    }

    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) not implemented") }

    // MARK: - Conditional Update

    func updateIfNeeded(topColor: UIColor, bottomColor: UIColor, size: CGSize) {
        guard changed(lastTop, topColor) || changed(lastBottom, bottomColor) else { return }
        lastTop    = topColor
        lastBottom = bottomColor
        texture    = BackgroundNode.gradient(size: size, top: topColor, bottom: bottomColor)
        self.size  = size
    }

    // MARK: - Gradient Texture

    /// UIKit y=0 is at the top of the image; SpriteKit displays it at the top of the sprite.
    private static func gradient(size: CGSize, top: UIColor, bottom: UIColor) -> SKTexture {
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { ctx in
            let cgCtx = ctx.cgContext
            let space = CGColorSpaceCreateDeviceRGB()
            let colors = [top.cgColor, bottom.cgColor] as CFArray
            let stops: [CGFloat] = [0, 1]
            guard let grad = CGGradient(colorsSpace: space, colors: colors, locations: stops) else { return }
            cgCtx.drawLinearGradient(
                grad,
                start: CGPoint(x: size.width / 2, y: 0),
                end:   CGPoint(x: size.width / 2, y: size.height),
                options: []
            )
        }
        return SKTexture(image: image)
    }

    // MARK: - Color Delta

    private func changed(_ a: UIColor, _ b: UIColor) -> Bool {
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        a.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        b.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        return abs(r1-r2) > threshold || abs(g1-g2) > threshold || abs(b1-b2) > threshold
    }
}
