import UIKit

enum ThemeColorOption: String, CaseIterable {
    
    case Blue, Green, Orange, Purple, Pink
    
    public var text: String {
        switch self {
        case .Blue:
            return Strings.blue
        case .Green:
            return Strings.green
        case .Orange:
            return Strings.orange
        case .Purple:
            return Strings.purple
        case .Pink:
            return Strings.pink
        }
    }
}

final class ThemeColorManager {
    
    public static let shared = ThemeColorManager()
    
    private init() {}
    
    private let defaults = UserDefaults.standard
    
    public var currentChoiceOfThemeColor: ThemeColorOption {
        
        let rawValue = defaults.string(forKey: Constants.UserDefaultsKeys.themeColor) ?? ThemeColorOption.Blue.rawValue
        return ThemeColorOption(rawValue: rawValue)!
    }
    
    public var currentThemeColor: UIColor {
        
        switch currentChoiceOfThemeColor {
        case .Blue:
            return UIColor(hex: "#789DE5")!
        case .Green:
            return UIColor(hex: "#83B869")!
        case .Orange:
            return UIColor(hex: "#E6954B")!
        case .Purple:
            return UIColor(hex: "#9F8FD9")!
        case .Pink:
            return UIColor(hex: "#E68280")!
        }
    }
    
    public func updateThemeColor(to choice: ThemeColorOption) {
        
        defaults.set(choice.rawValue, forKey: Constants.UserDefaultsKeys.themeColor)
    }
}
