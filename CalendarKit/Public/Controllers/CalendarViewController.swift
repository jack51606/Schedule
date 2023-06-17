import UIKit
import EventKit

@objc public protocol CalendarViewControllerDelegate: AnyObject {
    @objc optional func didSetSelectedDate()
}

public final class CalendarViewController: UIViewController {
    
    public weak var delegate: CalendarViewControllerDelegate?
    
    public internal (set) var selectedDate: Date = CalendarPreferenceManager.shared.calendar.startOfDay(for: Date()) {
        didSet {
            guard selectedDate != oldValue else { return }
            
            delegate?.didSetSelectedDate?()
        }
    }
    
    public var padding: UIEdgeInsets = .zero
    
    // MARK: - Private Properties
    
    private var calendar: Calendar {
        return CalendarPreferenceManager.shared.calendar
    }
    
    private let monthDataManager = MonthDataManager.shared
    
    private let weekdayLabels: [UILabel] = {
        var labels = [UILabel]()
        for _ in 1...7 {
            let label = UILabel()
            label.font = .systemFont(ofSize: 14, weight: .medium)
            if let descriptor = label.font.fontDescriptor.withDesign(.rounded) {
                label.font = UIFont(descriptor: descriptor, size: 14)
            }
            label.textColor = .secondaryLabel
            label.textAlignment = .center
            labels.append(label)
        }
        return labels
    }()
    private let monthViewPageController = MonthViewPageController()
    
    // MARK: - Life Cycle
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        setContents()
        setSubviews()
        setObservers()
    }
    
    // MARK: - Override Methods
    
    public override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard let keyPath else { return }
        
        switch keyPath {
            
        case Constants.UserDefaultsKeys.firstWeekday:
            
            updateWeekdayLabelsText()
            
            let monthViewController = MonthViewController(month: selectedDate.month)
            monthViewPageController.setMonthViewController(monthViewController, direction: .forward, animated: false)
            
        default:
            break
        }
    }
    
    // MARK: - Public Methods
    
    public func setSelectedDate(_ date: Date) {
        guard date != selectedDate else { return }
        
        let year = date.month.year
        guard year > 1900, year <= 4000 else { return }
        
        if (date.month != selectedDate.month) {
            monthViewPageController.scrollToMonth(date.month)
        } else {
            (monthViewPageController.viewControllers?.first as? MonthViewController)?.setDaySelected(calendar.component(.day, from: date))
        }
        
        selectedDate = date
    }
    
    public func updateCalendarItemsForCurrentDisplayingMonth() {
        monthViewPageController.updateCalendarItemsForCurrentDisplayingMonth()
    }
    
    public func updateToCurrentDate() {
        guard let currentMonthViewController = monthViewPageController.viewControllers?.first as? MonthViewController else { return }
        
        currentMonthViewController.updateToCurrentDate()
    }
    
    public func preUpdateMonthData() async {
        
        let authorizationStatusForEvents = EKEventStore.authorizationStatus(for: .event)
        let authorizationStatusForReminders = EKEventStore.authorizationStatus(for: .reminder)
        guard authorizationStatusForEvents != .notDetermined else { return }
        guard authorizationStatusForReminders != .notDetermined else { return }
        guard authorizationStatusForEvents == .authorized || authorizationStatusForReminders == .authorized else { return }
        
        let startMonth = calendar.date(byAdding: .year, value: -2, to: Date())!.month
        let endMonth = calendar.date(byAdding: .year, value: 2, to: Date())!.month
        
        await monthDataManager.updateMonthData(from: startMonth, to: endMonth)
    }
    
    public func clearAllCachedCalendarItems() async {
        await monthDataManager.deleteAllMonthData()
    }
    
    // MARK: - Private Methods
    
    private func setContents() {
        
        updateWeekdayLabelsText()
        
        addChild(monthViewPageController)
    }
    
    private func setSubviews() {
        
        let weekdaySymbolsView: UIStackView = {
            let view = UIStackView()
            view.axis = .horizontal
            view.alignment = .center
            view.distribution = .fillEqually
            view.heightAnchor.constraint(equalToConstant: 18).isActive = true
            
            for label in weekdayLabels {
                view.addArrangedSubview(label)
            }
            
            return view
        }()
        
        let stackView: UIStackView = {
            let view = UIStackView()
            view.axis = .vertical
            view.alignment = .fill
            view.spacing = 4
            
            view.addArrangedSubview(weekdaySymbolsView)
            view.addArrangedSubview(monthViewPageController.view)
            
            return view
        }()
        
        view.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: view.topAnchor, constant: padding.top),
            stackView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -padding.bottom),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: padding.left),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -padding.right)
        ])
        
        monthViewPageController.didMove(toParent: self)
    }
    
    private func setObservers() {
        
        let defaults = UserDefaults.standard
        let notificationCenter = NotificationCenter.default
        
        defaults.addObserver(self, forKeyPath: Constants.UserDefaultsKeys.firstWeekday, context: nil)
        notificationCenter.addObserver(self, selector: #selector(sceneWillEnterForeground), name: UIScene.willEnterForegroundNotification, object: nil)
    }
    
    private func updateWeekdayLabelsText() {
        
        let symbols = calendar.shortStandaloneWeekdaySymbols
        
        for index in symbols.indices {
            let symbol = symbols[(index + calendar.firstWeekday - 1) % 7]
            weekdayLabels[index].text = symbol
        }
    }
    
    @objc private func sceneWillEnterForeground() {
        
        updateCalendarItemsForCurrentDisplayingMonth()
    }
}

extension CalendarViewController: MonthViewControllerDelegate {
    
    func didSelectDate(date: Date) {
        selectedDate = date
    }
}
