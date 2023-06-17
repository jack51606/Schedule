import UIKit
import EventKit
import CalendarKit
import CustomNavigationController

final class ReminderEditingViewController: CustomNavigationChildViewController {
    
    // MARK: - Private Properties
    
    private enum Mode {
        case create, edit
    }
    private let mode: Mode
    private let calendarItemsManager = CalendarItemsManager.shared
    private var calendar: Calendar {
        return CalendarPreferenceManager.shared.calendar
    }
    private let reminder: EKReminder
    private let snapshotList: EKCalendar
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .navigationBarButton
        return label
    }()
    private let cancelButton: UIButton = {
        
        let button = UIButton()
        
        var configuration = UIButton.Configuration.plain()
        
        var attributedTitle = AttributedString(Strings.cancel)
        attributedTitle.font = .navigationBarButton
        configuration.attributedTitle = attributedTitle
        
        configuration.contentInsets.leading = 0
        button.configuration = configuration
        
        return button
    }()
    private let doneButton: UIButton = {
        
        let button = UIButton()
        
        var configuration = UIButton.Configuration.plain()
        
        var attributedTitle = AttributedString(Strings.done)
        attributedTitle.font = .navigationBarButton
        configuration.attributedTitle = attributedTitle
        
        configuration.contentInsets.trailing = 0
        button.configuration = configuration
        
        return button
    }()
    
    private var collectionView: UICollectionView!
    
    private let dateSwitch: UISwitch = {
        let `switch` = UISwitch()
        `switch`.onTintColor = .tintColor
        return `switch`
    }()
    private let datePicker: UIDatePicker = {
        let picker = UIDatePicker()
        picker.datePickerMode = .date
        picker.preferredDatePickerStyle = .compact
        return picker
    }()
    private let timeSwitch: UISwitch = {
        let `switch` = UISwitch()
        `switch`.onTintColor = .tintColor
        return `switch`
    }()
    private let timePicker: UIDatePicker = {
        let picker = UIDatePicker()
        picker.datePickerMode = .time
        picker.preferredDatePickerStyle = .compact
        return picker
    }()
    private let endRepeatSwitch: UISwitch = {
        let `switch` = UISwitch()
        `switch`.onTintColor = .tintColor
        return `switch`
    }()
    private let endRepeatDatePicker: UIDatePicker = {
        let picker = UIDatePicker()
        picker.datePickerMode = .date
        picker.preferredDatePickerStyle = .compact
        return picker
    }()
    
    private enum CellName: String, CaseIterable {
        
        case BlankCell
        case ListCell
        case TitleCell
        case NotesCell
        case DateCell
        case TimeCell
        case RepeatCell
        case EndRepeatCell
        case PriorityCell
        case DeleteCell
        
        var tag: Int {
            switch self {
            case .BlankCell:
                return 0
            case .ListCell:
                return 1
            case .TitleCell:
                return 2
            case .NotesCell:
                return 3
            case .DateCell:
                return 4
            case .TimeCell:
                return 5
            case .RepeatCell:
                return 6
            case .EndRepeatCell:
                return 7
            case .PriorityCell:
                return 8
            case .DeleteCell:
                return 9
            }
        }
    }
    
    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .secondarySystemBackground
        
        parent?.presentationController?.delegate = self
        
        setNavigationItems()
        setComponents()
        setCollectionView()
    }
    
    // MARK: - Public Methods
    
    public init(reminder: EKReminder) {
        
        self.reminder = reminder
        self.mode = reminder.isNew ? .create : .edit
        self.snapshotList = reminder.calendar
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func reloadItem(at indexPath: IndexPath) {
        
        collectionView.reloadItems(at: [indexPath])
    }
    
    public func checkAndSetDoneButtonEnabled() {
        
        let noTitle = reminder.title == nil || reminder.title.isEmpty
        if noTitle {
            doneButton.isEnabled = false
        } else {
            if reminder.isNew {
                doneButton.isEnabled = true
            } else if reminder.hasChanges {
                doneButton.isEnabled = true
            } else {
                doneButton.isEnabled = false
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func setNavigationItems() {
        
        navigationBar.backgroundColor = view.backgroundColor
        
        titleLabel.text = mode == .create ? Strings.newReminder : Strings.editReminder
        cancelButton.addTarget(self, action: #selector(cancelButtonPressed), for: .touchUpInside)
        doneButton.addTarget(self, action: #selector(doneButtonPressed), for: .touchUpInside)
        
        customNavigationItem.titleView = titleLabel
        customNavigationItem.rightBarButtonItem = UIBarButtonItem(customView: doneButton)
        customNavigationItem.leftBarButtonItem = UIBarButtonItem(customView: cancelButton)
        doneButton.isEnabled = false
    }
    
    private func setComponents() {
        
        func reconfigureDateCellAccessories() {
            guard let indexPath = indexPathForCell(name: .DateCell) else { return }
            guard let dateCell = collectionView.cellForItem(at: indexPath) as? UICollectionViewListCell else { return }
            
            let dateSwitchAccessoryViewConfiguration = UICellAccessory.CustomViewConfiguration(customView: dateSwitch, placement: .trailing(), reservedLayoutWidth: .actual)
            
            let datePickerAccessoryViewConfiguration = UICellAccessory.CustomViewConfiguration(customView: datePicker, placement: .trailing(), reservedLayoutWidth: .actual)
            
            dateCell.accessories = reminder.dueDateComponents?.date != nil ? [.customView(configuration: datePickerAccessoryViewConfiguration), .customView(configuration: dateSwitchAccessoryViewConfiguration)] : [.customView(configuration: dateSwitchAccessoryViewConfiguration)]
        }
        func reconfigureTimeCellAccessories() {
            guard let indexPath = indexPathForCell(name: .TimeCell) else { return }
            guard let timeCell = collectionView.cellForItem(at: indexPath) as? UICollectionViewListCell else { return }
            
            let timeSwitchAccessoryViewConfiguration = UICellAccessory.CustomViewConfiguration(customView: timeSwitch, placement: .trailing(), reservedLayoutWidth: .actual)
            
            let timePickerAccessoryViewConfiguration = UICellAccessory.CustomViewConfiguration(customView: timePicker, placement: .trailing(), reservedLayoutWidth: .actual)
            
            timeCell.accessories = reminder.dueDateComponents?.hour != nil ? [.customView(configuration: timePickerAccessoryViewConfiguration), .customView(configuration: timeSwitchAccessoryViewConfiguration)] : [.customView(configuration: timeSwitchAccessoryViewConfiguration)]
        }
        
        dateSwitch.isOn = reminder.dueDateComponents?.date != nil
        dateSwitch.addAction(UIAction(handler: { [weak self] _ in
            guard let self else { return }
            
            if dateSwitch.isOn {
                reminder.dueDateComponents = defaultDateComponents(withTime: false)
                datePicker.date = reminder.dueDateComponents!.date!
            } else {
                reminder.dueDateComponents = nil
                reminder.recurrenceRules = []
                timeSwitch.setOn(false, animated: true)
                reconfigureTimeCellAccessories()
            }
            
            reconfigureDateCellAccessories()
            
            collectionView.reloadSections([3])
            checkAndSetDoneButtonEnabled()
            
        }), for: .valueChanged)
        
        datePicker.calendar = calendar
        datePicker.date = defaultDate(withTime: false)
        datePicker.addAction(UIAction(handler: { [weak self] _ in
            guard let self else { return }
            
            let year = calendar.component(.year, from: datePicker.date)
            let month = calendar.component(.month, from: datePicker.date)
            let day = calendar.component(.day, from: datePicker.date)
            
            reminder.dueDateComponents?.year = year
            reminder.dueDateComponents?.month = month
            reminder.dueDateComponents?.day = day
            
            checkAndSetDoneButtonEnabled()
            
        }), for: .valueChanged)
        
        timeSwitch.isOn = reminder.dueDateComponents?.hour != nil
        timeSwitch.addAction(UIAction(handler: { [weak self] _ in
            guard let self else { return }
            
            if timeSwitch.isOn {
                var roundedTime: Date {
                    var date = Date()
                    while (self.calendar.component(.minute, from: date) + 1) % 5 != 0 {
                        date = self.calendar.date(byAdding: .minute, value: 1, to: date)!
                    }
                    date = self.calendar.date(byAdding: .minute, value: 1, to: date)!
                    return date
                }
                let hour = calendar.component(.hour, from: roundedTime)
                let minute = calendar.component(.minute, from: roundedTime)
                if reminder.dueDateComponents?.date != nil {
                    reminder.dueDateComponents?.hour = hour
                    reminder.dueDateComponents?.minute = minute
                } else {
                    reminder.dueDateComponents = defaultDateComponents(withTime: true)
                    dateSwitch.setOn(true, animated: true)
                    reconfigureDateCellAccessories()
                }
                
                timePicker.date = reminder.dueDateComponents!.date!
                
            } else {
                
                reminder.dueDateComponents?.hour = nil
                reminder.dueDateComponents?.minute = nil
                reminder.dueDateComponents?.second = nil
                reminder.dueDateComponents?.nanosecond = nil
            }
            
            reconfigureTimeCellAccessories()
            
            collectionView.reloadSections([3])
            checkAndSetDoneButtonEnabled()
            
        }), for: .valueChanged)
        
        timePicker.calendar = calendar
        if let date = reminder.dueDateComponents?.date, reminder.dueDateComponents?.hour != nil {
            timePicker.date = date
        }
        timePicker.addAction(UIAction(handler: { [weak self] _ in
            guard let self else { return }
            
            reminder.dueDateComponents?.hour = calendar.component(.hour, from: timePicker.date)
            reminder.dueDateComponents?.minute = calendar.component(.minute, from: timePicker.date)
            reminder.dueDateComponents?.second = nil
            reminder.dueDateComponents?.nanosecond = nil
            
            checkAndSetDoneButtonEnabled()
            
        }), for: .valueChanged)
        
        endRepeatSwitch.isOn = reminder.recurrenceRules?.first?.recurrenceEnd?.endDate != nil
        endRepeatSwitch.addAction(UIAction(handler: { [weak self] _ in
            guard let self else { return }
            
            if endRepeatSwitch.isOn {
                
            } else {
                
            }
            
        }), for: .valueChanged)
        
        endRepeatDatePicker.calendar = calendar
        if let date = reminder.dueDateComponents?.date {
            endRepeatDatePicker.date = date
        }
//        endRepeatDatePicker.addAction(<#T##action: UIAction##UIAction#>, for: <#T##UIControl.Event#>)
    }
    
    private func setCollectionView() {
        
        var configuration = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
        configuration.backgroundColor = .clear
        configuration.headerMode = .supplementary
        let layout = UICollectionViewCompositionalLayout.list(using: configuration)
        
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(UICollectionViewListCell.self, forCellWithReuseIdentifier: UICollectionViewListCell.self.description())
        collectionView.contentInset.top = 20
        collectionView.contentInset.bottom = 60
        collectionView.backgroundColor = .clear
        
        view.addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
    
    private func cellName(at indexPath: IndexPath) -> CellName {
        
        switch indexPath {
            
        case IndexPath(item: 0, section: 0):
            return .ListCell
        case IndexPath(item: 0, section: 1):
            return .TitleCell
        case IndexPath(item: 1, section: 1):
            return .NotesCell
        case IndexPath(item: 0, section: 2):
            return .DateCell
        case IndexPath(item: 1, section: 2):
            return .TimeCell
        case IndexPath(item: 0, section: 3):
            return .RepeatCell
        case IndexPath(item: 1, section: 3):
            return .EndRepeatCell
        case IndexPath(item: 0, section: 4):
            return .PriorityCell
        case IndexPath(item: 0, section: 5):
            return .DeleteCell
            
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
    
    private func defaultDate(withTime: Bool) -> Date {
        
        var selectedDate: Date? {
            guard let mainController = parent?.presentationController?.presentingViewController as? MainController else { return nil }
            guard let homeViewController = mainController.pages[0]?.rootViewController as? HomeViewController else { return nil }
            return homeViewController.selectedDate
        } // 必定為午夜 12:00
        
        var roundedTime: Date {
            var date = Date()
            while (calendar.component(.minute, from: date) + 1) % 5 != 0 {
                date = calendar.date(byAdding: .minute, value: 1, to: date)!
            }
            date = calendar.date(byAdding: .minute, value: 1, to: date)!
            return date
        }
        let hour = calendar.component(.hour, from: roundedTime) // Int
        let minute = calendar.component(.minute, from: roundedTime) // Int
        
        if let selectedDate {
            if withTime {
                return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: selectedDate)!
            } else {
                return selectedDate
            }
        } else {
            if withTime {
                return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: Date())!
            } else {
                return calendar.startOfDay(for: Date())
            }
        }
    }
    
    private func defaultDateComponents(withTime: Bool) -> DateComponents {
        
        let date = defaultDate(withTime: withTime)
        
        var components = calendar.dateComponents(in: calendar.timeZone, from: date)
        if !withTime {
            components.hour = nil
            components.minute = nil
        }
        components.second = nil
        components.nanosecond = nil
        
        return components
    }
    
    @objc private func cancelButtonPressed() {
        
        if mode == .edit {
            reminder.reset()
        } else {
            calendarItemsManager.delete(reminder)
        }
        
        dismiss(animated: true)
    }
    
    @objc private func doneButtonPressed() {
        
        calendarItemsManager.save(reminder)
        
        dismiss(animated: true)
    }
    
    @objc private func titleTextFieldTextDidChange(_ sender: UITextField) {
        guard let text = sender.text else { return }
        
        reminder.title = text
        checkAndSetDoneButtonEnabled()
    }
}

extension ReminderEditingViewController: UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        
        if mode == .create {
            return 5
        } else {
            return 6
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        switch section {
        case 0:
            return 1
        case 1:
            return 2
        case 2:
            return 2
        case 3:
            return reminder.hasRecurrenceRules ? 2 : 1
        case 4:
            return 1
        case 5:
            return 1
        default:
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: UICollectionViewListCell.self.description(), for: indexPath) as! UICollectionViewListCell
        
        let cellName = cellName(at: indexPath)
        
        switch cellName {
        case .BlankCell:
            break
        case .ListCell: // MARK: List Cell
            
            var configuration = cell.defaultContentConfiguration()
            configuration.textProperties.font = .rounded(ofSize: configuration.textProperties.font.pointSize)
            configuration.secondaryTextProperties.font = .rounded(ofSize: 18)
            configuration.secondaryTextProperties.color = .secondaryLabel
            configuration.prefersSideBySideTextAndSecondaryText = true
            
            configuration.text = Strings.list
            var attributedString: NSAttributedString {
                let attributedString = NSMutableAttributedString()
                let image = Constants.SFSymbols.circlebadgeFill.withConfiguration(UIImage.SymbolConfiguration(scale: .small)).withTintColor(UIColor(cgColor: reminder.calendar.cgColor))
                let colorIcon = NSAttributedString(attachment: NSTextAttachment(image: image))
                let space = NSAttributedString(string: Strings.space)
                let calendarTitle = NSAttributedString(string: reminder.calendar.title)
                attributedString.append(colorIcon)
                attributedString.append(space)
                attributedString.append(space)
                attributedString.append(calendarTitle)
                return attributedString
            }
            configuration.secondaryAttributedText = attributedString
            
            cell.contentConfiguration = configuration
            
            cell.accessories = [.disclosureIndicator()]
            
        case .TitleCell: // MARK: Title Cell
            
            var configuration = TextFieldConfiguration()
            
            configuration.textField.tag = cellName.tag
            
            configuration.textField.delegate = self
            configuration.textField.clearButtonMode = .whileEditing
            configuration.textField.returnKeyType = .done
            
            configuration.textField.addTarget(self, action: #selector(titleTextFieldTextDidChange), for: .editingChanged)
            
            configuration.contentInsets.leading = 20
            configuration.contentInsets.trailing = 20
            configuration.height = 48
            configuration.textField.font = .rounded(ofSize: 19)
            
            configuration.textField.placeholder = Strings.title
            configuration.textField.text = reminder.title
            if reminder.isNew {
                configuration.textField.becomeFirstResponder()
            }
            
            cell.contentConfiguration = configuration
            
        case .NotesCell: // MARK: Notes Cell
            
            var configuration = TextViewConfiguration()
            
            configuration.textView.backgroundColor = .clear
            configuration.textView.tag = cellName.tag
            
            configuration.textView.delegate = self
            
            configuration.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 20, bottom: 12, trailing: 20)
            configuration.textView.textContainer.lineFragmentPadding = 0
            configuration.textView.textContainerInset = .zero
            configuration.textView.textContainer.lineBreakMode = .byTruncatingTail
            configuration.textView.isScrollEnabled = false
            configuration.textView.textContainer.maximumNumberOfLines = 5
            configuration.textView.font = .rounded(ofSize: 19)
            
            configuration.textView.placeholder = Strings.notes
            configuration.textView.text = reminder.notes
            
            cell.contentConfiguration = configuration
            
        case .DateCell: // MARK: Date Cell
            
            var configuration = cell.defaultContentConfiguration()
            configuration.textProperties.font = .rounded(ofSize: configuration.textProperties.font.pointSize)
            
            configuration.text = Strings.date
            
            cell.contentConfiguration = configuration
            
            let dateSwitchAccessoryViewConfiguration = UICellAccessory.CustomViewConfiguration(customView: dateSwitch, placement: .trailing(), reservedLayoutWidth: .actual)
            
            let datePickerAccessoryViewConfiguration = UICellAccessory.CustomViewConfiguration(customView: datePicker, placement: .trailing(), reservedLayoutWidth: .actual)
            
            cell.accessories = reminder.dueDateComponents?.date != nil ? [.customView(configuration: datePickerAccessoryViewConfiguration), .customView(configuration: dateSwitchAccessoryViewConfiguration)] : [.customView(configuration: dateSwitchAccessoryViewConfiguration)]
            
        case .TimeCell: // MARK: Time Cell
            
            var configuration = cell.defaultContentConfiguration()
            configuration.textProperties.font = .rounded(ofSize: configuration.textProperties.font.pointSize)
            
            configuration.text = Strings.time
            
            cell.contentConfiguration = configuration
            
            let timeSwitchAccessoryViewConfiguration = UICellAccessory.CustomViewConfiguration(customView: timeSwitch, placement: .trailing(), reservedLayoutWidth: .actual)
            
            let timePickerAccessoryViewConfiguration = UICellAccessory.CustomViewConfiguration(customView: timePicker, placement: .trailing(), reservedLayoutWidth: .actual)
            
            cell.accessories = reminder.dueDateComponents?.hour != nil ? [.customView(configuration: timePickerAccessoryViewConfiguration), .customView(configuration: timeSwitchAccessoryViewConfiguration)] : [.customView(configuration: timeSwitchAccessoryViewConfiguration)]
            
        case .RepeatCell: // MARK: Repeat Cell
            
            var configuration = cell.defaultContentConfiguration()
            configuration.textProperties.font = .rounded(ofSize: configuration.textProperties.font.pointSize)
            
            configuration.text = Strings.repeat
            
            cell.contentConfiguration = configuration
            
            let repeatButton = UIButton()
            var repeatButtonConfiguration = UIButton.Configuration.plain()
            repeatButtonConfiguration.contentInsets = .zero
            repeatButtonConfiguration.baseForegroundColor = .secondaryLabel
            repeatButton.configuration = repeatButtonConfiguration
            repeatButton.showsMenuAsPrimaryAction = true
            repeatButton.changesSelectionAsPrimaryAction = true
            repeatButton.isEnabled = reminder.dueDateComponents?.date != nil
            
            var menu: UIMenu {
                let children: [UIAction] = [
                    UIAction(title: Strings.never, handler: { [weak self] _ in
                        guard let self else { return }
                        reminder.recurrenceRules = nil
                        let accessory = cell.accessories[0]
                        cell.accessories = []
                        cell.accessories = [accessory]
                        collectionView.reloadSections([3])
                        checkAndSetDoneButtonEnabled()
                    }),
                    UIAction(title: Strings.everyDay, handler: { [weak self] _ in
                        guard let self else { return }
                        reminder.recurrenceRules = [EKRecurrenceRule(recurrenceWith: .daily, interval: 1, end: nil)]
                        let accessory = cell.accessories[0]
                        cell.accessories = []
                        cell.accessories = [accessory]
                        collectionView.reloadSections([3])
                        checkAndSetDoneButtonEnabled()
                    }),
                    UIAction(title: Strings.everyWeek, handler: { [weak self] _ in
                        guard let self else { return }
                        reminder.recurrenceRules = [EKRecurrenceRule(recurrenceWith: .weekly, interval: 1, end: nil)]
                        let accessory = cell.accessories[0]
                        cell.accessories = []
                        cell.accessories = [accessory]
                        collectionView.reloadSections([3])
                        checkAndSetDoneButtonEnabled()
                    }),
                    UIAction(title: Strings.every2Weeks, handler: { [weak self] _ in
                        guard let self else { return }
                        reminder.recurrenceRules = [EKRecurrenceRule(recurrenceWith: .weekly, interval: 2, end: nil)]
                        let accessory = cell.accessories[0]
                        cell.accessories = []
                        cell.accessories = [accessory]
                        collectionView.reloadSections([3])
                        checkAndSetDoneButtonEnabled()
                    }),
                    UIAction(title: Strings.everyMonth, handler: { [weak self] _ in
                        guard let self else { return }
                        reminder.recurrenceRules = [EKRecurrenceRule(recurrenceWith: .monthly, interval: 1, end: nil)]
                        let accessory = cell.accessories[0]
                        cell.accessories = []
                        cell.accessories = [accessory]
                        collectionView.reloadSections([3])
                        checkAndSetDoneButtonEnabled()
                    }),
                    UIAction(title: Strings.everyYear, handler: { [weak self] _ in
                        guard let self else { return }
                        reminder.recurrenceRules = [EKRecurrenceRule(recurrenceWith: .yearly, interval: 1, end: nil)]
                        let accessory = cell.accessories[0]
                        cell.accessories = []
                        cell.accessories = [accessory]
                        collectionView.reloadSections([3])
                        checkAndSetDoneButtonEnabled()
                    })
                ]
                if !reminder.hasRecurrenceRules {
                    children[0].state = .on
                } else {
                    switch reminder.recurrenceRules![0].frequency {
                    case .daily:
                        children[1].state = .on
                    case .weekly:
                        if reminder.recurrenceRules![0].interval == 1 {
                            children[2].state = .on
                        } else {
                            children[3].state = .on
                        }
                    case .monthly:
                        children[4].state = .on
                    case .yearly:
                        children[5].state = .on
                    default:
                        break
                    }
                }
                return UIMenu(children: children)
            }
            repeatButton.menu = menu
            
            let repeatButtonAccessoryViewConfiguration = UICellAccessory.CustomViewConfiguration(customView: repeatButton, placement: .trailing())
            
            cell.accessories = [.customView(configuration: repeatButtonAccessoryViewConfiguration)]
            
        case .EndRepeatCell: // MARK: End Repeat Cell
            
            var configuration = cell.defaultContentConfiguration()
            configuration.textProperties.font = .rounded(ofSize: configuration.textProperties.font.pointSize)
            
            configuration.text = Strings.endRepeat
            
            cell.contentConfiguration = configuration
            
            let endRepeatSwitchAccessoryViewConfiguration = UICellAccessory.CustomViewConfiguration(customView: endRepeatSwitch, placement: .trailing(), reservedLayoutWidth: .actual)
            
            let endRepeatDatePickerAccessoryViewConfiguration = UICellAccessory.CustomViewConfiguration(customView: endRepeatDatePicker, placement: .trailing(), reservedLayoutWidth: .actual)
            
            cell.accessories = [.customView(configuration: endRepeatDatePickerAccessoryViewConfiguration), .customView(configuration: endRepeatSwitchAccessoryViewConfiguration)]
            
        case .PriorityCell:
            break
        case .DeleteCell: // MARK: Delete Cell
            
            var configuration = LabelConfiguration()
            
            configuration.height = 48
            configuration.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20)
            configuration.label.font = .rounded(ofSize: 19)
            configuration.label.textColor = .systemRed
            configuration.label.textAlignment = .center
            configuration.label.text = Strings.deleteReminder
            
            cell.contentConfiguration = configuration
        }
        
        var backgroundConfiguration = cell.backgroundConfiguration
        backgroundConfiguration?.backgroundColor = .tertiarySystemBackground
        cell.backgroundConfiguration = backgroundConfiguration
        
        cell.tag = cellName.tag
        
        return cell
    }
}

extension ReminderEditingViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        collectionView.deselectItem(at: indexPath, animated: true)
        
        let cellName = cellName(at: indexPath)
        
        switch cellName {
        case .ListCell:
            navigationController?.pushViewController(ReminderListChoosingViewController(reminder: reminder), animated: true)
        case .DeleteCell:
            
            let alertTitle = Strings.sureToDelete + Strings.space + Strings.this.lowercased() + Strings.space + Strings.reminder.lowercased() + Strings.questionMark
            let alert = UIAlertController(title: alertTitle, message: nil, preferredStyle: .actionSheet)
            let deleteAction = UIAlertAction(title: Strings.deleteReminder, style: .destructive) { [weak self] _ in
                guard let self else { return }
                
                calendarItemsManager.delete(reminder)
                
                dismiss(animated: true)
            }
            
            let cancelAction = UIAlertAction(title: Strings.cancel, style: .cancel)
            
            alert.addAction(deleteAction)
            alert.addAction(cancelAction)
            present(alert, animated: true)
            
        default:
            break
        }
    }
}

extension ReminderEditingViewController: UIAdaptivePresentationControllerDelegate {
    
    func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        
        // 隱藏鍵盤
        view.endEditing(true)
        
        switch mode {
        case .create:
            let listUnchanged = reminder.calendar == snapshotList
            let noTitle = reminder.title == nil || reminder.title.isEmpty
            let noNotes = !reminder.hasNotes
            let noDueDate = reminder.dueDateComponents?.date == nil
            let noRepeat = !reminder.hasRecurrenceRules
            let noPriority = reminder.priority == 0
            if listUnchanged, noTitle, noNotes, noDueDate, noRepeat, noPriority {
                return true
            } else {
                return false
            }
        case .edit:
            return !reminder.hasChanges
        }
    }
    
    func presentationControllerDidAttemptToDismiss(_ presentationController: UIPresentationController) {
        
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let discardAction = UIAlertAction(title: Strings.discardChanges, style: .destructive) { [weak self] _ in
            guard let self else { return }
            
            if mode == .edit {
                reminder.reset()
            } else {
                calendarItemsManager.delete(reminder)
            }
            
            dismiss(animated: true)
        }
        let cancelAction = UIAlertAction(title: Strings.cancel, style: .cancel)
        alert.addAction(discardAction)
        alert.addAction(cancelAction)
        present(alert, animated: true)
    }
    
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        
        if reminder.isNew {
            calendarItemsManager.delete(reminder)
        }
    }
}

extension ReminderEditingViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        textField.resignFirstResponder()
        
        return true
    }
}

extension ReminderEditingViewController: UITextViewDelegate {
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        
        textView.textContainer.maximumNumberOfLines = 0
        let text = textView.text
        textView.text = Strings.empty
        textView.text = text
        collectionView.performBatchUpdates(nil)
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        
        textView.textContainer.maximumNumberOfLines = 5
        let text = textView.text
        textView.text = Strings.empty
        textView.text = text
        collectionView.performBatchUpdates(nil)
    }
    
    func textViewDidChange(_ textView: UITextView) {
        
        reminder.notes = textView.text
        
        checkAndSetDoneButtonEnabled()
        
        collectionView.performBatchUpdates(nil)
    }
}
