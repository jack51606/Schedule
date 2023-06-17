import UIKit
import EventKit

public enum RemindersFetchingOption {
    case All, IncompleteOnly
}

public final class CalendarItemsManager {
    
    // MARK: - Public Properties
    
    public static let shared = CalendarItemsManager()
    public private (set) var allEvents: [EKEvent] = []
    public private (set) var allReminders: [EKReminder] = []
    
    // MARK: - Private Properties
    
    private let defaults = UserDefaults.standard
    private var calendar: Calendar {
        return CalendarPreferenceManager.shared.calendar
    }
    private let eventStore = EKEventStore()
    
    // MARK: - Public Methods
    
    public func requestAuthorization() async {
        
        let eventsAuthorizationStatus = EKEventStore.authorizationStatus(for: .event)
        let remindersAuthorizationStatus = EKEventStore.authorizationStatus(for: .reminder)
        
        if eventsAuthorizationStatus == .notDetermined || remindersAuthorizationStatus == .notDetermined {
            
            do {
                try await eventStore.requestAccess(to: .event)
                try await eventStore.requestAccess(to: .reminder)
            }
            catch {
                print("🔸", error)
            }
        }
    }
    
    public func saveEventStoreAuthorizationStatuses() {
        
        let newValue1 = EKEventStore.authorizationStatus(for: .event).rawValue
        let newValue2 = EKEventStore.authorizationStatus(for: .reminder).rawValue
        
        defaults.set(newValue1, forKey: Constants.UserDefaultsKeys.authorizationStatusForEvent)
        defaults.set(newValue2, forKey: Constants.UserDefaultsKeys.authorizationStatusForReminder)
    }
    
    // 檢查權限有沒有更動過
    public var eventStoreAuthorizationStatusesUpdated: Bool {
        
        let rawValue1 = defaults.object(forKey: Constants.UserDefaultsKeys.authorizationStatusForEvent) as? Int ?? 0
        let rawValue2 = defaults.object(forKey: Constants.UserDefaultsKeys.authorizationStatusForReminder) as? Int ?? 0
        
        let newValue1 = EKEventStore.authorizationStatus(for: .event).rawValue
        let newValue2 = EKEventStore.authorizationStatus(for: .reminder).rawValue
        let updated = newValue1 != rawValue1 || newValue2 != rawValue2
        
        return updated
    }
    
    public func refreshEventStoreSourcesIfNecessary() {
        
        eventStore.refreshSourcesIfNecessary()
    }
    
    public func newEventCalendar() -> EKCalendar? {
        
        var source: EKSource? {
            for source in eventStore.sources {
                if source.sourceType == .calDAV && source.title == "iCloud" {
                    return source
                }
            }
            for source in eventStore.sources {
                if source.sourceType == .local {
                    return source
                }
            }
            return nil
        }
        
        guard let source else { return nil }
        
        let calendar = EKCalendar(for: .event, eventStore: eventStore)
        calendar.source = source
        print("🔸", "成功新增行事曆")
        return calendar
    }
    
    public func newReminderList() -> EKCalendar? {
        
        var source: EKSource? {
            if let source = eventStore.defaultCalendarForNewReminders()?.source {
                return source
            }
            for source in eventStore.sources {
                if source.sourceType == .calDAV && source.title == "iCloud" {
                    return source
                }
            }
            for source in eventStore.sources {
                if source.sourceType == .local {
                    return source
                }
            }
            return nil
        }
        
        guard let source else { return nil }
        
        let list = EKCalendar(for: .reminder, eventStore: eventStore)
        list.source = source
        print("🔸", "成功新增清單")
        return list
    }
    
    public func saveEventCalendar(_ calendar: EKCalendar) {
        
        do {
            let addToCurrentVisibleCalendars = calendar.isNew
            try eventStore.saveCalendar(calendar, commit: true)
            
            guard addToCurrentVisibleCalendars else { return }
            
            addVisibleEventCalendar(calendar)
            
            let calendars = eventStore.calendars(for: .event).filter({ $0.allowsContentModifications })
            if calendars.count == 1 && calendars.first! == calendar {
                defaults.set(calendar.calendarIdentifier, forKey: Constants.UserDefaultsKeys.defaultEventCalendar)
            }
            print("🔸", "成功儲存行事曆")
        }
        catch {
            print("🔸", "Failed to save event calendar: ", error)
        }
    }
    
    public func saveReminderList(_ list: EKCalendar) {
        
        do {
            let addToVisibleLists = list.isNew
            try eventStore.saveCalendar(list, commit: true)
            
            guard addToVisibleLists else { return }
            
            addVisibleReminderList(list)
            
            let lists = eventStore.calendars(for: .reminder).filter({ $0.allowsContentModifications })
            if lists.count == 1 && lists.first! == list {
                defaults.set(list.calendarIdentifier, forKey: Constants.UserDefaultsKeys.defaultReminderList)
            }
            print("🔸", "成功儲存清單")
        }
        catch {
            print("🔸", "Failed to save reminder list: ", error)
        }
    }
    
    public func deleteEventCalendar(_ calendar: EKCalendar) {
        
        do {
            let removeDefaultEventCalendar = calendar == defaultEventCalendar
            try eventStore.removeCalendar(calendar, commit: true)
            if removeDefaultEventCalendar {
                defaults.set(nil, forKey: Constants.UserDefaultsKeys.defaultEventCalendar)
            }
            print("🔸", "成功刪除行事曆")
        }
        catch {
            print("🔸", "Failed to remove event calendar: ", error)
        }
    }
    
    public func deleteReminderList(_ list: EKCalendar) {
        
        do {
            let removeDefaultReminderList = list == defaultReminderList
            try eventStore.removeCalendar(list, commit: true)
            if removeDefaultReminderList {
                defaults.set(nil, forKey: Constants.UserDefaultsKeys.defaultReminderList)
            }
            print("🔸", "成功刪除清單")
        }
        catch {
            print("🔸", "Failed to remove reminder list: ", error)
        }
    }
    
    public var defaultEventCalendar: EKCalendar? {
        
        let identifier = defaults.string(forKey: Constants.UserDefaultsKeys.defaultEventCalendar)
        
        if let identifier, let calendar = eventStore.calendar(withIdentifier: identifier) {
            return calendar
        } else {
            let calendars = eventStore.calendars(for: .event).filter { $0.allowsContentModifications }
            if !calendars.isEmpty {
                let calendar = calendars.first!
                defaults.set(calendar.calendarIdentifier, forKey: Constants.UserDefaultsKeys.defaultEventCalendar)
                return calendar
            } else {
                defaults.set(nil, forKey: Constants.UserDefaultsKeys.defaultEventCalendar)
                return nil
            }
        }
    }
    
    public func updateDefaultEventCalendar(to calendar: EKCalendar) {
        guard eventStore.calendars(for: .event).contains(calendar) else { return }
        guard calendar.allowsContentModifications else { return }
        
        defaults.set(calendar.calendarIdentifier, forKey: Constants.UserDefaultsKeys.defaultEventCalendar)
    }
    
    public var defaultReminderList: EKCalendar? {
        
        let identifier = defaults.string(forKey: Constants.UserDefaultsKeys.defaultReminderList)
        
        if let identifier, let list = eventStore.calendar(withIdentifier: identifier) {
            return list
        } else {
            let lists = eventStore.calendars(for: .reminder)
            if !lists.isEmpty {
                let list = lists.first!
                defaults.set(list.calendarIdentifier, forKey: Constants.UserDefaultsKeys.defaultReminderList)
                return list
            } else {
                defaults.set(nil, forKey: Constants.UserDefaultsKeys.defaultReminderList)
                return nil
            }
        }
    }
    
    public func updateDefaultReminderList(to list: EKCalendar) {
        guard eventStore.calendars(for: .reminder).contains(list) else { return }
        guard list.allowsContentModifications else { return }
        
        defaults.set(list.calendarIdentifier, forKey: Constants.UserDefaultsKeys.defaultReminderList)
    }
    
    public var currentVisibleEventCalendarIdentifiers: [String] {
        
        let allEventCalendars = eventStore.calendars(for: .event)
        var allEventCalendarIdentifiers: [String] {
            var identifiers = [String]()
            for calendar in allEventCalendars {
                identifiers.append(calendar.calendarIdentifier)
            }
            return identifiers
        }
        
        var currentVisibleEventCalendarIdentifiers = defaults.stringArray(forKey: Constants.UserDefaultsKeys.eventCalendars) ?? allEventCalendarIdentifiers
        currentVisibleEventCalendarIdentifiers.removeAll(where: { !allEventCalendarIdentifiers.contains($0) })
        defaults.set(currentVisibleEventCalendarIdentifiers, forKey: Constants.UserDefaultsKeys.eventCalendars)
        
        return currentVisibleEventCalendarIdentifiers
    }
    
    public var currentVisibleEventCalendars: [EKCalendar] {
        
        var calendars = eventStore.calendars(for: .event).filter {
            currentVisibleEventCalendarIdentifiers.contains($0.calendarIdentifier)
        }
        calendars.sort { calendar1, calendar2 in
            let index1 = currentVisibleEventCalendarIdentifiers.firstIndex(of: calendar1.calendarIdentifier)!
            let index2 = currentVisibleEventCalendarIdentifiers.firstIndex(of: calendar2.calendarIdentifier)!
            return index1 < index2
        }
        
        return calendars
    }
    
    public var currentInvisibleEventCalendars: [EKCalendar] {
        
        let calendars = eventStore.calendars(for: .event).filter {
            !currentVisibleEventCalendarIdentifiers.contains($0.calendarIdentifier)
        }
        
        return calendars
    }
    
    public func reorderCurrentVisibleEventCalendars(to calendars: [EKCalendar]) {
        guard Set(calendars) == Set(currentVisibleEventCalendars) else { return }
        
        let newValue = calendars.map { $0.calendarIdentifier }
        
        defaults.set(newValue, forKey: Constants.UserDefaultsKeys.eventCalendars)
    }
    
    public func addVisibleEventCalendar(_ calendar: EKCalendar, at index: Int? = nil) {
        guard !currentVisibleEventCalendars.contains(calendar) else { return }
        
        var newValue = currentVisibleEventCalendarIdentifiers
        
        if let index, index <= currentVisibleEventCalendars.count {
            newValue.insert(calendar.calendarIdentifier, at: index)
        } else {
            newValue.append(calendar.calendarIdentifier)
        }
        
        defaults.set(newValue, forKey: Constants.UserDefaultsKeys.eventCalendars)
    }
    
    public func removeVisibleEventCalendar(_ calendar: EKCalendar) {
        var newValue = currentVisibleEventCalendarIdentifiers
        newValue.removeAll(where: { $0 == calendar.calendarIdentifier })
        defaults.set(newValue, forKey: Constants.UserDefaultsKeys.eventCalendars)
    }
    
    public var currentVisibleReminderListIdentifiers: [String] {
        
        let allReminderLists = eventStore.calendars(for: .reminder)
        var allReminderListIdentifiers: [String] {
            var identifiers = [String]()
            for calendar in allReminderLists {
                identifiers.append(calendar.calendarIdentifier)
            }
            return identifiers
        }
        
        var currentVisibleReminderListIdentifiers = defaults.stringArray(forKey: Constants.UserDefaultsKeys.reminderLists) ?? allReminderListIdentifiers
        currentVisibleReminderListIdentifiers.removeAll(where: { !allReminderListIdentifiers.contains($0) })
        defaults.set(currentVisibleReminderListIdentifiers, forKey: Constants.UserDefaultsKeys.reminderLists)
        
        return currentVisibleReminderListIdentifiers
    }
    
    public var currentVisibleReminderLists: [EKCalendar] {
        
        var lists = eventStore.calendars(for: .reminder).filter {
            currentVisibleReminderListIdentifiers.contains($0.calendarIdentifier)
        }
        lists.sort { list1, list2 in
            let index1 = currentVisibleReminderListIdentifiers.firstIndex(of: list1.calendarIdentifier)!
            let index2 = currentVisibleReminderListIdentifiers.firstIndex(of: list2.calendarIdentifier)!
            return index1 < index2
        }
        
        return lists
    }
    
    public var currentInvisibleReminderLists: [EKCalendar] {
        
        let lists = eventStore.calendars(for: .reminder).filter {
            !currentVisibleReminderListIdentifiers.contains($0.calendarIdentifier)
        }
        
        return lists
    }
    
    public func reorderCurrentVisibleReminderLists(to lists: [EKCalendar]) {
        guard Set(lists) == Set(currentVisibleReminderLists) else { return }
        
        let newValue = lists.map { $0.calendarIdentifier }
        
        defaults.set(newValue, forKey: Constants.UserDefaultsKeys.reminderLists)
    }
    
    public func addVisibleReminderList(_ list: EKCalendar, at index: Int? = nil) {
        guard !currentVisibleReminderLists.contains(list) else { return }
        
        var newValue = currentVisibleReminderListIdentifiers
        
        if let index, index <= currentVisibleReminderLists.count {
            newValue.insert(list.calendarIdentifier, at: index)
        } else {
            newValue.append(list.calendarIdentifier)
        }
        
        defaults.set(newValue, forKey: Constants.UserDefaultsKeys.reminderLists)
    }
    
    public func removeVisibleReminderList(_ list: EKCalendar) {
        var newValue = currentVisibleReminderListIdentifiers
        newValue.removeAll(where: { $0 == list.calendarIdentifier })
        defaults.set(newValue, forKey: Constants.UserDefaultsKeys.reminderLists)
    }
    
    public func newEvent() -> EKEvent? {
        guard let defaultEventCalendar else { return nil }
        
        let event = EKEvent(eventStore: eventStore)
        event.calendar = defaultEventCalendar
        
        return event
    }
    
    public func newReminder() -> EKReminder? {
        guard let defaultReminderList else { return nil }
        
        let reminder = EKReminder(eventStore: eventStore)
        reminder.calendar = defaultReminderList
        
        return reminder
    }
    
    public func save(_ event: EKEvent, span: EKSpan) {
        
        do {
            try eventStore.save(event, span: span, commit: true)
            print("🔸", "成功儲存行程")
        }
        catch {
            print("🔸", "Failed to save event: ", error)
        }
    }
    
    public func save(_ reminder: EKReminder) {
        
        do {
            try eventStore.save(reminder, commit: true)
            print("🔸", "成功儲存提醒事項")
        }
        catch {
            print("🔸", "Failed to save reminder: ", error)
        }
    }
    
    public func delete(_ event: EKEvent, span: EKSpan = .thisEvent) {
        
        do {
            try eventStore.remove(event, span: span, commit: true)
            print("🔸", "成功刪除行程")
        }
        catch {
            print("🔸", "Failed to remove event: ", error)
        }
    }
    
    public func delete(_ reminder: EKReminder) {
        
        do {
            try eventStore.remove(reminder, commit: true)
            print("🔸", "成功刪除提醒事項")
        }
        catch {
            print("🔸", "Failed to remove reminder: ", error)
        }
    }
    
    public func fetchAllCalendarItems(completion: @escaping () -> Void = {}) {
        
        DispatchQueue.global(qos: .default).async { [weak self] in
            guard let self else { return }
            
            Task {
                self.fetchAllEvents()
                await self.fetchAllReminders()
                
                completion()
            }
        }
    }
    
    public func events(from startDate: Date, to endDate: Date) -> [EKEvent] {
        guard EKEventStore.authorizationStatus(for: .event) == .authorized else { return [] }
        guard startDate <= endDate else { return [] }
        guard !currentVisibleEventCalendars.isEmpty else { return [] }
        
        let startDate = calendar.startOfDay(for: startDate), endDate = calendar.endOfDay(for: endDate)
        let predicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: currentVisibleEventCalendars)
        let events = eventStore.events(matching: predicate)
        
        return events
    }
    
    public func reminders(from startDate: Date, to endDate: Date, option: RemindersFetchingOption) async -> [EKReminder] {
        guard EKEventStore.authorizationStatus(for: .reminder) == .authorized else { return [] }
        guard startDate <= endDate else { return [] }
        guard !currentVisibleReminderLists.isEmpty else { return [] }
        
        let startDate = calendar.startOfDay(for: startDate), endDate = calendar.endOfDay(for: endDate)
        
        switch option {
        case .All:
            
            let predicate = eventStore.predicateForReminders(in: currentVisibleReminderLists)
            
            return await withCheckedContinuation { continuation in
                
                eventStore.fetchReminders(matching: predicate) { reminders in
                    
                    if var reminders {
                        
                        reminders = reminders.filter {
                            guard let dueDate = $0.dueDateComponents?.date else { return false }
                            
                            return (startDate...endDate).contains(dueDate)
                        }
                        
                        continuation.resume(returning: reminders)
                        
                    } else {
                        continuation.resume(returning: [])
                    }
                }
            }
            
        case .IncompleteOnly:
            
            let startDate = calendar.date(byAdding: .second, value: -1, to: calendar.startOfDay(for: startDate)) // 前一天的 23:59:59
            let predicate = eventStore.predicateForIncompleteReminders(withDueDateStarting: startDate, ending: endDate, calendars: currentVisibleReminderLists)
            
            return await withCheckedContinuation { continuation in
                
                eventStore.fetchReminders(matching: predicate) { reminders in
                    
                    if var reminders {
                        
                        reminders = reminders.filter {
                            return $0.dueDateComponents?.date != nil
                        }
                        
                        continuation.resume(returning: reminders)
                        
                    } else {
                        continuation.resume(returning: [])
                    }
                }
            }
        }
    }
    
    public func singleDayCalendarItemsSortComparator(date: Date) -> (EKCalendarItem, EKCalendarItem) -> Bool {
        return { [weak self] item1, item2 in
            guard let self else { return true }
            
            let calendar = self.calendar
            
            var isEvent1: Bool = true, isEvent2: Bool = true
            var isAllDay1: Bool = false, isAllDay2: Bool = false
            var startDate1: Date!, startDate2: Date!
            
            if item1 is EKEvent {
                let event = item1 as! EKEvent
                isEvent1 = true
                startDate1 = event.startDate
                isAllDay1 = event.isAllDay
            } else {
                let reminder = item1 as! EKReminder
                isEvent1 = false
                startDate1 = reminder.dueDateComponents?.date
                isAllDay1 = reminder.dueDateComponents?.hour == nil
            }
            if item2 is EKEvent {
                let event = item2 as! EKEvent
                isEvent2 = true
                startDate2 = event.startDate
                isAllDay2 = event.isAllDay
            } else {
                let reminder = item2 as! EKReminder
                isEvent2 = false
                startDate2 = reminder.dueDateComponents?.date
                isAllDay2 = reminder.dueDateComponents?.hour == nil
            }
            
            
            let eventCalendars = self.currentVisibleEventCalendars
            let reminderLists = self.currentVisibleReminderLists
            
            // 不看日期時間，依照 calendar -> title 來排序 event
            func sortEvents(_ event1: EKEvent, _ event2: EKEvent) -> Bool {
                // 依照 calendar 排序
                if event1.calendar.calendarIdentifier != event2.calendar.calendarIdentifier {
                    guard eventCalendars.contains(event1.calendar), eventCalendars.contains(event2.calendar) else {
                        return event1.calendar.calendarIdentifier < event2.calendar.calendarIdentifier
                    }
                    let index1 = eventCalendars.firstIndex(of: event1.calendar)!, index2 = eventCalendars.firstIndex(of: event2.calendar)!
                    return index1 < index2
                } else { // 屬於同一個 calendar
                    // 依照 title 排序
                    return event1.title < event2.title
                }
            }
            
            // 不看日期時間，依照 priority -> calendar -> title 來排序 reminder
            func sortReminders(_ reminder1: EKReminder, _ reminder2: EKReminder) -> Bool {
                // 依照 priority 排序
                if reminder1.priority != reminder2.priority {
                    if reminder1.priority == 0 || reminder2.priority == 0 {
                        return reminder2.priority == 0
                    } else {
                        return reminder1.priority < reminder2.priority
                    }
                } else { // priority 相同
                    if reminder1.calendar.calendarIdentifier != reminder2.calendar.calendarIdentifier {
                        guard reminderLists.contains(reminder1.calendar), reminderLists.contains(reminder2.calendar) else {
                            return reminder1.calendar.calendarIdentifier < reminder2.calendar.calendarIdentifier
                        }
                        let index1 = reminderLists.firstIndex(of: reminder1.calendar)!, index2 = reminderLists.firstIndex(of: reminder2.calendar)!
                        return index1 < index2
                    } else { // 屬於同一個 calendar
                        // 依照 title 排序
                        return reminder1.title < reminder2.title
                    }
                }
            }
            
            if isAllDay1 != isAllDay2 {
                // 整天的 排前面
                return isAllDay1
            } else {
                if isAllDay1 && isAllDay2 { // 都是整天
                    if isEvent1 != isEvent2 {
                        // event 排前面
                        return isEvent1
                    } else {
                        if isEvent1 && isEvent2 { // 都是 event
                            let event1 = item1 as! EKEvent, event2 = item2 as! EKEvent
                            return sortEvents(event1, event2)
                        } else { // 都是 reminder
                            let reminder1 = item1 as! EKReminder, reminder2 = item2 as! EKReminder
                            return sortReminders(reminder1, reminder2)
                        }
                    }
                } else { // 都是非整天
                    // startDate 早於當天凌晨 12:00 的，設為凌晨 12:00
                    if !calendar.isDate(startDate1, inSameDayAs: date) {
                        startDate1 = calendar.startOfDay(for: date)
                    }
                    if !calendar.isDate(startDate2, inSameDayAs: date) {
                        startDate2 = calendar.startOfDay(for: date)
                    }
                    if startDate1 != startDate2 {
                        // 比較早開始的 排前面
                        return startDate1 < startDate2
                    } else {
                        if isEvent1 != isEvent2 {
                            // reminder 排前面
                            return isEvent2
                        } else {
                            if isEvent1 && isEvent2 { // 都是 event
                                let event1 = item1 as! EKEvent, event2 = item2 as! EKEvent
                                let endDate1 = event1.endDate!, endDate2 = event2.endDate!
                                if endDate1 != endDate2 {
                                    // 比較早結束的 排前面
                                    return endDate1 < endDate2
                                } else {
                                    return sortEvents(event1, event2)
                                }
                            } else { // 都是 reminder
                                let reminder1 = item1 as! EKReminder, reminder2 = item2 as! EKReminder
                                return sortReminders(reminder1, reminder2)
                            }
                        }
                    }
                }
            }
        }
    }
    
    public func saveCompletionState(for reminder: EKReminder) {
        
        do {
            try eventStore.save(reminder, commit: true)
        }
        catch {
            print("🔸", "Failed to save completion state for reminder: \(error)")
        }
    }
    
    // MARK: - Private Methods
    
    private init() {}
    
    private func fetchAllEvents() {
        
        allEvents.removeAll()
        
        guard EKEventStore.authorizationStatus(for: .event) == .authorized else { return }
        
        var startDateComponents: DateComponents = {
            var components = DateComponents()
            components.calendar = calendar
            return components
        }()
        var endDateComponents: DateComponents = {
            var components = DateComponents()
            components.calendar = calendar
            components.month = 12
            components.day = 31
            components.hour = 23
            components.minute = 59
            components.second = 59
            return components
        }()
        
        for x in 0...(4000-1900)/4-1 { // 0...524
            let startYear = 1901 + (x * 4), endYear = startYear + 3
            startDateComponents.year = startYear
            endDateComponents.year = endYear
            guard let startDate = startDateComponents.date, let endDate = endDateComponents.date else { continue }
            let predicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: currentVisibleEventCalendars)
            let events = eventStore.events(matching: predicate)
            allEvents.append(contentsOf: events)
        }
    }
    
    private func fetchAllReminders() async {
        
        allReminders.removeAll()
        
        guard EKEventStore.authorizationStatus(for: .reminder) == .authorized else { return }
        
        let predicate = eventStore.predicateForReminders(in: currentVisibleReminderLists)
        
        allReminders = await withCheckedContinuation({ continuation in
            eventStore.fetchReminders(matching: predicate) { reminders in
                
                if let reminders {
                    continuation.resume(returning: reminders)
                } else {
                    continuation.resume(returning: [])
                }
            }
        })
    }
}
