import UIKit
import EventKit

public extension Calendar {
    
    func endOfDay(for date: Date) -> Date {
        
        let startOfNextDay = self.date(byAdding: .day, value: 1, to: startOfDay(for: date))!
        
        return startOfNextDay.addingTimeInterval(-1)
    }
    
    func dates(from startDate: Date, to endDate: Date) -> [Date]? {
        guard startDate != Date.distantPast, endDate != Date.distantFuture, startDate <= endDate else { return nil }
        
        var dates = [Date]()
        var date = startOfDay(for: startDate)
        
        while date <= endDate {
            dates.append(date)
            date = self.date(byAdding: .day, value: 1, to: date) ?? Date.distantFuture
        }
        
        return dates
    }
}

public extension [EKEvent] {
    
    func filteredWithTimeSpan(from start: Date, to end: Date) -> [EKEvent] {
        guard start <= end else { return [] }
        
        return self.filter {
            guard let startDate = $0.startDate, let endDate = $0.endDate else { return false }
            
            // 兩段時間有重疊到就算
            return startDate <= end && endDate > start
        }
    }
}

public extension [EKReminder] {
    
    func filteredWithTimeSpan(from start: Date?, to end: Date?) -> [EKReminder] {
        guard let start, let end else {
            return self.filter {
                return $0.dueDateComponents?.date == nil
            }
        }
        guard start <= end else { return [] }
        
        return self.filter {
            guard let components = $0.dueDateComponents, let date = components.date else { return false }
            
            return date >= start && date <= end
        }
    }
}
