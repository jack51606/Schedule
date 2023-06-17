import UIKit

@MainActor final class MonthViewPageController: UIPageViewController {
    
    // MARK: - Private Properties
    
    public var selectedMonth: Month {
        return (viewControllers?.first as? MonthViewController)!.month
    }
    
    // MARK: - Private Properties
    
    private let calendar = CalendarPreferenceManager.shared.calendar
    private weak var calendarViewController: CalendarViewController?
    
    private var scrollView: UIScrollView?
    private var pageWidth: CGFloat?
    private var targetOffset: CGFloat?
    private var referencesOfCachedViewControllers = [Reference<MonthViewController>]()
    private weak var currentViewController: MonthViewController?
    private weak var previousViewController: MonthViewController?
    private weak var nextViewController: MonthViewController?
    
    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        calendarViewController = parent as? CalendarViewController
        setPageView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        view.heightAnchor.constraint(equalToConstant: 264).isActive = true
        setScrollViewDelegate()
    }
    
    // MARK: - Public Methods
    
    public init() {
        super.init(transitionStyle: .scroll, navigationOrientation: .horizontal, options: [.interPageSpacing: 30])
    }
    
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func setMonthViewController(_ monthViewController: MonthViewController, direction: NavigationDirection, animated: Bool, completion: ((Bool) -> Void)? = nil) {
        
        monthViewController.delegate = calendarViewController
        monthViewController.shouldSetDaySelectedAfterInitialize = true
        referencesOfCachedViewControllers.reap()
        setViewControllers([monthViewController], direction: direction, animated: animated, completion: completion)
    }
    
    public func scrollToMonth(_ month: Month) {
        guard month != selectedMonth else { return }
        
        scrollView?.isUserInteractionEnabled = false
        
        let direction: UIPageViewController.NavigationDirection = month > selectedMonth ? .forward : .reverse
        let monthViewController = MonthViewController(month: month)
        setMonthViewController(monthViewController, direction: direction, animated: true) { [weak self] completed in
            guard let self else { return }
            
            self.scrollView?.isUserInteractionEnabled = completed
        }
    }
    
    public func updateCalendarItemsForCurrentDisplayingMonth() {
        guard let currentMonthViewController = viewControllers?.first as? MonthViewController else { return }
        
        currentMonthViewController.updateCalendarItems()
    }
    
    // MARK: - Private Methods
    
    private func setScrollViewDelegate() {
        for subview in view.subviews {
            if let scrollView = subview as? UIScrollView {
                scrollView.delegate = self
                scrollView.delaysContentTouches = false
                self.scrollView = scrollView
                pageWidth = scrollView.bounds.width
            }
        }
    }
    
    private func setPageView() {
        
        dataSource = self
        delegate = self
        
        let singleMonthViewController = MonthViewController(month: Date().month)
        setMonthViewController(singleMonthViewController, direction: .forward, animated: false)
    }
    
    private func setSelectedDayForPendingMonthViewController(day: Int? = nil,_ monthViewController: MonthViewController) {
        
        if let day {
            // select 某個特定的日期
            print("🔸", day, "還沒寫")
        } else {
            if monthViewController.month.isCurrentMonth {
                let date = calendar.startOfDay(for: Date())
                calendarViewController?.selectedDate = date
                let day = calendar.component(.day, from: date)
                monthViewController.setDaySelected(day)
            } else {
                let date = monthViewController.month.startOfFirstDay
                calendarViewController?.selectedDate = date
                monthViewController.setDaySelected(1)
            }
        }
    }
}

extension MonthViewPageController: UIPageViewControllerDataSource {
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let previousMonth = selectedMonth.previousMonth else { return nil }
        
        let previousMonthViewController = MonthViewController(month: previousMonth)
        previousMonthViewController.delegate = calendarViewController
        
        referencesOfCachedViewControllers.reap()
        referencesOfCachedViewControllers.append(Reference(previousMonthViewController))
        
        return previousMonthViewController
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let nextMonth = selectedMonth.nextMonth else { return nil }
        
        let nextMonthViewController = MonthViewController(month: nextMonth)
        nextMonthViewController.delegate = calendarViewController
        
        referencesOfCachedViewControllers.reap()
        referencesOfCachedViewControllers.append(Reference(nextMonthViewController))
        
        return nextMonthViewController
    }
}

extension MonthViewPageController: UIPageViewControllerDelegate {
    
    func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController]) {
        
        currentViewController = viewControllers?.first as? MonthViewController
        
        guard let pendingMonthViewController = pendingViewControllers.first as? MonthViewController else { return }
        
        if pendingMonthViewController.month > selectedMonth {
            nextViewController = pendingMonthViewController
            previousViewController = nil
        } else {
            previousViewController = pendingMonthViewController
            nextViewController = nil
        }
        
        if targetOffset != nil { // 滑太快
            
            // 判斷往前往後
            let direction: NavigationDirection = previousViewController == nil ? .forward : .reverse
            
            if direction == .forward {
                if let month = currentViewController?.month.nextMonth {
                    referencesOfCachedViewControllers.forEach {
                        if let nextViewController = $0.object, nextViewController.month == month {
                            nextViewController.shouldSetDaySelectedAfterInitialize = true
                            setSelectedDayForPendingMonthViewController(nextViewController)
                            referencesOfCachedViewControllers.setEveryDayUnselectedForMonthViewControllers(besides: nextViewController)
                        }
                    }
                }
            } else {
                if let month = currentViewController?.month.previousMonth {
                    referencesOfCachedViewControllers.forEach {
                        if let previousViewController = $0.object, previousViewController.month == month {
                            previousViewController.shouldSetDaySelectedAfterInitialize = true
                            setSelectedDayForPendingMonthViewController(previousViewController)
                            referencesOfCachedViewControllers.setEveryDayUnselectedForMonthViewControllers(besides: previousViewController)
                        }
                    }
                }
            }
            
            targetOffset = nil
        }
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        
        if completed {
            guard let currentMonthViewController = viewControllers?.first as? MonthViewController else { return }
            
            currentViewController = nil
            previousViewController = nil
            nextViewController = nil
            
            currentMonthViewController.updateCalendarItems()
        }
    }
}

extension MonthViewPageController: UIScrollViewDelegate {
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        guard let pageWidth else { return }
        
        var direction: NavigationDirection? {
            
            let x = targetContentOffset.pointee.x
            
            if let targetOffset {
                if x != targetOffset { // 被拉回來，或去更遠了，但 selectedDate 已經更新過
                    self.targetOffset = x
                    // 判斷新的 direction
                    if targetOffset == pageWidth { // 本來沒有要動
                        return x > pageWidth ? .forward : .reverse
                    } else if targetOffset > pageWidth {
                        if x > targetOffset { // 從下個月去下下個月
                            return .forward
                        } else { // 從下個月回來
                            previousViewController = currentViewController
                            currentViewController = nextViewController
                            return .reverse
                        }
                    } else {
                        if x > targetOffset { // 從上個月回來
                            nextViewController = currentViewController
                            currentViewController = previousViewController
                            return .forward
                        } else { // 從上個月去上上個月
                            return .reverse
                        }
                    }
                } else {
                    guard x != pageWidth else { return nil }
                    return x > pageWidth ? .forward : .reverse
                }
            } else {
                targetOffset = x
                guard x != pageWidth else { return nil }
                return x > pageWidth ? .forward : .reverse
            }
        }
        
        guard let direction else { return }
        
        switch direction {
        case .forward:
            guard let nextViewController else { return }
            setSelectedDayForPendingMonthViewController(nextViewController)
        case .reverse:
            guard let previousViewController else { return }
            setSelectedDayForPendingMonthViewController(previousViewController)
        default:
            break
        }
        
        // 這邊其實如果調用 viewcontrollers.first 會發現已經變新的了，所以我們預先設好舊的去 setEveryDayUnselected
        currentViewController?.setEveryDayUnselected()
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard let pageWidth else { return }
        
        let offset = scrollView.contentOffset.x
        if offset != pageWidth {
            var correctOffset: CGFloat
            if offset > pageWidth {
                correctOffset = pageWidth * (offset / pageWidth).rounded(.up)
            } else {
                correctOffset = pageWidth * (offset / pageWidth).rounded(.down)
            }
            scrollView.setContentOffset(CGPoint(x: correctOffset, y: 0), animated: true)
        }
        
        targetOffset = nil
        
        // 最後手段，如果減速完沒有 selected 才會觸發
        if let currentViewController = viewControllers?.first as? MonthViewController, currentViewController.isEveryDayUnselected {
            setSelectedDayForPendingMonthViewController(currentViewController)
            referencesOfCachedViewControllers.setEveryDayUnselectedForMonthViewControllers(besides: currentViewController)
        }
    }
}

private class Reference<T: AnyObject> {
    
    weak var object : T?
    
    init (_ object: T) {
        self.object = object
    }
}

extension [Reference<MonthViewController>] {
    
    mutating func reap() {
        self = self.filter { $0.object != nil }
    }
    
    @MainActor mutating func setEveryDayUnselectedForMonthViewControllers(besides viewController: MonthViewController) {
        
        reap()
        
        let viewControllers = self.map(\.object!) as! [MonthViewController]
        for viewController in viewControllers {
            viewController.setEveryDayUnselected()
        }
    }
}
