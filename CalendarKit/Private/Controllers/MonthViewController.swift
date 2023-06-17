import UIKit

protocol MonthViewControllerDelegate: AnyObject {
    func didSelectDate(date: Date)
}

@MainActor final class MonthViewController: UIViewController {
    
    // MARK: - Public Properties
    
    public let month: Month
    
    public weak var delegate: MonthViewControllerDelegate?
    
    public var shouldSetDaySelectedAfterInitialize: Bool = false
    public var isEveryDayUnselected: Bool {
        for cell in collectionView.visibleCells {
            guard let cell = cell as? DayCell else { return true }
            
            if cell.isSelected {
                return false
            }
        }
        return true
    }
    
    // MARK: - Private Properties
    
    private let calendar = CalendarPreferenceManager.shared.calendar
    private let calendarPreferenceManager = CalendarPreferenceManager.shared
    private let monthDataManager = MonthDataManager.shared
    private let eventStoreAuthorizationStatusesUpdated = CalendarItemsManager.shared.eventStoreAuthorizationStatusesUpdated
    private var data: Data?
    
    private var collectionView: UICollectionView!
    private var collectionViewLayout: UICollectionViewLayout {
        
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1/7), heightDimension: .fractionalHeight(1))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(44))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        
        let section = NSCollectionLayoutSection(group: group)
        
        return UICollectionViewCompositionalLayout(section: section)
    }
    private var numberOfEmptyDates: Int {
        if month.weekdayOfFirstDay >= calendar.firstWeekday {
            return month.weekdayOfFirstDay - calendar.firstWeekday
        } else {
            return 7 - (calendar.firstWeekday - month.weekdayOfFirstDay)
        }
    }
    
    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        fetchMonthData()
        setCollectionView()
    }
    
    override func viewWillLayoutSubviews() {
        
        view.addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        if shouldSetDaySelectedAfterInitialize {
            
            var day: Int
            
            if let selectedDate = (delegate as? CalendarViewController)?.selectedDate {
                day = calendar.component(.day, from: selectedDate)
            } else {
                if month.isCurrentMonth {
                    day = calendar.component(.day, from: Date())
                } else {
                    day = 1
                }
            }
            guard let cell = collectionView.cellForItem(at: IndexPath(item: day + numberOfEmptyDates - 1, section: 0)) as? DayCell else { return }
            
            cell.isSelected = true
        }
    }
    
    // MARK: - Public Methods
    
    public init(month: Month) {
        self.month = month
        super.init(nibName: nil, bundle: nil)
    }
    
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func setDaySelected(_ day: Int) {
        guard day > 0, let cell = collectionView.cellForItem(at: IndexPath(item: day + numberOfEmptyDates - 1, section: 0)) as? DayCell else { return }
        
        for cell in collectionView.visibleCells {
            guard let cell = cell as? DayCell else { return }
            
            cell.isSelected = false
        }
        
        cell.isSelected = true
    }
    
    public func setEveryDayUnselected() {
        for cell in collectionView.visibleCells {
            guard let cell = cell as? DayCell else { return }
            
            cell.isSelected = false
        }
    }
    
    public func updateToCurrentDate() {
        
        for item in 0...month.numberOfDays + numberOfEmptyDates - 1 {
            
            guard let cell = collectionView.cellForItem(at: IndexPath(item: item, section: 0)) as? DayCell else { return }
            
            cell.isToday = false
        }
        
        guard month.year == calendar.component(.year, from: Date()), month.month == calendar.component(.month, from: Date()) else { return }
        
        let item = calendar.component(.day, from: Date()) + numberOfEmptyDates - 1
        guard let cell = collectionView.cellForItem(at: IndexPath(item: item, section: 0)) as? DayCell else { return }
        
        cell.isToday = true
    }
    
    public func updateCalendarItems() {
        
        Task {
            
            await monthDataManager.updateMonthData(month)
            
            fetchMonthData()
            
            guard let data else { return }
            
            for day in 1...month.numberOfDays {
                guard let cell = collectionView.cellForItem(at: IndexPath(item: numberOfEmptyDates + day - 1, section: 0)) as? DayCell else { break }
                
                let items = data.dictionary[day]!
                cell.updateItems(items: items, withUIupdate: true)
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func setCollectionView() {
        
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: collectionViewLayout)
        collectionView.register(DayCell.self, forCellWithReuseIdentifier: DayCell.identifier)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.isScrollEnabled = false
        collectionView.backgroundColor = .clear
    }
    
    private func fetchMonthData() {
        data = monthDataManager.fetchMonthData(by: month)?.data
    }
}

extension MonthViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return numberOfEmptyDates + month.numberOfDays
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: DayCell.identifier, for: indexPath) as! DayCell
        
        guard indexPath.item >= numberOfEmptyDates else {
            cell.isUserInteractionEnabled = false
            return cell
        }
        
        let day = indexPath.item - numberOfEmptyDates + 1
        cell.day = day
        let date: Date = {
            var components = DateComponents()
            components.calendar = calendar
            components.year = month.year
            components.month = month.month
            components.day = day
            return components.date!
        }()
        cell.isWeekend = calendar.isDateInWeekend(date)
        cell.isToday = calendar.isDateInToday(date)
        
        if let data, !eventStoreAuthorizationStatusesUpdated {
            let items = data.dictionary[day]!
            cell.updateItems(items: items, withUIupdate: false)
        }
        
        return cell
    }
}

extension MonthViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        let day = indexPath.item - numberOfEmptyDates + 1
        
        for cell in collectionView.visibleCells {
            guard let cell = cell as? DayCell else { break }
            
            cell.isSelected = cell.day == day
        }
        
        let date: Date = {
            var components = DateComponents()
            components.calendar = calendar
            components.year = month.year
            components.month = month.month
            components.day = day
            return calendar.startOfDay(for: components.date!)
        }()
        
        delegate?.didSelectDate(date: date)
    }
}
