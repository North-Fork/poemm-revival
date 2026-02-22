import SwiftUI
import SpriteKit

struct ContentView: View {

    @StateObject private var phaseManager = TimePhaseManager(
        transitionWindowMinutes: AppProperties.shared.transitionWindowMinutes
    )

    // Scene is created once and held here.
    private let scene: PoemScene = {
        let s = PoemScene()
        s.scaleMode = .resizeFill   // SpriteKit updates scene.size to match the view
        return s
    }()

    var body: some View {
        SpriteView(scene: scene)
            .ignoresSafeArea()
            .onAppear {
                scene.phaseManager = phaseManager
            }
    }
}
