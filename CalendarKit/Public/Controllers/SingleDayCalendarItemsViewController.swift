import UIKit
import EventKit

@objc public protocol SingleDayCalendarItemsViewControllerDelegate: AnyObject {
    @objc optional var collectionViewPlaceholder: UIView { get }
    @objc optional func replacementTitleForEvent(withTitle originalTitle: String) -> String?
    @objc optional func replacementAttributedTitleForEvent(withTitle originalTitle: String, originalFont: UIFont) -> NSAttributedString?
    @objc optional func eventSelected(_ event: EKEvent)
    @objc optional func reminderSelected(_ reminder: EKReminder)
}

public final class SingleDayCalendarItemsViewController: UIViewController {
    
    // MARK: - Public Properties
    
    public var date: Date? {
        didSet {
            updateCalendarItemsForCollectionView(collapseReminderCells: true)
        }
    }
    
    public var padding: UIEdgeInsets = .zero
    
    public weak var delegate: SingleDayCalendarItemsViewControllerDelegate?
    
    // MARK: - Private Properties
    
    private var calendar: Calendar {
        return CalendarPreferenceManager.shared.calendar
    }
    private let calendarItemsManager = CalendarItemsManager.shared
    private var items: [EKCalendarItem] = []
    
    private typealias DataSource = UICollectionViewDiffableDataSource<Section, EKCalendarItem>
    private typealias Snapshot = NSDiffableDataSourceSnapshot<Section, EKCalendarItem>
    private var dataSource: DataSource!
    private var snapShot = Snapshot()
    private enum Section {
        case main
    }
    
    private var collectionView: UICollectionView!
    private lazy var collectionViewPlaceholder: UIView = {
        let label = UILabel()
        label.text = Strings.noEvents
        label.font = .systemFont(ofSize: 19, weight: .medium)
        label.textColor = .placeholderText
        return delegate?.collectionViewPlaceholder ?? label
    }()
    private var expandedReminderCellItemIdentifiers: [String] = []
    
    private static let BlankCellIdentifier = "BlankCell"
    
    // MARK: - Life Cycle
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        setCollectionView()
        setLongPressGestureRecognizer()
        setObservers()
    }
    
    // MARK: - Public Methods
    
    public func updateCalendarItemsForCollectionView(animatingDifferences: Bool = false, collapseReminderCells: Bool = false, completion: (() -> Void)? = nil) {
        guard let date else { return }
        
        Task {
            
            let startTime = calendar.startOfDay(for: date)
            let endTime = calendar.endOfDay(for: date)
            
            let events = calendarItemsManager.events(from: startTime, to: endTime)
            var reminders: [EKReminder] {
                get async {
                    switch CalendarPreferenceManager.shared.currentChoiceOfShowingRemindersInSingleDayItemsView {
                        
                    case .IncompleteOnly:
                        return await calendarItemsManager.reminders(from: startTime, to: endTime, option: .IncompleteOnly)
                    case .ShowAll:
                        return await calendarItemsManager.reminders(from: startTime, to: endTime, option: .All)
                    case .HideAll:
                        return []
                    }
                }
            }
            
            var items: [EKCalendarItem] = await events + reminders
            items.sort(by: calendarItemsManager.singleDayCalendarItemsSortComparator(date: date))
            
            self.items = items
            
            snapShot.deleteAllItems()
            snapShot.appendSections([.main])
            snapShot.appendItems(items)
            
            if collapseReminderCells {
                expandedReminderCellItemIdentifiers = []
            }
            
            if animatingDifferences {
                
                DispatchQueue.main.async { [weak self] in
                    guard let self else { return }
                    dataSource.apply(snapShot, animatingDifferences: animatingDifferences) {
                        
                        completion?()
                        
                        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseInOut) {
                            if !items.isEmpty {
                                self.collectionViewPlaceholder.alpha = 0
                            } else {
                                self.collectionViewPlaceholder.alpha = 1
                            }
                        }
                    }
                }
                
            } else {
                
                dataSource.applySnapshotUsingReloadData(snapShot) { [weak self] in
                    guard let self else { return }
                    
                    completion?()
                    
                    if !items.isEmpty {
                        collectionViewPlaceholder.alpha = 0
                    } else {
                        collectionViewPlaceholder.alpha = 1
                    }
                }
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func setCollectionView() {
        
        var configuration = UICollectionLayoutListConfiguration(appearance: .plain)
        configuration.backgroundColor = .clear
        configuration.separatorConfiguration.bottomSeparatorInsets.leading = 24
        configuration.separatorConfiguration.bottomSeparatorInsets.trailing = 12
        configuration.itemSeparatorHandler = { [weak self] (indexPath, sectionSeparatorConfiguration) in
            guard let self else { return sectionSeparatorConfiguration }
            
            var configuration = sectionSeparatorConfiguration
            if indexPath.item == items.count - 1 {
                configuration.bottomSeparatorVisibility = .hidden
            }
            
            return configuration
        }
        let layout = UICollectionViewCompositionalLayout.list(using: configuration)
        
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.register(EventCell.self, forCellWithReuseIdentifier: EventCell.identifier)
        collectionView.register(ReminderCell.self, forCellWithReuseIdentifier: ReminderCell.identifier)
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: Self.BlankCellIdentifier)
        collectionView.delegate = self
        collectionView.contentInset.bottom = 60
        collectionView.backgroundColor = .clear
        
        view.addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor, constant: padding.top),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -padding.bottom),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: padding.left),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -padding.right)
        ])
        
        view.addSubview(collectionViewPlaceholder)
        collectionViewPlaceholder.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            collectionViewPlaceholder.centerXAnchor.constraint(equalTo: collectionView.centerXAnchor),
            collectionViewPlaceholder.centerYAnchor.constraint(equalTo: collectionView.centerYAnchor)
        ])
        
        dataSource = DataSource(collectionView: collectionView, cellProvider: { [weak self] collectionView, indexPath, item in
            guard let self else {
                return collectionView.dequeueReusableCell(withReuseIdentifier: Self.BlankCellIdentifier, for: indexPath)
            }
            
            if let event = item as? EKEvent, let date {
                
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: EventCell.identifier, for: indexPath) as! EventCell
                
                cell.delegate = self
                cell.configure(with: event, date: date, setEventEndedOnlyOnToday: true)
                
                return cell
            }
            
            if let reminder = item as? EKReminder {
                
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ReminderCell.identifier, for: indexPath) as! ReminderCell
                
                cell.delegate = self
                cell.configure(with: reminder, expand: expandedReminderCellItemIdentifiers.contains(reminder.calendarItemIdentifier))
                
                return cell
            }
            
            return collectionView.dequeueReusableCell(withReuseIdentifier: Self.BlankCellIdentifier, for: indexPath)
        })
        
        snapShot.appendSections([.main])
        dataSource.apply(snapShot)
    }
    
    private func setLongPressGestureRecognizer() {
        
        let gesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPressGesture))
        
        collectionView.addGestureRecognizer(gesture)
    }
    
    private func setObservers() {
        
        let notificationCenter = NotificationCenter.default
        
        notificationCenter.addObserver(self, selector: #selector(sceneWillEnterForeground), name: UIScene.willEnterForegroundNotification, object: nil)
    }
    
    @objc private func handleLongPressGesture(_ sender: UILongPressGestureRecognizer) {
        guard sender.state == .began else { return }
        
        let location = sender.location(in: collectionView)
        guard let indexPath = collectionView.indexPathForItem(at: location) else { return }
        guard let cell = collectionView.cellForItem(at: indexPath) else { return }
        
        if let event = (cell as? EventCell)?.event {
            delegate?.eventSelected?(event)
        } else if let reminder = (cell as? ReminderCell)?.reminder {
            delegate?.reminderSelected?(reminder)
        }
    }
    
    @objc private func sceneWillEnterForeground() {
        
        updateCalendarItemsForCollectionView()
    }
}

extension SingleDayCalendarItemsViewController: UICollectionViewDelegate {
    
    public func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let reminderCell = cell as? ReminderCell else { return }
        
        reminderCell.didEndDisplay()
    }
}

extension SingleDayCalendarItemsViewController: EventCellDelegate {
    
    func replacementTitle(withOriginalTitle originalTitle: String) -> String? {
        return delegate?.replacementTitleForEvent?(withTitle: originalTitle)
    }
    
    func replacementAttributedTitle(withOriginalTitle originalTitle: String, originalFont: UIFont) -> NSAttributedString? {
        return delegate?.replacementAttributedTitleForEvent?(withTitle: originalTitle, originalFont: originalFont)
    }
}

extension SingleDayCalendarItemsViewController: ReminderCellDelegate {
    
    func didExpand(_ isExpanded: Bool, reminder: EKReminder) {
        
        let identifier = reminder.calendarItemIdentifier
        
        if isExpanded {
            guard !expandedReminderCellItemIdentifiers.contains(identifier) else { return }
            
            expandedReminderCellItemIdentifiers.append(identifier)
        } else {
            guard expandedReminderCellItemIdentifiers.contains(identifier) else { return }
            
            let index = expandedReminderCellItemIdentifiers.firstIndex(of: identifier)!
            expandedReminderCellItemIdentifiers.remove(at: index)
        }
    }
}
