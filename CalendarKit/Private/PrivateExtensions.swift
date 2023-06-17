import UIKit

extension Date {
    
    enum Format: String {
        case DMY, MDY, YMD
    }
    
    static var format: Format {
        
        let locale = CalendarPreferenceManager.shared.calendar.locale ?? Locale.current
        var localeWithJustLanguageCode: Locale!
        
        if #available(iOS 16, *) {
            localeWithJustLanguageCode = Locale(identifier: locale.language.languageCode!.identifier)
        } else {
            localeWithJustLanguageCode = Locale(identifier: locale.languageCode!)
        }
        
        let component = DateComponents(calendar: locale.calendar, year: 1999, month: 12, day: 31)
        let style = FormatStyle(date: .numeric, time: .none, locale: localeWithJustLanguageCode, calendar: locale.calendar)
        guard let string = component.date?.formatted(style) else { return .MDY }
        
        switch string {
        case "31/12/1999":
            return .DMY
        case "12/31/1999":
            return .MDY
        case "1999/12/31":
            return .YMD
        default:
            return .MDY
        }
    }
    
    var month: Month {
        let calendar = CalendarPreferenceManager.shared.calendar
        let year = calendar.dateComponents([.year], from: self).year!
        let month = calendar.dateComponents([.month], from: self).month!
        return Month(month, year)!
    }
}

extension UIFont {
    
    class func rounded(ofSize size: CGFloat, weight: UIFont.Weight = .regular) -> UIFont {
        
        let systemFont = UIFont.systemFont(ofSize: size, weight: weight)
        
        let font: UIFont
        if let descriptor = systemFont.fontDescriptor.withDesign(.rounded) {
            font = UIFont(descriptor: descriptor, size: size)
        } else {
            font = systemFont
        }
        
        return font
    }
}
