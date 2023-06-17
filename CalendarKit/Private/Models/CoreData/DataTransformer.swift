final class DataTransformer: NSSecureUnarchiveFromDataTransformer {
    
    override class var allowedTopLevelClasses: [AnyClass] {
        return [Data.self]
    }
    
    static func register() {
        let name = NSValueTransformerName(String(describing: DataTransformer.self))
        ValueTransformer.setValueTransformer(DataTransformer(), forName: name)
    }
}
