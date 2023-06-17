import UIKit

public enum FirstWeekdayOption: String, CaseIterable {
    
    case SystemSetting
    case Sunday
    case Monday
    case Tuesday
    case Wednesday
    case Thursday
    case Friday
    case Saturday
    
    public var text: String {
        switch self {
        case .SystemSetting:
            return Strings.FirstWeekday.systemSetting
        case .Sunday:
            return Strings.FirstWeekday.Sunday
        case .Monday:
            return Strings.FirstWeekday.Monday
        case .Tuesday:
            return Strings.FirstWeekday.Tuesday
        case .Wednesday:
            return Strings.FirstWeekday.Wednesday
        case .Thursday:
            return Strings.FirstWeekday.Thursday
        case .Friday:
            return Strings.FirstWeekday.Friday
        case .Saturday:
            return Strings.FirstWeekday.Saturday
        }
    }
}

public enum ShowRemindersOption: String, CaseIterable {
    
    case IncompleteOnly
    case HideAll
    case ShowAll
    
    public var text: String {
        switch self {
        case .IncompleteOnly:
            return Strings.ShowReminders.incompleteOnly
        case .HideAll:
            return Strings.ShowReminders.hideAll
        case .ShowAll:
            return Strings.ShowReminders.showAll
        }
    }
}

public final class CalendarPreferenceManager {
    
    // MARK: - Public Properties
    
    public static let shared = CalendarPreferenceManager()
    
    public var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale.current
        calendar.firstWeekday = currentFirstWeekday
        return calendar
    }
    
    // MARK: - Private Properties
    
    private let defaults = UserDefaults.standard
    
    // MARK: - Public Methods
    
    public var currentChoiceOfFirstWeekday: FirstWeekdayOption {
        
        let rawValue = defaults.string(forKey: Constants.UserDefaultsKeys.firstWeekday) ?? FirstWeekdayOption.SystemSetting.rawValue
        return FirstWeekdayOption(rawValue: rawValue)!
    }
    
    public var currentFirstWeekday: Int {
        
        let weekday = FirstWeekdayOption.allCases.firstIndex(of: currentChoiceOfFirstWeekday)!
        return weekday != 0 ? weekday : Calendar.current.firstWeekday
    }
    
    public func updateFirstWeekday(to choice: FirstWeekdayOption) {
        
        defaults.set(choice.rawValue, forKey: Constants.UserDefaultsKeys.firstWeekday)
    }
    
    public var currentChoiceOfShowingRemindersInCalendarView: ShowRemindersOption {
        
        let rawValue = defaults.string(forKey: Constants.UserDefaultsKeys.showRemindersInCalendarView) ?? ShowRemindersOption.IncompleteOnly.rawValue
        return ShowRemindersOption(rawValue: rawValue)!
    }
    
    public func updateChoiceOfShowingRemindersInCalendarView(to choice: ShowRemindersOption) {
        
        defaults.set(choice.rawValue, forKey: Constants.UserDefaultsKeys.showRemindersInCalendarView)
    }
    
    public var currentChoiceOfShowingRemindersInSingleDayItemsView: ShowRemindersOption {
        
        let rawValue = defaults.string(forKey: Constants.UserDefaultsKeys.showRemindersInSingleDayItemsView) ?? ShowRemindersOption.IncompleteOnly.rawValue
        return ShowRemindersOption(rawValue: rawValue)!
    }
    
    public func updateChoiceOfShowingRemindersInSingleDayItemsView(to choice: ShowRemindersOption) {
        
        defaults.set(choice.rawValue, forKey: Constants.UserDefaultsKeys.showRemindersInSingleDayItemsView)
    }
    
    // MARK: - Private Methods
    
    private init() {}
}
