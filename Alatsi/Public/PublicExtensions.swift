import UIKit

public extension UIFont {
    
    static func alatsi(ofSize size: CGFloat) -> UIFont {
        
        if UIFont(name: "Alatsi-Regular", size: size) == nil {
            do {
                try register(fileName: "Alatsi-Regular", type: "ttf")
            }
            catch {
                print("🔸", error)
            }
        }
        
        var font = UIFont()
        if let alatsi = UIFont(name: "Alatsi-Regular", size: size) {
            let discriptor = alatsi.fontDescriptor.addingAttributes([.cascadeList: [boldSystemFont(ofSize: size).fontDescriptor]])
            font = UIFont(descriptor: discriptor, size: size)
        } else {
            font = UIFont.boldSystemFont(ofSize: size)
        }
        
        return Locale.autoupdatingCurrent.isEnglish ? font : UIFont.boldSystemFont(ofSize: size)
    }
    
    static let regularTitle = alatsi(ofSize: 28)
    static let navigationBarButton = alatsi(ofSize: 22)
    
    static func showAllFonts() {
        familyNames.forEach {
            fontNames(forFamilyName: $0).forEach {
                print("🔸", $0)
            }
        }
    }
}
