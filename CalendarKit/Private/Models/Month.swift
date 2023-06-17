final class Month: NSObject, Comparable {
    
    // MARK: - Public Properties
    
    public let month: Int
    public let year: Int
    
    public var isCurrentMonth: Bool {
        return self == Date().month
    }
    public var previousMonth: Month? {
        if month != 1 {
            return Month(month - 1, year)
        } else {
            return Month(12, year - 1)
        }
    }
    public var nextMonth: Month? {
        if month != 12 {
            return Month(month + 1, year)
        } else {
            return Month(1, year + 1)
        }
    }
    public var numberOfDays: Int {
        
        let range = calendar.range(of: .day, in: .month, for: startOfFirstDay)!
        return range.count
    }
    public var numberOfWeeks: Int {
        
        let range = calendar.range(of: .weekOfMonth, in: .month, for: startOfFirstDay)!
        return range.count
    }
    public var weekdayOfFirstDay: Int {
        
        return calendar.component(.weekday, from: startOfFirstDay)
    }
    public var startOfFirstDay: Date {
        
        var components = DateComponents()
        components.calendar = calendar
        components.year = year
        components.month = month
        
        return calendar.startOfDay(for: components.date!)
    }
    public var endOfLastDay: Date {
        
        var components = DateComponents()
        components.calendar = calendar
        components.year = year
        components.month = month
        components.day = numberOfDays
        components.hour = 23
        components.minute = 59
        components.second = 59
        
        return components.date!
    }
    
    // MARK: - Override Properties
    
    override var description: String {
        return "(\(month), \(year))"
    }
    
    // MARK: - Private Properties
    
    private var calendar: Calendar {
        return CalendarPreferenceManager.shared.calendar
    }
    
    // MARK: - Public Methods
    
    public init?(_ month: Int, _ year: Int) {
        guard month > 0, month <= 12, year > 1900, year <= 4000 else { return nil }
        
        self.month = month
        self.year = year
    }
    
    public override func isEqual(_ object: Any?) -> Bool {
        if let month = object as? Month {
            return month.month == self.month && month.year == self.year
        } else {
            return super.isEqual(object)
        }
    }
    
    public static func < (lhs: Month, rhs: Month) -> Bool {
        if lhs.year != rhs.year {
            return lhs.year < rhs.year
        } else {
            return lhs.month < rhs.month
        }
    }
}

extension Month: NSSecureCoding {
    
    static var supportsSecureCoding = true
    
    private enum Key: String {
        case month
        case year
    }
    
    convenience init?(coder: NSCoder) {
        
        let month = coder.decodeInteger(forKey: Key.month.rawValue)
        let year = coder.decodeInteger(forKey: Key.year.rawValue)
        
        self.init(month, year)
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(month, forKey: Key.month.rawValue)
        coder.encode(year, forKey: Key.year.rawValue)
    }
}
