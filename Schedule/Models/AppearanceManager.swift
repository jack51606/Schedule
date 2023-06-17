import UIKit

enum AppearanceOption: String, CaseIterable {
    
    case Auto, Light, Dark
    
    public var text: String {
        switch self {
        case .Auto:
            return Strings.auto
        case .Light:
            return Strings.light
        case .Dark:
            return Strings.dark
        }
    }
}

final class AppearanceManager {
    
    public static let shared = AppearanceManager()
    
    private init() {}
    
    private let defaults = UserDefaults.standard
    
    public var currentChoiceOfAppearance: AppearanceOption {
        
        let rawValue = defaults.string(forKey: Constants.UserDefaultsKeys.appearance) ?? AppearanceOption.Auto.rawValue
        return AppearanceOption(rawValue: rawValue)!
    }
    
    public var currentAppearance: UIUserInterfaceStyle {
        return UIUserInterfaceStyle(rawValue: AppearanceOption.allCases.firstIndex(of: currentChoiceOfAppearance)!)!
    }
    
    public func updateAppearance(to choice: AppearanceOption) {
        
        defaults.set(choice.rawValue, forKey: Constants.UserDefaultsKeys.appearance)
    }
}
