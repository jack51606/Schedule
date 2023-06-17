import UIKit
import RegexBuilder

extension Locale {
    
    public var isEnglish: Bool {
        return language.languageCode!.identifier == "en"
    }
    
    public var isChinese: Bool {
        return language.languageCode!.identifier == "zh"
    }
}

extension UIColor {
    
    public convenience init?(hex: String) {
        
        let regex = Regex {
            Anchor.startOfSubject
            "#"
            Repeat(count: 6) {
                CharacterClass(
                    ("A"..."F"),
                    ("a"..."f"),
                    ("0"..."9")
                )
            }
            Anchor.endOfSubject
        }
        guard hex == hex.firstMatch(of: regex)?.base else { return nil }
        
        var hexString = hex.uppercased()
        hexString.remove(at: hexString.startIndex)
        
        var value: UInt64 = 0
        Scanner(string: hexString).scanHexInt64(&value)
        
        let r, g, b: CGFloat
        r = CGFloat((value & 0xFF0000) >> 16) / 255.0
        g = CGFloat((value & 0x00FF00) >> 8) / 255.0
        b = CGFloat(value & 0x0000FF) / 255.0
        
        self.init(red: r, green: g, blue: b, alpha: 1)
        
        return
    }
    
    public var hex: String? {
        guard let components = cgColor.components else { return nil }
        
        let red: CGFloat = components[0]
        let green: CGFloat = components[1]
        let blue: CGFloat = components[2]
        
        let r = Int(red * 255.0)
        let g = Int(green * 255.0)
        let b = Int(blue * 255.0)
        
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}

extension UIFont {
    
    class func rounded(ofSize size: CGFloat, weight: UIFont.Weight = .regular) -> UIFont {
        
        let systemFont = UIFont.systemFont(ofSize: size, weight: weight)
        
        let font: UIFont
        if let descriptor = systemFont.fontDescriptor.withDesign(.rounded) {
            font = UIFont(descriptor: descriptor, size: size)
        } else {
            font = systemFont
        }
        
        return font
    }
}
