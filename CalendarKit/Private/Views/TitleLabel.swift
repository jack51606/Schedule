import UIKit

internal class TitleLabel: PaddingLabel {
    
    public var isTruncated: Bool {
        guard let font, let text else { return false }
        
        let width = (text as NSString).size(withAttributes: [.font: font]).width
        
        return width > bounds.size.width && numberOfLines == 1
    }
}
