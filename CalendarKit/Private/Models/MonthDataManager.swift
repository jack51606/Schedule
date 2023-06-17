import UIKit
import CoreData
import EventKit

final class MonthDataManager {
    
    // MARK: - Public Properties
    
    public static let shared = MonthDataManager()
    
    // MARK: - Private Properties
    
    private let calendar = CalendarPreferenceManager.shared.calendar
    private let calendarItemsManager = CalendarItemsManager.shared
    
    private let bundleIdentifier: String = "com.jack51606.CalendarKit"
    private let modelName: String = "DataModel"
    private let modelType: String = "momd"
    
    private var queueForUpdating = ThreadSafeMonthArray()
    
    private lazy var persistentContainer: NSPersistentContainer = {
        
        let bundle = Bundle(identifier: bundleIdentifier)!
        let url = bundle.url(forResource: modelName, withExtension: modelType)!
        let model = NSManagedObjectModel(contentsOf: url)!
        
        let container = NSPersistentContainer(name: modelName, managedObjectModel: model)
        container.loadPersistentStores { description, error in
            if let error {
                fatalError("Failed to load persistent stores: \(error)")
            }
        }
        
        return container
    }()
    
    // MARK: - Public Methods
    
    public func updateMonthData(_ month: Month) async {
        
        func performUpdate() async {
            
            let data = await data(by: month)
            
            await persistentContainer.performBackgroundTask { context in
                
                let request = MonthData.fetchRequest()
                let predicate = NSPredicate(format: "month == %@", month)
                request.predicate = predicate
                
                do {
                    var objects = try context.fetch(request)
                    if objects.isEmpty {
                        
                        let monthData = MonthData(context: context)
                        monthData.month = month
                        monthData.data = data
                        monthData.lastModifiedDate = Date()
                        
                        do {
                            try context.save()
                        }
                        catch {
                            print("🔸", "Failed to create MonthData for Month \(month.description): \(error.localizedDescription)")
                        }
                        
                    } else {
                        
                        // 只留下最新的那一個
                        objects.sort { $0.lastModifiedDate > $1.lastModifiedDate }
                        for index in objects.indices where index > 0 {
                            context.delete(objects[index])
                        }
                        
                        objects.first!.data = data
                        objects.first!.lastModifiedDate = Date()
                        
                        do {
                            try context.save()
                        }
                        catch {
                            print("🔸", "Failed to update MonthData by Month \(month.description): \(error.localizedDescription)")
                        }
                    }
                }
                catch {
                    print("🔸", "Failed to fetch MonthData by Month \(month.description): \(error.localizedDescription)")
                }
            }
        }
        
        guard !queueForUpdating.contains(month) else {
            
            // 如果這個 month 正在更新，就加到 queue 裡，然後直接返回
            // 正在更新的那部分，在做完之後會檢查到 queue 裡還有一次要執行，所以就會再執行一次，然後才會返回
            
            queueForUpdating.append(month)
            
            return
        }
        
        queueForUpdating.append(month)
        
        while queueForUpdating.contains(month) {
            await performUpdate()
            queueForUpdating.remove(month)
        }
    }
    
    public func updateMonthData(from start: Month, to end: Month) async {
        guard start <= end else { return }
        
        var months: [Month] {
            var months = [Month]()
            if start.year == end.year {
                for monthNumber in start.month...end.month {
                    months.append(Month(monthNumber, start.year)!)
                }
            } else {
                for monthNumber in start.month...12 {
                    months.append(Month(monthNumber, start.year)!)
                }
                if end.year - start.year > 1 {
                    for yearNumber in (start.year + 1)...(end.year - 1) {
                        for monthNumber in 1...12 {
                            months.append(Month(monthNumber, yearNumber)!)
                        }
                    }
                }
                for monthNumber in 1...end.month {
                    months.append(Month(monthNumber, end.year)!)
                }
            }
            months.sort()
            return months
        }
        
        // 先刪除 span 之外月份的 MonthData
        await persistentContainer.performBackgroundTask { context in
            
            var predicates: [NSPredicate] = []
            
            for month in months {
                let predicate = NSPredicate(format: "month != %@", month)
                predicates.append(predicate)
            }
            
            let request = NSFetchRequest<NSFetchRequestResult>(entityName: "MonthData")
            let compoundPredicate = NSCompoundPredicate(type: .and, subpredicates: predicates)
            request.predicate = compoundPredicate
            
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
            
            do {
                try context.execute(deleteRequest)
            }
            catch {
                print("🔸", "Failed to batch delete MonthData outside of update time span: \(error)")
            }
        }
        
        
        await withTaskGroup(of: Void.self) { group in
            
            for month in months {
                
                group.addTask { [weak self] in
                    guard let self else { return }
                    
                    await self.updateMonthData(month)
                }
            }
        }
    }
    
    public func fetchMonthData(by month: Month) -> MonthData? {
        
        let context = persistentContainer.viewContext
        
        let request = MonthData.fetchRequest()
        let predicate = NSPredicate(format: "month == %@", month)
        request.predicate = predicate
        
        var monthData: MonthData?
        
        do {
            var objects = try context.fetch(request)
            if !objects.isEmpty {
                objects.sort { $0.lastModifiedDate > $1.lastModifiedDate }
                monthData = objects.first!
            }
        }
        catch {
            print("🔸", "Failed to fetch MonthData for Month \(month.description): \(error.localizedDescription)")
        }
        
        return monthData
    }
    
    public func deleteAllMonthData() async {
        
        await persistentContainer.performBackgroundTask { context in
            
            let request = NSFetchRequest<NSFetchRequestResult>(entityName: "MonthData")
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
            
            do {
                try context.execute(deleteRequest)
            }
            catch {
                print("🔸", "Failed to delete all MonthData: \(error)")
            }
        }
    }
    
    // MARK: - Private Methods
    
    private init() {
        MonthTransformer.register()
        DataTransformer.register()
    }
    
    private func data(by month: Month) async -> Data {
        
        let allEventsInMonth = calendarItemsManager.events(from: month.startOfFirstDay, to: month.endOfLastDay)
        var allRemindersInMonth: [EKReminder] = []
        switch CalendarPreferenceManager.shared.currentChoiceOfShowingRemindersInCalendarView {
        case .IncompleteOnly:
            allRemindersInMonth = await calendarItemsManager.reminders(from: month.startOfFirstDay, to: month.endOfLastDay, option: .IncompleteOnly)
        case .ShowAll:
            allRemindersInMonth = await calendarItemsManager.reminders(from: month.startOfFirstDay, to: month.endOfLastDay, option: .All)
        case .HideAll:
            break
        }
        
        var dictionary = [Int: [Item]]()
        for date in calendar.dates(from: month.startOfFirstDay, to: month.endOfLastDay)! {
            let events = allEventsInMonth.filteredWithTimeSpan(from: calendar.startOfDay(for: date), to: calendar.endOfDay(for: date))
            let reminders = allRemindersInMonth.filteredWithTimeSpan(from: calendar.startOfDay(for: date), to: calendar.endOfDay(for: date))
            var calendarItems: [EKCalendarItem] = events + reminders
            
            calendarItems.sort(by: calendarItemsManager.singleDayCalendarItemsSortComparator(date: date))
            
            var items = [Item]()
            calendarItems.forEach {
                var type: ItemType!
                var color: UIColor!
                if let event = $0 as? EKEvent {
                    type = .event
                    color = UIColor(cgColor: event.calendar.cgColor)
                } else if let reminder = $0 as? EKReminder {
                    type = .reminder
                    color = UIColor(cgColor: reminder.calendar.cgColor)
                }
                let item = Item(type: type, color: color)
                items.append(item)
            }
            let day = calendar.component(.day, from: date)
            dictionary.updateValue(items, forKey: day)
        }
        
        return Data(dictionary: dictionary)
    }
}

final private class ThreadSafeMonthArray {
    
    private var array = [Month]()
    private let queue = DispatchQueue(label: "ThreadSafeMonthArray")
    
    func append(_ month: Month) {
        queue.sync {
            array.append(month)
        }
    }
    
    func remove(_ month: Month) {
        queue.sync {
            if let index = array.firstIndex(of: month) {
                self.array.remove(at: index)
            }
        }
    }
    
    func contains(_ month: Month) -> Bool {
        var result = false
        queue.sync {
            result = array.contains(where: { $0 == month })
        }
        return result
    }
}
