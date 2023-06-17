final class MonthTransformer: NSSecureUnarchiveFromDataTransformer {
    
    override class var allowedTopLevelClasses: [AnyClass] {
        return [Month.self]
    }
    
    static func register() {
        let name = NSValueTransformerName(String(describing: MonthTransformer.self))
        ValueTransformer.setValueTransformer(MonthTransformer(), forName: name)
    }
}
