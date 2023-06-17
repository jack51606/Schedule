import UIKit

public struct Constants {
    
    public struct UserDefaultsKeys {
        public static let authorizationStatusForEvent = "Authorization Status For Event"
        public static let authorizationStatusForReminder = "Authorization Status For Reminder"
        public static let firstWeekday = "First Weekday"
        public static let showRemindersInCalendarView = "Show Reminders In Calendar View"
        public static let showRemindersInSingleDayItemsView = "Show Reminders In Single Day Items View"
        public static let eventCalendars = "Event Calendars"
        public static let reminderLists = "Reminder Lists"
        public static let defaultEventCalendar = "Default Event Calendar"
        public static let defaultReminderList = "Default Reminder List"
    }
    
    struct SFSymbols {
        
        static let circleFill = UIImage(systemName: "circle.fill")!
        static let checkmark = UIImage(systemName: "checkmark")!
        static let ellipsis = UIImage(systemName: "ellipsis")!
        static let square = UIImage(systemName: "square")!
        static let checkmarkSquare = UIImage(systemName: "checkmark.square")!
        static let exclamationmark = UIImage(systemName: "exclamationmark")!
        static let exclamationmark2 = UIImage(systemName: "exclamationmark.2")!
        static let exclamationmark3 = UIImage(systemName: "exclamationmark.3")!
        static let chevronUp = UIImage(systemName: "chevron.up")!
        static let chevronDown = UIImage(systemName: "chevron.down")!
        static let cycle = UIImage(systemName: "arrow.triangle.2.circlepath")!
    }
}
