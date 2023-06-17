import UIKit
import CalendarKit

final class FirstWeekdayChoosingViewController: SettingsViewChildViewController {
    
    // MARK: - Private Properties
    
    private let calendarPreferenceManager = CalendarPreferenceManager.shared
    
    private var collectionView: UICollectionView!
    
    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setCollectionView()
        setObserver()
    }
    
    deinit {
        removeObserver()
    }
    
    // MARK: - Override Methods
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard let keyPath, keyPath == CalendarKit.Constants.UserDefaultsKeys.firstWeekday else { return }
        
        collectionView.reloadData()
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
    
    private func setObserver() {
        UserDefaults.standard.addObserver(self, forKeyPath: CalendarKit.Constants.UserDefaultsKeys.firstWeekday, context: nil)
    }
    
    private func removeObserver() {
        UserDefaults.standard.removeObserver(self, forKeyPath: CalendarKit.Constants.UserDefaultsKeys.firstWeekday)
    }
}

extension FirstWeekdayChoosingViewController: UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        
        return 2
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: SectionHeader.identifier, for: indexPath) as! SectionHeader
        
        switch indexPath.section {
        case 0:
            header.setTitle(Strings.followSystemSetting)
        case 1:
            header.setTitle(Strings.custom)
        default:
            break
        }
        
        return header
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        switch section {
        case 0:
            return 1
        case 1:
            return 7
        default:
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: UICollectionViewListCell.self.description(), for: indexPath) as! UICollectionViewListCell
        
        var configuration = cell.defaultContentConfiguration()
        configuration.textProperties.font = .rounded(ofSize: configuration.textProperties.font.pointSize)
        
        switch indexPath.section {
            
        case 0:
            
            var text: String {
                let text = FirstWeekdayOption.SystemSetting.text
                let weekdayText = Calendar.autoupdatingCurrent.weekdaySymbols[Calendar.autoupdatingCurrent.firstWeekday - 1]
                return Locale.autoupdatingCurrent.isChinese ? text + Strings.parenthesisLeft + weekdayText + Strings.parenthesisRight : text + Strings.space + Strings.parenthesisLeft + weekdayText + Strings.parenthesisRight
            }
            configuration.text = text
            
        case 1:
            
            configuration.text = FirstWeekdayOption.allCases[indexPath.row + 1].text
            
        default:
            break
        }
        
        cell.contentConfiguration = configuration
        
        cell.accessories = [.checkmark(options: .init(isHidden: FirstWeekdayOption.allCases[indexPath.section + indexPath.row] != calendarPreferenceManager.currentChoiceOfFirstWeekday))]
        
        var backgroundConfiguration = cell.backgroundConfiguration
        backgroundConfiguration?.backgroundColor = .tertiarySystemBackground
        cell.backgroundConfiguration = backgroundConfiguration
        
        return cell
    }
}

extension FirstWeekdayChoosingViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        collectionView.deselectItem(at: indexPath, animated: true)
        
        let choice = FirstWeekdayOption.allCases[indexPath.section + indexPath.row]
        guard choice != calendarPreferenceManager.currentChoiceOfFirstWeekday else { return }
        
        calendarPreferenceManager.updateFirstWeekday(to: choice)
    }
}
