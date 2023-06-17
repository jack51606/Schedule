import UIKit
import EventKit
import CalendarKit
import CustomNavigationController

final class ReminderListChoosingViewController: CalendarItemEditingChildViewController {
    
    // MARK: - Private Properties
    
    private let reminder: EKReminder
    private let calendarItemsManager = CalendarItemsManager.shared
    
    private var lists: [EKCalendar] {
        return calendarItemsManager.currentVisibleReminderLists + calendarItemsManager.currentInvisibleReminderLists
    }
    private var sources: [EKSource] {
        let set = Set(lists.map({ $0.source! }))
        return Array(set)
    }
    
    private var collectionView: UICollectionView!
    
    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setCollectionView()
    }
    
    // MARK: - Public Methods
    
    public init(reminder: EKReminder) {
        
        self.reminder = reminder
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Private Methods
    
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
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
}

extension ReminderListChoosingViewController: UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        
        return sources.count
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: SectionHeader.identifier, for: indexPath) as! SectionHeader
        
        header.setTitle(sources[indexPath.section].title)
        
        return header
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        let source = sources[section]
        
        return lists.filter({ $0.source == source }).count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let list = lists.filter({ $0.source == sources[indexPath.section] })[indexPath.item]
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: UICollectionViewListCell.self.description(), for: indexPath) as! UICollectionViewListCell
        
        var configuration = cell.defaultContentConfiguration()
        configuration.textProperties.font = .rounded(ofSize: configuration.textProperties.font.pointSize)
        
        configuration.image = Constants.SFSymbols.circlebadgeFill.withConfiguration(UIImage.SymbolConfiguration(scale: .default)).withTintColor(UIColor(cgColor: list.cgColor), renderingMode: .alwaysOriginal)
        configuration.text = list.title
        
        cell.contentConfiguration = configuration
        
        cell.accessories = [.checkmark(options: .init(isHidden: list != reminder.calendar))]
        
        var backgroundConfiguration = cell.backgroundConfiguration
        backgroundConfiguration?.backgroundColor = .tertiarySystemBackground
        cell.backgroundConfiguration = backgroundConfiguration
        
        return cell
    }
}

extension ReminderListChoosingViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        collectionView.deselectItem(at: indexPath, animated: true)
        
        let list = lists.filter({ $0.source == sources[indexPath.section] })[indexPath.item]
        
        guard reminder.calendar != list else { return }
        
        reminder.calendar = list
        
        collectionView.reloadData()
        
        guard let reminderEditingViewController = (parent as? CustomNavigationController)?.rootViewController as? ReminderEditingViewController else { return }
        
        reminderEditingViewController.reloadItem(at: IndexPath(item: 0, section: 0))
        reminderEditingViewController.checkAndSetDoneButtonEnabled()
    }
}
