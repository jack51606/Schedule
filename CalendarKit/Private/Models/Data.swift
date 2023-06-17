final class Data: NSObject {

    // MARK: - Public Properties

    public let dictionary: [Int: [Item]]

    // MARK: - Public Methods

    public init(dictionary: [Int: [Item]]) {
        self.dictionary = dictionary
    }
}

extension Data: NSSecureCoding {
    
    static var supportsSecureCoding = true
    
    private enum Key: String {
        case dictionary
    }
    
    convenience init?(coder: NSCoder) {

        let dictionary = coder.decodeObject(of: [NSDictionary.self, NSNumber.self, NSArray.self, Item.self], forKey: Key.dictionary.rawValue) as! [Int: [Item]]
        
        self.init(dictionary: dictionary)
    }

    func encode(with coder: NSCoder) {
        coder.encode(dictionary, forKey: Key.dictionary.rawValue)
    }
}
