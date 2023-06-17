import CoreData

final class MonthData: NSManagedObject, Identifiable {
    
    @NSManaged public var month: Month
    @NSManaged public var data: Data
    @NSManaged public var lastModifiedDate: Date
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<MonthData> {
        return NSFetchRequest<MonthData>(entityName: "MonthData")
    }
}
