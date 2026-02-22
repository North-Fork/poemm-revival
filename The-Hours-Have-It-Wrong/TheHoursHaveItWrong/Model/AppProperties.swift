import UIKit

/// Reads CircadianProperties.plist and exposes device-appropriate font settings
/// and the transition window duration.
struct AppProperties {
    let fontName: String
    let fontSize: CGFloat
    let transitionWindowMinutes: Double

    static let shared: AppProperties = {
        guard
            let url  = Bundle.main.url(forResource: "CircadianProperties", withExtension: "plist"),
            let dict = NSDictionary(contentsOf: url) as? [String: Any]
        else {
            return AppProperties(fontName: "GillSans-Bold", fontSize: 26, transitionWindowMinutes: 30)
        }

        let fontName              = dict["FontName"] as? String ?? "GillSans-Bold"
        let transitionWindow      = dict["TransitionWindowMinutes"] as? Double ?? 30.0
        let isIPad                = UIDevice.current.userInterfaceIdiom == .pad
        let deviceKey             = isIPad ? "Properties-iPad" : "Properties-iPhone"
        let deviceDict            = dict[deviceKey] as? [String: Any]
        let fontSize              = CGFloat(deviceDict?["FontSize"] as? Int ?? 26)

        return AppProperties(fontName: fontName, fontSize: fontSize, transitionWindowMinutes: transitionWindow)
    }()
}
