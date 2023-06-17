import UIKit
import MapKit
import EventKit
import CalendarKit
import CustomNavigationController

final class EventEditingViewController: CustomNavigationChildViewController {
    
    // MARK: - Private Properties
    
    private enum Mode {
        case create, edit
    }
    private let mode: Mode
    
    private let calendarItemsManager = CalendarItemsManager.shared
    private var calendar: Calendar {
        return CalendarPreferenceManager.shared.calendar
    }
    private let event: EKEvent
    private let snapshotCalendar: EKCalendar
    private let snapshotStartDate: Date
    private let snapshotEndDate: Date
    
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
    
    private enum CellName: String, CaseIterable {
        
        case BlankCell
        case CalendarCell
        case TitleCell
        case LocationCell
        case URLCell
        case NotesCell
        case AllDayCell
        case StartDateCell
        case EndDateCell
        case RepeatCell
        case EndRepeatCell
        case DeleteCell
        
        var tag: Int {
            switch self {
            case .BlankCell:
                return 0
            case .CalendarCell:
                return 1
            case .TitleCell:
                return 2
            case .LocationCell:
                return 3
            case .URLCell:
                return 4
            case .NotesCell:
                return 5
            case .AllDayCell:
                return 6
            case .StartDateCell:
                return 7
            case .EndDateCell:
                return 8
            case .RepeatCell:
                return 9
            case .EndRepeatCell:
                return 10
            case .DeleteCell:
                return 11
            }
        }
    }
    
    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .secondarySystemBackground
        
        parent?.presentationController?.delegate = self
        
        setNavigationItems()
        setCollectionView()
    }
    
    // MARK: - Public Methods
    
    public init(event: EKEvent) {
        
        self.event = event
        self.mode = event.isNew ? .create : .edit
        self.snapshotCalendar = event.calendar
        self.snapshotStartDate = event.startDate
        self.snapshotEndDate = event.endDate
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func reloadItem(at indexPath: IndexPath) {
        
        collectionView.reloadItems(at: [indexPath])
    }
    
    public func checkAndSetDoneButtonEnabled() {
        
        let noTitle = event.title == nil || event.title.isEmpty
        let noValidDate = event.startDate == nil || event.endDate == nil
        if noTitle || noValidDate {
            doneButton.isEnabled = false
        } else {
            if event.isNew {
                doneButton.isEnabled = true
            } else if event.hasChanges {
                doneButton.isEnabled = true
            } else {
                doneButton.isEnabled = false
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func setNavigationItems() {
        
        navigationBar.backgroundColor = view.backgroundColor
        
        titleLabel.text = mode == .create ? Strings.newEvent : Strings.editEvent
        cancelButton.addTarget(self, action: #selector(cancelButtonPressed), for: .touchUpInside)
        doneButton.addTarget(self, action: #selector(doneButtonPressed), for: .touchUpInside)
        
        customNavigationItem.titleView = titleLabel
        customNavigationItem.rightBarButtonItem = UIBarButtonItem(customView: doneButton)
        
        if event.calendar.allowsContentModifications {
            customNavigationItem.leftBarButtonItem = UIBarButtonItem(customView: cancelButton)
            doneButton.isEnabled = false
        }
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
            return .CalendarCell
        case IndexPath(item: 0, section: 1):
            return .TitleCell
        case IndexPath(item: 1, section: 1):
            return .LocationCell
        case IndexPath(item: 0, section: 2):
            return .URLCell
        case IndexPath(item: 1, section: 2):
            return .NotesCell
        case IndexPath(item: 0, section: 3):
            return .AllDayCell
        case IndexPath(item: 1, section: 3):
            return .StartDateCell
        case IndexPath(item: 2, section: 3):
            return .EndDateCell
        case IndexPath(item: 0, section: 4):
            return .RepeatCell
        case IndexPath(item: 1, section: 4):
            return .EndRepeatCell
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
    
    @objc private func cancelButtonPressed() {
        
        if mode == .edit {
            event.reset()
        } else {
            calendarItemsManager.delete(event)
        }
        
        dismiss(animated: true)
    }
    
    @objc private func doneButtonPressed() {
        
        if event.calendar.allowsContentModifications {
            
            let span: EKSpan = event.hasRecurrenceRules ? .futureEvents : .thisEvent
            calendarItemsManager.save(event, span: span)
        }
        
        dismiss(animated: true)
    }
    
    @objc private func titleTextFieldTextDidChange(_ sender: UITextField) {
        guard let text = sender.text else { return }
        
        event.title = text
        checkAndSetDoneButtonEnabled()
    }
    
    @objc private func urlTextFieldTextDidChange(_ sender: UITextField) {
        guard let text = sender.text else { return }
        
        event.url = URL(string: text)
        checkAndSetDoneButtonEnabled()
        
        guard let indexPath = indexPathForCell(name: .URLCell) else { return }
        guard let cell = collectionView.cellForItem(at: indexPath) as? UICollectionViewListCell else { return }
        guard let openLinkButton = cell.viewWithTag(CellName.URLCell.tag + 1) as? UIButton else { return }
        
        if let url = event.url, !url.absoluteString.isEmpty {
            var fullUrl: URL? {
                let prefix = "https://"
                if !url.absoluteString.hasPrefix(prefix) {
                    return URL(string: prefix + url.absoluteString)
                } else {
                    return url
                }
            }
            if let fullUrl {
                openLinkButton.isEnabled = UIApplication.shared.canOpenURL(fullUrl)
            } else {
                openLinkButton.isEnabled = false
            }
        } else {
            openLinkButton.isEnabled = false
        }
    }
}

extension EventEditingViewController: UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        
        if mode == .create || !event.calendar.allowsContentModifications {
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
            return 3
        case 4:
            return event.hasRecurrenceRules ? 2 : 1
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
        case .CalendarCell: // MARK: Calendar Cell
            
            var configuration = cell.defaultContentConfiguration()
            configuration.textProperties.font = .rounded(ofSize: configuration.textProperties.font.pointSize)
            configuration.secondaryTextProperties.font = .rounded(ofSize: 18)
            configuration.secondaryTextProperties.color = .secondaryLabel
            configuration.prefersSideBySideTextAndSecondaryText = true
            
            configuration.text = Strings.calendar
            var attributedString: NSAttributedString {
                let attributedString = NSMutableAttributedString()
                let image = Constants.SFSymbols.circlebadgeFill.withConfiguration(UIImage.SymbolConfiguration(scale: .small)).withTintColor(UIColor(cgColor: event.calendar.cgColor))
                let colorIcon = NSAttributedString(attachment: NSTextAttachment(image: image))
                let space = NSAttributedString(string: Strings.space)
                let calendarTitle = NSAttributedString(string: event.calendar.title)
                attributedString.append(colorIcon)
                attributedString.append(space)
                attributedString.append(space)
                attributedString.append(calendarTitle)
                return attributedString
            }
            configuration.secondaryAttributedText = attributedString
            
            cell.contentConfiguration = configuration
            
            if event.calendar.allowsContentModifications {
                cell.accessories = [.disclosureIndicator()]
            }
            
        case .TitleCell: // MARK: Title Cell
            
            var configuration = TextFieldConfiguration()
            
            configuration.textField.tag = cellName.tag
            
            configuration.textField.isEnabled = event.calendar.allowsContentModifications
            
            configuration.textField.delegate = self
            configuration.textField.clearButtonMode = .whileEditing
            configuration.textField.returnKeyType = .done
            
            configuration.textField.addTarget(self, action: #selector(titleTextFieldTextDidChange), for: .editingChanged)
            
            configuration.contentInsets.leading = 20
            configuration.contentInsets.trailing = 20
            configuration.height = 48
            configuration.textField.font = .rounded(ofSize: 19)
            
            configuration.textField.placeholder = Strings.title
            configuration.textField.text = event.title
            if event.isNew {
                configuration.textField.becomeFirstResponder()
            }
            
            cell.contentConfiguration = configuration
            
        case .LocationCell: // MARK: Location Cell
            
            var configuration = cell.defaultContentConfiguration()
            
            configuration.textProperties.font = .rounded(ofSize: configuration.textProperties.font.pointSize)
            configuration.secondaryTextProperties.font = .rounded(ofSize: configuration.secondaryTextProperties.font.pointSize)
            configuration.secondaryTextProperties.color = .secondaryLabel
            
            if let fullLocation = event.location {
                if let title = event.structuredLocation?.title {
                    configuration.text = title
                    if fullLocation.hasPrefix(title) {
                        let address = String(fullLocation.dropFirst(title.count + 1))
                        configuration.secondaryText = address
                    } else {
                        configuration.secondaryText = fullLocation
                    }
                } else {
                    configuration.secondaryText = fullLocation
                }
            } else {
                configuration.textProperties.color = .placeholderText
                configuration.text = Strings.location
            }
            
            cell.contentConfiguration = configuration
            
            let clearButton = UIButton()
            clearButton.setImage(Constants.SFSymbols.xmarkCircleFill.withTintColor(.placeholderText, renderingMode: .alwaysOriginal), for: .normal)
            clearButton.addAction(UIAction(handler: { [weak self] _ in
                guard let self else { return }
                event.location = nil
                UIView.performWithoutAnimation {
                    collectionView.reloadItems(at: [indexPath])
                }
                checkAndSetDoneButtonEnabled()
            }), for: .touchUpInside)
            let clearButtonAccessoryViewConfiguration = UICellAccessory.CustomViewConfiguration(customView: clearButton, placement: .trailing(), isHidden: !event.calendar.allowsContentModifications || event.location == nil)
            
            let openInMapButton = UIButton()
            openInMapButton.setImage(Constants.SFSymbols.mapPin, for: .normal)
            openInMapButton.isEnabled = event.structuredLocation?.geoLocation != nil
            openInMapButton.addAction(UIAction(handler: { [weak self] _ in
                guard let self else { return }
                if let structuredLocation = event.structuredLocation, let location = structuredLocation.geoLocation {
                    let item = MKMapItem(placemark: MKPlacemark(coordinate: location.coordinate))
                    item.name = event.structuredLocation?.title
                    item.openInMaps()
                }
            }), for: .touchUpInside)
            
            let openInMapButtonAccessoryViewConfiguration = UICellAccessory.CustomViewConfiguration(customView: openInMapButton, placement: .trailing())
            
            cell.accessories = [.customView(configuration: clearButtonAccessoryViewConfiguration), .customView(configuration: openInMapButtonAccessoryViewConfiguration)]
            
        case .URLCell: // MARK: URL Cell
            
            var configuration = TextFieldConfiguration()
            
            configuration.textField.tag = cellName.tag
            
            configuration.textField.isEnabled = event.calendar.allowsContentModifications
            
            configuration.textField.delegate = self
            configuration.textField.clearButtonMode = .whileEditing
            configuration.textField.keyboardType = .URL
            configuration.textField.autocapitalizationType = .none
            configuration.textField.returnKeyType = .done
            
            configuration.textField.addTarget(self, action: #selector(urlTextFieldTextDidChange), for: .editingChanged)
            
            configuration.contentInsets.leading = 20
            configuration.height = 48
            configuration.textField.font = .rounded(ofSize: 19)
            
            configuration.textField.placeholder = Strings.url
            configuration.textField.text = event.url?.absoluteString
            
            cell.contentConfiguration = configuration
            
            let openLinkButton = UIButton()
            openLinkButton.tag = cellName.tag + 1
            openLinkButton.setImage(Constants.SFSymbols.link, for: .normal)
            if let url = event.url, !url.absoluteString.isEmpty {
                var fullUrl: URL? {
                    let prefix = "https://"
                    if !url.absoluteString.hasPrefix(prefix) {
                        return URL(string: prefix + url.absoluteString)
                    } else {
                        return url
                    }
                }
                if let fullUrl {
                    openLinkButton.isEnabled = UIApplication.shared.canOpenURL(fullUrl)
                } else {
                    openLinkButton.isEnabled = false
                }
            } else {
                openLinkButton.isEnabled = false
            }
            openLinkButton.addAction(UIAction(handler: { [weak self] _ in
                guard let self else { return }
                guard let url = event.url else { return }
                var fullUrl: URL? {
                    let prefix = "https://"
                    if !url.absoluteString.hasPrefix(prefix) {
                        return URL(string: prefix + url.absoluteString)
                    } else {
                        return url
                    }
                }
                if let fullUrl {
                    UIApplication.shared.open(fullUrl)
                }
            }), for: .touchUpInside)
            
            let openLinkButtonAccessoryViewConfiguration = UICellAccessory.CustomViewConfiguration(customView: openLinkButton, placement: .trailing())
            
            cell.accessories = [.customView(configuration: openLinkButtonAccessoryViewConfiguration)]
            
        case .NotesCell: // MARK: Notes Cell
            
            var configuration = TextViewConfiguration()
            
            configuration.textView.backgroundColor = .clear
            configuration.textView.tag = cellName.tag
            
            configuration.textView.delegate = self
            configuration.textView.isEditable = event.calendar.allowsContentModifications
            
            configuration.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 20, bottom: 12, trailing: 20)
            configuration.textView.textContainer.lineFragmentPadding = 0
            configuration.textView.textContainerInset = .zero
            configuration.textView.textContainer.lineBreakMode = .byTruncatingTail
            configuration.textView.isScrollEnabled = false
            configuration.textView.textContainer.maximumNumberOfLines = 5
            configuration.textView.font = .rounded(ofSize: 19)
            
            configuration.textView.placeholder = Strings.notes
            configuration.textView.text = event.notes
            
            cell.contentConfiguration = configuration
            
        case .AllDayCell: // MARK: All-Day Cell
            
            var configuration = cell.defaultContentConfiguration()
            configuration.textProperties.font = .rounded(ofSize: configuration.textProperties.font.pointSize)
            
            configuration.text = Strings.allDay
            
            cell.contentConfiguration = configuration
            
            let allDaySwitch = UISwitch()
            allDaySwitch.onTintColor = .tintColor
            allDaySwitch.isOn = event.isAllDay
            allDaySwitch.isEnabled = event.calendar.allowsContentModifications
            allDaySwitch.addAction(UIAction(handler: { [weak self] _ in
                guard let self else { return }
                event.isAllDay = allDaySwitch.isOn
                if !event.isAllDay {
                    let hour = calendar.component(.hour, from: Date())
                    let startDate = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: event.startDate)!
                    event.startDate = startDate
                    let endDate = calendar.date(bySettingHour: hour + 1, minute: 0, second: 0, of: event.endDate)!
                    event.endDate = endDate
                }
                if let startDateCellIndexPath = indexPathForCell(name: .StartDateCell), let endDateCellIndexPath = indexPathForCell(name: .EndDateCell) {
                    reloadItem(at: startDateCellIndexPath)
                    reloadItem(at: endDateCellIndexPath)
                }
                checkAndSetDoneButtonEnabled()
            }), for: .valueChanged)
            
            let allDaySwitchAccessoryViewConfiguration = UICellAccessory.CustomViewConfiguration(customView: allDaySwitch, placement: .trailing())
            
            cell.accessories = [.customView(configuration: allDaySwitchAccessoryViewConfiguration)]
            
        case .StartDateCell: // MARK: Start Date Cell
            
            var configuration = cell.defaultContentConfiguration()
            configuration.textProperties.font = .rounded(ofSize: configuration.textProperties.font.pointSize - 1)
            
            configuration.text = Strings.starts
            
            cell.contentConfiguration = configuration
            
            let startDayPicker = UIDatePicker()
            startDayPicker.datePickerMode = .date
            if let date = event.startDate {
                startDayPicker.date = date
            } else {
                startDayPicker.date = calendar.startOfDay(for: Date())
            }
            startDayPicker.isUserInteractionEnabled = event.calendar.allowsContentModifications
            
            let startTimePicker = UIDatePicker()
            startTimePicker.datePickerMode = .time
            if let time = event.startDate {
                startTimePicker.date = time
            } else {
                let hour = calendar.component(.hour, from: Date())
                let time = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: Date())!
                startTimePicker.date = time
            }
            startTimePicker.isUserInteractionEnabled = event.calendar.allowsContentModifications
            
            startDayPicker.addAction(UIAction(handler: { [weak self] _ in
                guard let self else { return }
                if event.isAllDay {
                    event.startDate = calendar.startOfDay(for: startDayPicker.date)
                } else {
                    let startOfDay = calendar.startOfDay(for: startDayPicker.date)
                    let hour = calendar.component(.hour, from: startTimePicker.date)
                    let minute = calendar.component(.minute, from: startTimePicker.date)
                    event.startDate = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: startOfDay)
                }
                if let endDateCellIndexPath = indexPathForCell(name: .EndDateCell) {
                    reloadItem(at: endDateCellIndexPath)
                }
                checkAndSetDoneButtonEnabled()
            }), for: .valueChanged)
            startTimePicker.addAction(UIAction(handler: { [weak self] _ in
                guard let self else { return }
                let startOfDay = calendar.startOfDay(for: startDayPicker.date)
                let hour = calendar.component(.hour, from: startTimePicker.date)
                let minute = calendar.component(.minute, from: startTimePicker.date)
                event.startDate = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: startOfDay)
                if let endDateCellIndexPath = indexPathForCell(name: .EndDateCell) {
                    reloadItem(at: endDateCellIndexPath)
                }
                checkAndSetDoneButtonEnabled()
            }), for: .valueChanged)
            
            let startDayPickerAccessoryViewConfiguration = UICellAccessory.CustomViewConfiguration(customView: startDayPicker, placement: .trailing(), reservedLayoutWidth: .actual)
            let startTimePickerAccessoryViewConfiguration = UICellAccessory.CustomViewConfiguration(customView: startTimePicker, placement: .trailing(), reservedLayoutWidth: .actual)
            
            if event.isAllDay {
                cell.accessories = [.customView(configuration: startDayPickerAccessoryViewConfiguration)]
            } else {
                cell.accessories = [.customView(configuration: startDayPickerAccessoryViewConfiguration), .customView(configuration: startTimePickerAccessoryViewConfiguration)]
            }
            
        case .EndDateCell: // MARK: End Date Cell
            
            var configuration = cell.defaultContentConfiguration()
            configuration.textProperties.font = .rounded(ofSize: configuration.textProperties.font.pointSize - 1)
            
            configuration.text = Strings.ends
            
            cell.contentConfiguration = configuration
            
            let endDayPicker = UIDatePicker()
            endDayPicker.datePickerMode = .date
            endDayPicker.minimumDate = calendar.startOfDay(for: event.startDate)
            if let date = event.endDate {
                endDayPicker.date = date
            } else {
                endDayPicker.date = calendar.endOfDay(for: Date())
            }
            endDayPicker.isUserInteractionEnabled = event.calendar.allowsContentModifications
            
            let endTimePicker = UIDatePicker()
            endTimePicker.datePickerMode = .time
            if calendar.isDate(endDayPicker.date, inSameDayAs: event.startDate) {
                endTimePicker.minimumDate = event.startDate
            }
            if let time = event.endDate {
                endTimePicker.date = time
            } else {
                let hour = calendar.component(.hour, from: Date())
                let time = calendar.date(bySettingHour: hour + 1, minute: 0, second: 0, of: Date())!
                endTimePicker.date = time
            }
            endTimePicker.isUserInteractionEnabled = event.calendar.allowsContentModifications
            
            endDayPicker.addAction(UIAction(handler: { [weak self] _ in
                guard let self else { return }
                if event.isAllDay {
                    event.endDate = calendar.endOfDay(for: endDayPicker.date)
                } else {
                    let startOfDay = calendar.startOfDay(for: endDayPicker.date)
                    let hour = calendar.component(.hour, from: endTimePicker.date)
                    let minute = calendar.component(.minute, from: endTimePicker.date)
                    event.endDate = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: startOfDay)
                }
                checkAndSetDoneButtonEnabled()
            }), for: .valueChanged)
            endTimePicker.addAction(UIAction(handler: { [weak self] _ in
                guard let self else { return }
                let startOfDay = calendar.startOfDay(for: endDayPicker.date)
                let hour = calendar.component(.hour, from: endTimePicker.date)
                let minute = calendar.component(.minute, from: endTimePicker.date)
                event.endDate = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: startOfDay)
                checkAndSetDoneButtonEnabled()
            }), for: .valueChanged)
            
            let endDayPickerAccessoryViewConfiguration = UICellAccessory.CustomViewConfiguration(customView: endDayPicker, placement: .trailing(), reservedLayoutWidth: .actual)
            let endTimePickerAccessoryViewConfiguration = UICellAccessory.CustomViewConfiguration(customView: endTimePicker, placement: .trailing(), reservedLayoutWidth: .actual)
            
            if event.isAllDay {
                cell.accessories = [.customView(configuration: endDayPickerAccessoryViewConfiguration)]
            } else {
                cell.accessories = [.customView(configuration: endDayPickerAccessoryViewConfiguration), .customView(configuration: endTimePickerAccessoryViewConfiguration)]
            }
            
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
            repeatButton.isEnabled = event.calendar.allowsContentModifications
            
            var menu: UIMenu {
                let children: [UIAction] = [
                    UIAction(title: Strings.never, handler: { [weak self] _ in
                        guard let self else { return }
                        event.recurrenceRules = nil
                        let accessory = cell.accessories[0]
                        cell.accessories = []
                        cell.accessories = [accessory]
                        collectionView.reloadSections([4])
                        checkAndSetDoneButtonEnabled()
                    }),
                    UIAction(title: Strings.everyDay, handler: { [weak self] _ in
                        guard let self else { return }
                        event.recurrenceRules = [EKRecurrenceRule(recurrenceWith: .daily, interval: 1, end: nil)]
                        let accessory = cell.accessories[0]
                        cell.accessories = []
                        cell.accessories = [accessory]
                        collectionView.reloadSections([4])
                        checkAndSetDoneButtonEnabled()
                    }),
                    UIAction(title: Strings.everyWeek, handler: { [weak self] _ in
                        guard let self else { return }
                        event.recurrenceRules = [EKRecurrenceRule(recurrenceWith: .weekly, interval: 1, end: nil)]
                        let accessory = cell.accessories[0]
                        cell.accessories = []
                        cell.accessories = [accessory]
                        collectionView.reloadSections([4])
                        checkAndSetDoneButtonEnabled()
                    }),
                    UIAction(title: Strings.every2Weeks, handler: { [weak self] _ in
                        guard let self else { return }
                        event.recurrenceRules = [EKRecurrenceRule(recurrenceWith: .weekly, interval: 2, end: nil)]
                        let accessory = cell.accessories[0]
                        cell.accessories = []
                        cell.accessories = [accessory]
                        collectionView.reloadSections([4])
                        checkAndSetDoneButtonEnabled()
                    }),
                    UIAction(title: Strings.everyMonth, handler: { [weak self] _ in
                        guard let self else { return }
                        event.recurrenceRules = [EKRecurrenceRule(recurrenceWith: .monthly, interval: 1, end: nil)]
                        let accessory = cell.accessories[0]
                        cell.accessories = []
                        cell.accessories = [accessory]
                        collectionView.reloadSections([4])
                        checkAndSetDoneButtonEnabled()
                    }),
                    UIAction(title: Strings.everyYear, handler: { [weak self] _ in
                        guard let self else { return }
                        event.recurrenceRules = [EKRecurrenceRule(recurrenceWith: .yearly, interval: 1, end: nil)]
                        let accessory = cell.accessories[0]
                        cell.accessories = []
                        cell.accessories = [accessory]
                        collectionView.reloadSections([4])
                        checkAndSetDoneButtonEnabled()
                    })
                ]
                if !event.hasRecurrenceRules {
                    children[0].state = .on
                } else {
                    switch event.recurrenceRules![0].frequency {
                    case .daily:
                        children[1].state = .on
                    case .weekly:
                        if event.recurrenceRules![0].interval == 1 {
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
            
            let endRepeatDatePicker = UIDatePicker()
            endRepeatDatePicker.datePickerMode = .date
            endRepeatDatePicker.minimumDate = event.endDate
            if let date = event.recurrenceRules?.first?.recurrenceEnd?.endDate {
                endRepeatDatePicker.date = date
            } else {
                endRepeatDatePicker.date = event.endDate
            }
            endRepeatDatePicker.isUserInteractionEnabled = event.calendar.allowsContentModifications
            
            endRepeatDatePicker.addAction(UIAction(handler: { [weak self] _ in
                guard let self else { return }
                if let rule = event.recurrenceRules?.first {
                    rule.recurrenceEnd = EKRecurrenceEnd(end: endRepeatDatePicker.date)
                }
                checkAndSetDoneButtonEnabled()
            }), for: .valueChanged)
            
            let endRepeatDatePickerAccessoryViewConfiguration = UICellAccessory.CustomViewConfiguration(customView: endRepeatDatePicker, placement: .trailing(), reservedLayoutWidth: .actual)
            
            cell.accessories = [.customView(configuration: endRepeatDatePickerAccessoryViewConfiguration)]
            
        case .DeleteCell: // MARK: Delete Cell
            
            var configuration = LabelConfiguration()
            
            configuration.height = 48
            configuration.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20)
            configuration.label.font = .rounded(ofSize: 19)
            configuration.label.textColor = .systemRed
            configuration.label.textAlignment = .center
            configuration.label.text = Strings.deleteEvent
            
            cell.contentConfiguration = configuration
        }
        
        var backgroundConfiguration = cell.backgroundConfiguration
        backgroundConfiguration?.backgroundColor = .tertiarySystemBackground
        cell.backgroundConfiguration = backgroundConfiguration
        
        cell.tag = cellName.tag
        
        return cell
    }
}

extension EventEditingViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        collectionView.deselectItem(at: indexPath, animated: true)
        
        guard event.calendar.allowsContentModifications else { return }
        
        let cellName = cellName(at: indexPath)
        
        switch cellName {
        case .CalendarCell:
            navigationController?.pushViewController(EventCalendarChoosingViewController(event: event), animated: true)
        case .LocationCell:
            navigationController?.pushViewController(EventLocationSearchingViewController(event: event), animated: true)
        case .DeleteCell:
            let alertTitle = Strings.sureToDelete + Strings.space + Strings.this.lowercased() + Strings.space + Strings.event.lowercased() + Strings.questionMark
            let alert = UIAlertController(title: alertTitle, message: nil, preferredStyle: .actionSheet)
            let deleteAction = UIAlertAction(title: Strings.deleteEvent, style: .destructive) { [weak self] _ in
                guard let self else { return }
                
                calendarItemsManager.delete(event)
                
                dismiss(animated: true)
            }
            let deleteThisEventOnlyAction = UIAlertAction(title: Strings.deleteThisEventOnly, style: .destructive) { [weak self] _ in
                guard let self else { return }
                
                calendarItemsManager.delete(event)
                
                dismiss(animated: true)
            }
            let deleteAllFutureEventsAction = UIAlertAction(title: Strings.deleteAllFutureEvents, style: .destructive) { [weak self] _ in
                guard let self else { return }
                
                calendarItemsManager.delete(event, span: .futureEvents)
                
                dismiss(animated: true)
            }
            let cancelAction = UIAlertAction(title: Strings.cancel, style: .cancel)
            
            if event.hasRecurrenceRules {
                alert.addAction(deleteThisEventOnlyAction)
                alert.addAction(deleteAllFutureEventsAction)
            } else {
                alert.addAction(deleteAction)
            }
            alert.addAction(cancelAction)
            present(alert, animated: true)
        default:
            break
        }
    }
}

extension EventEditingViewController: UIAdaptivePresentationControllerDelegate {
    
    func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        
        // 隱藏鍵盤
        view.endEditing(true)
        
        switch mode {
        case .create:
            let calendarUnchanged = event.calendar == snapshotCalendar
            let noTitle = event.title == nil || event.title.isEmpty
            let noLocation = event.location == nil
            let noUrl = event.url == nil
            let noNotes = !event.hasNotes
            let dateUnchanged = event.startDate == snapshotStartDate && event.endDate == snapshotEndDate
            let noRepeat = !event.hasRecurrenceRules
            if calendarUnchanged, noTitle, noLocation, noUrl, noNotes, dateUnchanged, noRepeat {
                return true
            } else {
                return false
            }
        case .edit:
            return !event.hasChanges
        }
    }
    
    func presentationControllerDidAttemptToDismiss(_ presentationController: UIPresentationController) {
        
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let discardAction = UIAlertAction(title: Strings.discardChanges, style: .destructive) { [weak self] _ in
            guard let self else { return }
            
            if mode == .edit {
                event.reset()
            } else {
                calendarItemsManager.delete(event)
            }
            
            dismiss(animated: true)
        }
        let cancelAction = UIAlertAction(title: Strings.cancel, style: .cancel)
        alert.addAction(discardAction)
        alert.addAction(cancelAction)
        present(alert, animated: true)
    }
    
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        
        if event.isNew {
            calendarItemsManager.delete(event)
        }
    }
}

extension EventEditingViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        textField.resignFirstResponder()
        
        return true
    }
}

extension EventEditingViewController: UITextViewDelegate {
    
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
        
        event.notes = textView.text
        
        checkAndSetDoneButtonEnabled()
        
        collectionView.performBatchUpdates(nil)
    }
}
