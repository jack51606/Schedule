struct Strings {
    
    static let noEvents = String(localized: "No Events") // 沒有行程
    static let allDay = String(localized: "all-day") // 整日
    
    struct FirstWeekday {
        static let systemSetting = String(localized: "System Setting") // 系統設定
        static let Sunday = Calendar.current.weekdaySymbols[0]
        static let Monday = Calendar.current.weekdaySymbols[1]
        static let Tuesday = Calendar.current.weekdaySymbols[2]
        static let Wednesday = Calendar.current.weekdaySymbols[3]
        static let Thursday = Calendar.current.weekdaySymbols[4]
        static let Friday = Calendar.current.weekdaySymbols[5]
        static let Saturday = Calendar.current.weekdaySymbols[6]
    }
    
    struct ShowReminders {
        static let incompleteOnly = String(localized: "Incomplete Only") // 僅未完成
        static let hideAll = String(localized: "Hide All") // 全部隱藏
        static let showAll = String(localized: "Show All") // 全部顯示
    }
}
