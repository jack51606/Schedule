import UIKit
import CustomNavigationController
import CalendarKit

final class SettingsViewController: CustomNavigationChildViewController {
    
    // MARK: - Private Properties
    
    private let appearanceManager = AppearanceManager.shared
    private let themeColorManager = ThemeColorManager.shared
    private let calendarPreferenceManager = CalendarPreferenceManager.shared
    private let calendarItemsManager = CalendarItemsManager.shared
    private let defaults = UserDefaults.standard
    
    private let titleButton: UIButton = {
        let button = UIButton()
        button.titleLabel?.font = .regularTitle
        button.setTitleColor(.tintColor, for: .normal)
        return button
    }()
    
    private var collectionView: UICollectionView!
    
    private enum Section: Int, CaseIterable {
        
        case General, CalendarView, SingleDayItemsView, Events, Reminders
        
        var title: String {
            switch self {
            case .General:
                return Strings.general
            case .CalendarView:
                return Strings.calendarView
            case .SingleDayItemsView:
                return Strings.singleDayItemsView
            case .Events:
                return Strings.events
            case .Reminders:
                return Strings.reminders
            }
        }
    }
    private enum CellName: String, CaseIterable {
        
        case BlankCell
        case AppearanceCell
        case ThemeColorCell
        case FirstWeekdayCell
        case ShowRemindersInCalendarViewCell
        case ShowRemindersInSingleDayItemsViewCell
        case EventCalendarsCell
        case DefaultEventCalendarCell
        case ReminderListsCell
        case DefaultReminderListCell
        
        var tag: Int {
            switch self {
            case .BlankCell:
                return 0
            case .AppearanceCell:
                return 1
            case .ThemeColorCell:
                return 2
            case .FirstWeekdayCell:
                return 3
            case .ShowRemindersInCalendarViewCell:
                return 4
            case .ShowRemindersInSingleDayItemsViewCell:
                return 5
            case .EventCalendarsCell:
                return 6
            case .DefaultEventCalendarCell:
                return 7
            case .ReminderListsCell:
                return 8
            case .DefaultReminderListCell:
                return 9
            }
        }
    }
    
    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setNavigationItems()
        setCollectionView()
        setObservers()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        collectionView.reloadData()
    }
    
    deinit {
        removeObservers()
    }
    
    // MARK: - Override Methods
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        guard let indexPath = indexPathForCell(name: .AppearanceCell) else { return }
        
        collectionView.reconfigureItems(at: [indexPath])
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard let keyPath else { return }
        
        switch keyPath {
        case Constants.UserDefaultsKeys.appearance:
            collectionView.reloadData()
        case Constants.UserDefaultsKeys.themeColor:
            collectionView.reloadData()
        case CalendarKit.Constants.UserDefaultsKeys.firstWeekday:
            collectionView.reloadData()
        case CalendarKit.Constants.UserDefaultsKeys.showRemindersInCalendarView:
            collectionView.reloadData()
        case CalendarKit.Constants.UserDefaultsKeys.showRemindersInSingleDayItemsView:
            collectionView.reloadData()
        case CalendarKit.Constants.UserDefaultsKeys.eventCalendars:
            collectionView.reloadData()
        case CalendarKit.Constants.UserDefaultsKeys.defaultEventCalendar:
            collectionView.reloadData()
        case CalendarKit.Constants.UserDefaultsKeys.reminderLists:
            collectionView.reloadData()
        case CalendarKit.Constants.UserDefaultsKeys.defaultReminderList:
            collectionView.reloadData()
        default:
            break
        }
    }
    
    // MARK: - Private Methods
    
    private func setNavigationItems() {
        
        titleButton.setTitle(Strings.settings, for: .normal)
        navigationBar.addSubview(titleButton)
        titleButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            titleButton.centerYAnchor.constraint(equalTo: navigationBar.centerYAnchor),
            titleButton.leadingAnchor.constraint(equalTo: navigationBar.leadingAnchor, constant: 20)
        ])
    }
    
    private func setCollectionView() {
        
        var configuration = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
        configuration.backgroundColor = .clear
        configuration.headerMode = .supplementary
        let layout = UICollectionViewCompositionalLayout.list(using: configuration)
        
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(SectionHeader.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: SectionHeader.identifier)
        collectionView.register(UICollectionViewListCell.self, forCellWithReuseIdentifier: UICollectionViewListCell.self.description())
        collectionView.contentInset.top = 20
        collectionView.contentInset.bottom = 60
        collectionView.backgroundColor = .clear
        
        view.addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.layoutMarginsGuide.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
    
    private func setObservers() {
        defaults.addObserver(self, forKeyPath: Constants.UserDefaultsKeys.appearance, context: nil)
        defaults.addObserver(self, forKeyPath: Constants.UserDefaultsKeys.themeColor, context: nil)
        defaults.addObserver(self, forKeyPath: CalendarKit.Constants.UserDefaultsKeys.firstWeekday, context: nil)
        defaults.addObserver(self, forKeyPath: CalendarKit.Constants.UserDefaultsKeys.showRemindersInCalendarView, context: nil)
        defaults.addObserver(self, forKeyPath: CalendarKit.Constants.UserDefaultsKeys.showRemindersInSingleDayItemsView, context: nil)
        defaults.addObserver(self, forKeyPath: CalendarKit.Constants.UserDefaultsKeys.eventCalendars, context: nil)
        defaults.addObserver(self, forKeyPath: CalendarKit.Constants.UserDefaultsKeys.defaultEventCalendar, context: nil)
        defaults.addObserver(self, forKeyPath: CalendarKit.Constants.UserDefaultsKeys.reminderLists, context: nil)
        defaults.addObserver(self, forKeyPath: CalendarKit.Constants.UserDefaultsKeys.defaultReminderList, context: nil)
    }
    
    private func removeObservers() {
        defaults.removeObserver(self, forKeyPath: Constants.UserDefaultsKeys.appearance)
        defaults.removeObserver(self, forKeyPath: Constants.UserDefaultsKeys.themeColor)
        defaults.removeObserver(self, forKeyPath: CalendarKit.Constants.UserDefaultsKeys.firstWeekday)
        defaults.removeObserver(self, forKeyPath: CalendarKit.Constants.UserDefaultsKeys.showRemindersInCalendarView)
        defaults.removeObserver(self, forKeyPath: CalendarKit.Constants.UserDefaultsKeys.showRemindersInSingleDayItemsView)
        defaults.removeObserver(self, forKeyPath: CalendarKit.Constants.UserDefaultsKeys.eventCalendars)
        defaults.removeObserver(self, forKeyPath: CalendarKit.Constants.UserDefaultsKeys.defaultEventCalendar)
        defaults.removeObserver(self, forKeyPath: CalendarKit.Constants.UserDefaultsKeys.reminderLists)
        defaults.removeObserver(self, forKeyPath: CalendarKit.Constants.UserDefaultsKeys.defaultReminderList)
    }
    
    private func cellName(at indexPath: IndexPath) -> CellName {
        
        switch indexPath {
            
        case IndexPath(item: 0, section: 0):
            return .AppearanceCell
        case IndexPath(item: 1, section: 0):
            return .ThemeColorCell
        case IndexPath(item: 0, section: 1):
            return .FirstWeekdayCell
        case IndexPath(item: 1, section: 1):
            return .ShowRemindersInCalendarViewCell
        case IndexPath(item: 0, section: 2):
            return .ShowRemindersInSingleDayItemsViewCell
        case IndexPath(item: 0, section: 3):
            return .EventCalendarsCell
        case IndexPath(item: 1, section: 3):
            return .DefaultEventCalendarCell
        case IndexPath(item: 0, section: 4):
            return .ReminderListsCell
        case IndexPath(item: 1, section: 4):
            return .DefaultReminderListCell
        default:
            return .BlankCell
        }
    }
    
    private func indexPathForCell(name: CellName) -> IndexPath? {
        
        for section in 0...collectionView.numberOfSections - 1 {
            for item in 0...collectionView.numberOfItems(inSection: section) {
                let indexPath = IndexPath(item: item, section: section)
                if let item = collectionView.cellForItem(at: indexPath) {
                    if item.tag == name.tag {
                        return indexPath
                    }
                }
            }
        }
        
        return nil
    }
}

extension SettingsViewController: UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        
        return Section.allCases.count
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: SectionHeader.identifier, for: indexPath) as! SectionHeader
        
        header.setTitle(Section.allCases[indexPath.section].title)
        
        return header
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        switch Section.allCases[section] {
        case .General:
            return 2
        case .CalendarView:
            return 2
        case .SingleDayItemsView:
            return 1
        case .Events:
            return calendarItemsManager.defaultEventCalendar == nil ? 1 : 2
        case .Reminders:
            return calendarItemsManager.defaultReminderList == nil ? 1 : 2
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: UICollectionViewListCell.self.description(), for: indexPath) as! UICollectionViewListCell
        
        var configuration = cell.defaultContentConfiguration()
        configuration.textProperties.font = .rounded(ofSize: configuration.textProperties.font.pointSize)
        configuration.secondaryTextProperties.font = .rounded(ofSize: 18)
        configuration.secondaryTextProperties.color = .secondaryLabel
        configuration.prefersSideBySideTextAndSecondaryText = true
        
        let cellName = cellName(at: indexPath)
        switch cellName {
        case .BlankCell:
            break
        case .AppearanceCell:
            let image = traitCollection.userInterfaceStyle == .dark ? Constants.SFSymbols.moon : Constants.SFSymbols.sun
            configuration.image = image.withConfiguration(UIImage.SymbolConfiguration(scale: .default))
            configuration.imageToTextPadding = 12
            configuration.text = Strings.appearance
            configuration.secondaryText = appearanceManager.currentChoiceOfAppearance.text
        case .ThemeColorCell:
            let image = Constants.SFSymbols.paintbrush
            configuration.image = image.withConfiguration(UIImage.SymbolConfiguration(scale: .default))
            configuration.imageToTextPadding = 12
            configuration.text = Strings.themeColor
            configuration.secondaryText = themeColorManager.currentChoiceOfThemeColor.text
        case .FirstWeekdayCell:
            configuration.text = Strings.firstWeekday
            var secondaryText: String {
                let choice = calendarPreferenceManager.currentChoiceOfFirstWeekday
                if choice == .SystemSetting {
                    let text = FirstWeekdayOption.SystemSetting.text
                    let weekdayText = Calendar.autoupdatingCurrent.weekdaySymbols[Calendar.autoupdatingCurrent.firstWeekday - 1]
                    return Locale.autoupdatingCurrent.isChinese ? weekdayText + Strings.parenthesisLeft + text + Strings.parenthesisRight : weekdayText + Strings.space + Strings.parenthesisLeft + text + Strings.parenthesisRight
                } else {
                    return choice.text
                }
            }
            configuration.secondaryText = secondaryText
        case .ShowRemindersInCalendarViewCell:
            configuration.text = Strings.showReminders
            configuration.secondaryText = calendarPreferenceManager.currentChoiceOfShowingRemindersInCalendarView.text
        case .ShowRemindersInSingleDayItemsViewCell:
            configuration.text = Strings.showReminders
            configuration.secondaryText = calendarPreferenceManager.currentChoiceOfShowingRemindersInSingleDayItemsView.text
        case .EventCalendarsCell:
            configuration.text = Strings.calendars
            configuration.secondaryText = calendarItemsManager.currentVisibleEventCalendars.count.formatted()
        case .DefaultEventCalendarCell:
            configuration.text = Strings.defaultCalendar
            var attributedString: NSAttributedString {
                let attributedString = NSMutableAttributedString()
                let image = Constants.SFSymbols.circlebadgeFill.withConfiguration(UIImage.SymbolConfiguration(scale: .small)).withTintColor(UIColor(cgColor: calendarItemsManager.defaultEventCalendar!.cgColor))
                let colorIcon = NSAttributedString(attachment: NSTextAttachment(image: image))
                let space = NSAttributedString(string: Strings.space)
                let calendarTitle = NSAttributedString(string: calendarItemsManager.defaultEventCalendar!.title)
                attributedString.append(colorIcon)
                attributedString.append(space)
                attributedString.append(space)
                attributedString.append(calendarTitle)
                return attributedString
            }
            configuration.secondaryAttributedText = attributedString
        case .ReminderListsCell:
            configuration.text = Strings.lists
            configuration.secondaryText = calendarItemsManager.currentVisibleReminderLists.count.formatted()
        case .DefaultReminderListCell:
            configuration.text = Strings.defaultList
            var attributedString: NSAttributedString {
                let attributedString = NSMutableAttributedString()
                let image = Constants.SFSymbols.circlebadgeFill.withConfiguration(UIImage.SymbolConfiguration(scale: .small)).withTintColor(UIColor(cgColor: calendarItemsManager.defaultReminderList!.cgColor))
                let colorIcon = NSAttributedString(attachment: NSTextAttachment(image: image))
                let space = NSAttributedString(string: Strings.space)
                let calendarTitle = NSAttributedString(string: calendarItemsManager.defaultReminderList!.title)
                attributedString.append(colorIcon)
                attributedString.append(space)
                attributedString.append(space)
                attributedString.append(calendarTitle)
                return attributedString
            }
            configuration.secondaryAttributedText = attributedString
        }
        
        cell.contentConfiguration = configuration
        
        var backgroundConfiguration = cell.backgroundConfiguration
        backgroundConfiguration?.backgroundColor = .tertiarySystemBackground
        cell.backgroundConfiguration = backgroundConfiguration
        
        cell.accessories = [.disclosureIndicator()]
        cell.tag = cellName.tag
        
        return cell
    }
}

extension SettingsViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        collectionView.deselectItem(at: indexPath, animated: true)
        
        var viewController: UIViewController?
        
        let cellName = cellName(at: indexPath)
        switch cellName {
        case .AppearanceCell:
            viewController = AppearanceChoosingViewController()
        case .ThemeColorCell:
            viewController = ThemeColorChoosingViewController()
        case .FirstWeekdayCell:
            viewController = FirstWeekdayChoosingViewController()
        case .ShowRemindersInCalendarViewCell:
            viewController = ShowRemindersInCalendarViewOptionsChoosingViewController()
        case .ShowRemindersInSingleDayItemsViewCell:
            viewController = ShowRemindersInSingleDayItemsViewOptionsChoosingViewController()
        case .EventCalendarsCell:
            viewController = EventCalendarsViewController()
        case .DefaultEventCalendarCell:
            viewController = DefaultEventCalendarChoosingViewController()
        case .ReminderListsCell:
            viewController = ReminderListsViewController()
        case .DefaultReminderListCell:
            viewController = DefaultReminderListChoosingViewController()
        default:
            break
        }
        
        guard let viewController else { return }
        
        navigationController?.pushViewController(viewController, animated: true)
    }
}
