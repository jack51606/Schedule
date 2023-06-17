import UIKit

extension Locale {
    
    internal var isEnglish: Bool {
        return language.languageCode!.identifier == "en"
    }
    
    internal var isChinese: Bool {
        return language.languageCode!.identifier == "zh"
    }
}

extension UIFont {
    
    internal enum CustomFontRegisteringError: Error {
        case fileNotFound
        case failedToRegister
    }
    
    internal static func register(fileName: String, type: String) throws {
        
        let bundleIdentifier: String = "com.jack51606.Alatsi"
        let bundle = Bundle(identifier: bundleIdentifier)
        
        guard let url = bundle?.url(forResource: fileName, withExtension: type) else {
            throw CustomFontRegisteringError.fileNotFound
        }
        
        guard CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil) else {
            throw CustomFontRegisteringError.failedToRegister
        }
    }
}
