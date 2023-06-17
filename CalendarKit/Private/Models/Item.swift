import UIKit

enum ItemType: Int {
    case event, reminder
}

final class Item: NSObject {
    
    // MARK: - Public Properties
    
    public var type: ItemType {
        return ItemType(rawValue: typeRawValue)!
    }
    public let color: UIColor
    
    // MARK: - Private Properties
    
    private let typeRawValue: Int
    
    // MARK: - Public Methods
    
    public init(type: ItemType, color: UIColor) {
        self.typeRawValue = type.rawValue
        self.color = color
    }
}

extension Item: NSSecureCoding {
    
    static var supportsSecureCoding = true
    
    private enum Key: String {
        case typeRawValue
        case color
    }
    
    convenience init?(coder: NSCoder) {

        let typeRawValue = coder.decodeInteger(forKey: Key.typeRawValue.rawValue)
        let color = coder.decodeObject(of: UIColor.self, forKey: Key.color.rawValue)!

        self.init(type: ItemType(rawValue: typeRawValue)!, color: color)
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(typeRawValue, forKey: Key.typeRawValue.rawValue)
        coder.encode(color, forKey: Key.color.rawValue)
    }
}
