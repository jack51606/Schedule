import UIKit
import EventKit
import CustomNavigationController
import CalendarKit
import NBATeams

final class HomeViewController: CustomNavigationChildViewController {
    
    public var selectedDate: Date {
        return calendarViewController.selectedDate
    }
    
    // MARK: - Private Properties
    
    private var calendar: Calendar {
        return CalendarPreferenceManager.shared.calendar
    }
    private let calendarPreferenceManager = CalendarPreferenceManager.shared
    private let calendarItemsManager = CalendarItemsManager.shared
    
    private let titleButton: UIButton = {
        let button = UIButton()
        button.titleLabel?.font = .regularTitle
        button.setTitleColor(.tintColor, for: .normal)
        return button
    }()
    private let showCalendarViewButton: UIButton = {
        let button = UIButton()
        var configuration = UIButton.Configuration.plain()
        configuration.image = Constants.SFSymbols.calendar.withConfiguration(UIImage.SymbolConfiguration(pointSize: UIFont.buttonFontSize))
        button.configuration = configuration
        button.widthAnchor.constraint(equalToConstant: 40).isActive = true
        return button
    }()
    
    private let calendarViewController = CalendarViewController()
    private let dateLabel: PaddingLabel = {
        let label = PaddingLabel()
        label.padding = UIEdgeInsets(top: 4, left: 16, bottom: 4, right: 16)
        label.font = .alatsi(ofSize: 18)
        label.textColor = .tintColor
        label.backgroundColor = .secondarySystemBackground
        return label
    }()
    private let singleDayCalendarItemsViewController = SingleDayCalendarItemsViewController()
    
    private var timer: Timer!
    
    private var dateLabelTopConstraint: NSLayoutConstraint!
    
    private var cachedShowRemindersOptionInCalendarView: ShowRemindersOption?
    private var cachedShowRemindersOptionInSingleDayItemsView: ShowRemindersOption?
    private var cachedEventCalendarIdentifiers: [String]?
    private var cachedReminderListIdentifiers: [String]?
    
    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setNavigationItems()
        setCalendarViewController()
        setDateLabel()
        setSingleDayCalendarItemsViewController()
        
        setupTimer()
        
        // 已經決定過權限了
        if EKEventStore.authorizationStatus(for: .event) != .notDetermined && EKEventStore.authorizationStatus(for: .reminder) != .notDetermined {
            
            Task {
                
                if calendarItemsManager.eventStoreAuthorizationStatusesUpdated {
                    
                    calendarItemsManager.saveEventStoreAuthorizationStatuses()
                    
                    // 清空所有 MonthData
                    await calendarViewController.clearAllCachedCalendarItems()
                    
                }
                
                setObservers()
                
                updateCachedDefaultProperties()
                
                calendarItemsManager.refreshEventStoreSourcesIfNecessary()
                
                calendarViewController.updateCalendarItemsForCurrentDisplayingMonth()
                
                await calendarViewController.preUpdateMonthData()
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        guard EKEventStore.authorizationStatus(for: .event) != .notDetermined && EKEventStore.authorizationStatus(for: .reminder) != .notDetermined else { return }
        
        var needsUpdate = false
        var needsPreUpdateMonthData = false
        
        if let cachedShowRemindersOptionInCalendarView, cachedShowRemindersOptionInCalendarView != calendarPreferenceManager.currentChoiceOfShowingRemindersInCalendarView {
            needsUpdate = true
            needsPreUpdateMonthData = true
        }
        
        if let cachedShowRemindersOptionInSingleDayItemsView, cachedShowRemindersOptionInSingleDayItemsView != calendarPreferenceManager.currentChoiceOfShowingRemindersInSingleDayItemsView {
            needsUpdate = true
        }
        
        if let cachedEventCalendarIdentifiers, cachedEventCalendarIdentifiers != calendarItemsManager.currentVisibleEventCalendarIdentifiers {
            needsUpdate = true
            needsPreUpdateMonthData = true
        }
        
        if let cachedReminderListIdentifiers, cachedReminderListIdentifiers != calendarItemsManager.currentVisibleReminderListIdentifiers {
            needsUpdate = true
            needsPreUpdateMonthData = true
        }
        
        updateCachedDefaultProperties()
        
        if needsUpdate {
            
            calendarViewController.updateCalendarItemsForCurrentDisplayingMonth()
            singleDayCalendarItemsViewController.updateCalendarItemsForCollectionView(collapseReminderCells: true)
            
            if needsPreUpdateMonthData {
                Task {
                    await calendarViewController.preUpdateMonthData()
                }
            }
        }
    }
    
    // MARK: - Override Methods
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard let keyPath else { return }
        
        switch keyPath {
        case CalendarKit.Constants.UserDefaultsKeys.firstWeekday:
            updateDateLabelTopConstraint()
        default:
            break
        }
    }
    
    // MARK: - Private Methods
    
    private func setNavigationItems() {
        
        // Title Button
        setTitle()
        titleButton.addTarget(self, action: #selector(backToToday), for: .touchUpInside)
        navigationBar.addSubview(titleButton)
        titleButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            titleButton.centerYAnchor.constraint(equalTo: navigationBar.centerYAnchor),
            titleButton.leadingAnchor.constraint(equalTo: navigationBar.leadingAnchor, constant: 20)
        ])
        
        // Show CalendarView Button
        showCalendarViewButton.isSelected = true
        showCalendarViewButton.addTarget(self, action: #selector(showCalendarView), for: .touchUpInside)
        customNavigationItem.rightBarButtonItem = UIBarButtonItem(customView: showCalendarViewButton)
    }
    
    private func setCalendarViewController() {
        
        calendarViewController.delegate = self
        calendarViewController.padding = UIEdgeInsets(top: 8, left: 4, bottom: 4, right: 4)
        
        addChild(calendarViewController)
        view.addSubview(calendarViewController.view)
        calendarViewController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            calendarViewController.view.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor),
            calendarViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            calendarViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        calendarViewController.didMove(toParent: self)
    }
    
    private func setDateLabel() {
        
        setDateLabelText()
        dateLabel.layer.borderColor = UIColor.opaqueSeparator.cgColor
        
        view.addSubview(dateLabel)
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        dateLabelTopConstraint = dateLabel.topAnchor.constraint(equalTo: calendarViewController.view.bottomAnchor)
        updateDateLabelTopConstraint()
        NSLayoutConstraint.activate([
            dateLabelTopConstraint,
            dateLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dateLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        let topBorder: UIView = {
            let view = UIView()
            view.backgroundColor = .opaqueSeparator
            view.heightAnchor.constraint(equalToConstant: 0.3).isActive = true
            return view
        }()
        view.addSubview(topBorder)
        topBorder.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            topBorder.topAnchor.constraint(equalTo: dateLabel.topAnchor),
            topBorder.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topBorder.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        let bottomBorder: UIView = {
            let view = UIView()
            view.backgroundColor = .opaqueSeparator
            view.heightAnchor.constraint(equalToConstant: 0.3).isActive = true
            return view
        }()
        view.addSubview(bottomBorder)
        bottomBorder.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            bottomBorder.bottomAnchor.constraint(equalTo: dateLabel.bottomAnchor),
            bottomBorder.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomBorder.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
    
    private func setSingleDayCalendarItemsViewController() {
        
        singleDayCalendarItemsViewController.date = calendarViewController.selectedDate
        singleDayCalendarItemsViewController.padding = UIEdgeInsets(top: 0, left: 4, bottom: 0, right: 4)
        singleDayCalendarItemsViewController.delegate = self
        
        addChild(singleDayCalendarItemsViewController)
        view.addSubview(singleDayCalendarItemsViewController.view)
        singleDayCalendarItemsViewController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            singleDayCalendarItemsViewController.view.topAnchor.constraint(equalTo: dateLabel.bottomAnchor),
            singleDayCalendarItemsViewController.view.bottomAnchor.constraint(equalTo: view.layoutMarginsGuide.bottomAnchor),
            singleDayCalendarItemsViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            singleDayCalendarItemsViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        singleDayCalendarItemsViewController.didMove(toParent: self)
    }
    
    private func setObservers() {
        
        let defaults = UserDefaults.standard
        let notificationCenter = NotificationCenter.default
        
        defaults.addObserver(self, forKeyPath: CalendarKit.Constants.UserDefaultsKeys.firstWeekday, context: nil)
        notificationCenter.addObserver(self, selector: #selector(sceneWillEnterForeground), name: UIScene.willEnterForegroundNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(EKEventStoreChanged), name: .EKEventStoreChanged, object: nil)
    }
    
    private func setupTimer() {
        
        let date = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: Date()))!
        timer = Timer(fireAt: date, interval: 86400, target: self, selector: #selector(didPassMidnight), userInfo: nil, repeats: true)
        
        RunLoop.main.add(timer, forMode: .common)
    }
    
    private func setTitle() {
        
        UIView.performWithoutAnimation {
            
            titleButton.setTitle(calendarViewController.selectedDate.formatted(.dateTime.year().month(.wide)), for: .normal)
            navigationBar.layoutIfNeeded()
        }
    }
    
    private func setDateLabelText() {
        
        let dot = "・"
        var prefix: String? {
            if calendar.isDateInToday(calendarViewController.selectedDate) {
                return Strings.today
            } else if calendar.isDateInTomorrow(calendarViewController.selectedDate) {
                return Strings.tomorrow
            } else if calendar.isDateInYesterday(calendarViewController.selectedDate) {
                return Strings.yesterday
            } else {
                return nil
            }
        }
        let dateText = calendarViewController.selectedDate.formatted(.dateTime.month(.defaultDigits).day(.defaultDigits).weekday())
        
        if let prefix {
            if Locale.current.isChinese {
                dateLabel.text = dot + prefix + Strings.space + dateText
            } else {
                dateLabel.text = dot + prefix + Strings.comma + Strings.space + dateText
            }
        } else {
            dateLabel.text = dot + dateText
        }
    }
    
    private func updateDateLabelTopConstraint() {
        
        let numberOfWeeksInMonth = calendar.range(of: .weekOfMonth, in: .month, for: calendarViewController.selectedDate)!.count
        let constant = showCalendarViewButton.isSelected ? CGFloat(-(6 - numberOfWeeksInMonth) * 44 + 6) : -(self.calendarViewController.view.frame.height)
        dateLabelTopConstraint.constant = constant
    }
    
    private func updateCachedDefaultProperties() {
        
        cachedShowRemindersOptionInCalendarView = calendarPreferenceManager.currentChoiceOfShowingRemindersInCalendarView
        
        cachedShowRemindersOptionInSingleDayItemsView = calendarPreferenceManager.currentChoiceOfShowingRemindersInSingleDayItemsView
        
        cachedEventCalendarIdentifiers = calendarItemsManager.currentVisibleEventCalendarIdentifiers
        
        cachedReminderListIdentifiers = calendarItemsManager.currentVisibleReminderListIdentifiers
    }
    
    @objc private func backToToday(_ sender: UIButton) {
        
        // 產生觸覺回饋
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        if calendar.component(.month, from: calendarViewController.selectedDate) == calendar.component(.month, from: Date()) {
            generator.impactOccurred()
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                generator.impactOccurred()
            }
        }
        
        sender.transform = CGAffineTransform(scaleX: 0.98, y: 0.95)
        UIView.animate(withDuration: 0.3) {
            sender.transform = .identity
        }
        
        if calendarViewController.selectedDate != calendar.startOfDay(for: Date()) {
            calendarViewController.setSelectedDate(calendar.startOfDay(for: Date()))
        }
    }
    
    @objc private func showCalendarView(_ sender: UIButton) {
        
        sender.isUserInteractionEnabled = false
        sender.isSelected.toggle()
        
        UIView.animate(withDuration: sender.isSelected ? 0.3 : 0.28, delay: sender.isSelected ? 0.1 : 0, options: .curveEaseOut) { [weak self] in
            guard let self else { return }
            
            self.calendarViewController.view.alpha = sender.isSelected ? 1 : 0
        }
        
        UIView.animate(withDuration: sender.isSelected ? 0.28 : 0.3, delay: sender.isSelected ? 0 : 0.1, options: [.curveEaseInOut, .preferredFramesPerSecond60]) { [weak self] in
            guard let self else { return }
            
            self.updateDateLabelTopConstraint()
            self.view.layoutIfNeeded()
        } completion: { completed in
            sender.isUserInteractionEnabled = completed
        }
    }
    
    @objc private func sceneWillEnterForeground() {
        
        calendarItemsManager.refreshEventStoreSourcesIfNecessary()
        
        // 這裡不要更新 UI，等收到 EventStore 通知後再更新
    }
    
    @objc private func EKEventStoreChanged() {
        
        calendarViewController.updateCalendarItemsForCurrentDisplayingMonth()
        singleDayCalendarItemsViewController.updateCalendarItemsForCollectionView(animatingDifferences: true)
        singleDayCalendarItemsViewController.updateCalendarItemsForCollectionView()
    }
    
    @objc private func didPassMidnight() {
        
        calendarViewController.updateToCurrentDate()
        setDateLabelText()
        singleDayCalendarItemsViewController.updateCalendarItemsForCollectionView()
    }
}

extension HomeViewController: LaunchAnimationDelegate {
    
    func didFinishLaunchAnimation() {
        // 有權限未決定才會執行
        guard EKEventStore.authorizationStatus(for: .event) == .notDetermined || EKEventStore.authorizationStatus(for: .reminder) == .notDetermined else { return }
        
        Task {
            
            await calendarItemsManager.requestAuthorization()
            
            calendarItemsManager.saveEventStoreAuthorizationStatuses()
            
            setObservers()
            
            updateCachedDefaultProperties()
            
            calendarItemsManager.refreshEventStoreSourcesIfNecessary()
            
            calendarViewController.updateCalendarItemsForCurrentDisplayingMonth()
            singleDayCalendarItemsViewController.updateCalendarItemsForCollectionView()
            
            await calendarViewController.preUpdateMonthData()
        }
    }
}

extension HomeViewController: CalendarViewControllerDelegate {
    
    func didSetSelectedDate() {
        
        setTitle()
        setDateLabelText()
        
        singleDayCalendarItemsViewController.date = calendarViewController.selectedDate
        
        if showCalendarViewButton.isSelected {
            
            calendarViewController.view.layoutIfNeeded()
            
            UIView.animate(withDuration: 0.16, delay: 0, options: [.curveEaseInOut, .preferredFramesPerSecond60]) { [weak self] in
                guard let self else { return }
                
                self.updateDateLabelTopConstraint()
                self.view.layoutIfNeeded()
            }
        }
    }
}

extension HomeViewController: SingleDayCalendarItemsViewControllerDelegate {
    
    var collectionViewPlaceholder: UIView {
        
        let label = UILabel()
        label.text = Strings.noEvents
        label.font = .alatsi(ofSize: 20)
        label.textColor = .placeholderText
        
        return label
    }
    
    func replacementAttributedTitleForEvent(withTitle originalTitle: String, originalFont: UIFont) -> NSAttributedString? {
        
        return originalTitle.NBAGameTitleAttributedText(font: originalFont)
    }
    
    func eventSelected(_ event: EKEvent) {
        
        let viewController = CustomNavigationController(rootViewController: EventEditingViewController(event: event))
        viewController.isPresentedModally = true
        
        present(viewController, animated: true)
    }
    
    func reminderSelected(_ reminder: EKReminder) {
        
        let viewController = CustomNavigationController(rootViewController: ReminderEditingViewController(reminder: reminder))
        viewController.isPresentedModally = true
        
        present(viewController, animated: true)
    }
}
