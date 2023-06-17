import UIKit
import EventKit
import CalendarKit

final class ReminderListsViewController: SettingsViewChildViewController {
    
    // MARK: - Private Properties
    
    private let calendarItemsManager = CalendarItemsManager.shared
    
    private let addButton: UIButton = {
        let button = UIButton()
        var configuration = UIButton.Configuration.plain()
        configuration.image = Constants.SFSymbols.plus.withConfiguration(UIImage.SymbolConfiguration(pointSize: UIFont.buttonFontSize, weight: .medium, scale: .default))
        button.configuration = configuration
        button.widthAnchor.constraint(equalToConstant: 28).isActive = true
        return button
    }()
    private let sortButton: UIButton = {
        let button = UIButton()
        var configuration = UIButton.Configuration.plain()
        configuration.image = Constants.SFSymbols.arrowUpArrowDown.withConfiguration(UIImage.SymbolConfiguration(pointSize: UIFont.buttonFontSize, weight: .medium, scale: .default))
        button.configuration = configuration
        button.widthAnchor.constraint(equalToConstant: 40).isActive = true
        return button
    }()
    
    private typealias DataSource = UICollectionViewDiffableDataSource<Section, EKCalendar>
    private typealias Snapshot = NSDiffableDataSourceSnapshot<Section, EKCalendar>
    private var dataSource: DataSource!
    private var snapShot = Snapshot()
    private enum Section {
        case currentVisibleLists, currentInvisibleLists
    }
    
    private var collectionView: UICollectionView!
    
    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setNavigationItems()
        setCollectionView()
        
        setObservers()
    }
    
    // MARK: - Private Methods
    
    private func setNavigationItems() {
        
        addButton.addTarget(self, action: #selector(addButtonPressed), for: .touchUpInside)
        sortButton.addTarget(self, action: #selector(sortButtonPressed), for: .touchUpInside)
        customNavigationItem.rightBarButtonItems = [UIBarButtonItem(customView: sortButton), UIBarButtonItem(customView: addButton)]
    }
    
    private func setCollectionView() {
        
        var configuration = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
        configuration.backgroundColor = .clear
        configuration.headerMode = .supplementary
        let layout = UICollectionViewCompositionalLayout.list(using: configuration)
        
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
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
        
        dataSource = DataSource(collectionView: collectionView, cellProvider: { collectionView, indexPath, list in
            
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: UICollectionViewListCell.self.description(), for: indexPath) as! UICollectionViewListCell
            
            var configuration = cell.defaultContentConfiguration()
            configuration.textProperties.font = .rounded(ofSize: configuration.textProperties.font.pointSize)
            
            configuration.text = list.title
            switch list.source.sourceType {
            case .local:
                configuration.secondaryText = Strings.this  + Strings.space + UIDevice().name
            case .subscribed:
                configuration.secondaryText = Strings.subscribed
            case .birthdays:
                configuration.secondaryText = nil
            default:
                configuration.secondaryText = list.source.title
            }
            
            cell.contentConfiguration = configuration
            
            let detailButton: DetailButton = { [weak self] in
                guard let self else { return DetailButton() }
                
                let button = DetailButton()
                
                button.setImage(Constants.SFSymbols.info.withConfiguration(UIImage.SymbolConfiguration(scale: .large)), for: .normal)
                
                button.list = list
                
                button.addTarget(self, action: #selector(detailButtonPressed), for: .touchUpInside)
                
                return button
            }()
            let detailButtonAccessoryViewConfiguration = UICellAccessory.CustomViewConfiguration(customView: detailButton, placement: .trailing(displayed: .whenNotEditing), tintColor: .secondaryLabel)
            
            let selectButton: SelectButton = { [weak self] in
                guard let self else { return SelectButton() }
                
                let button = SelectButton()
                
                let unselectedImage = Constants.SFSymbols.circle.withConfiguration(UIImage.SymbolConfiguration(scale: .large))
                let selectedImage = Constants.SFSymbols.checkmarkCircleFill.withConfiguration(UIImage.SymbolConfiguration(scale: .large))
                
                button.setImage(unselectedImage, for: .normal)
                button.setImage(selectedImage, for: .selected)
                
                button.list = list
                
                button.isSelected = calendarItemsManager.currentVisibleReminderLists.contains(list)
                
                button.addTarget(self, action: #selector(selectButtonPressed), for: .touchUpInside)
                
                return button
            }()
            let selectButtonAccessoryViewConfiguration = UICellAccessory.CustomViewConfiguration(customView: selectButton, placement: .leading(displayed: .always), tintColor: UIColor(cgColor: list.cgColor))
            
            cell.accessories = [.customView(configuration: selectButtonAccessoryViewConfiguration), .customView(configuration: detailButtonAccessoryViewConfiguration), .reorder(displayed: .whenEditing, options: UICellAccessory.ReorderOptions(isHidden: indexPath.section != 0))]
            
            var backgroundConfiguration = cell.backgroundConfiguration
            backgroundConfiguration?.backgroundColor = .tertiarySystemBackground
            cell.backgroundConfiguration = backgroundConfiguration
            
            return cell
        })
        
        dataSource.supplementaryViewProvider = { collectionView, kind, indexPath in
            guard kind == UICollectionView.elementKindSectionHeader else { return nil }
            
            let header = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: SectionHeader.identifier, for: indexPath) as! SectionHeader
            
            switch indexPath.section {
            case 0:
                header.setTitle(Strings.displayed)
            case 1:
                header.setTitle(Strings.notDisplayed)
            default:
                break
            }
            
            return header
        }
        
        dataSource.reorderingHandlers.canReorderItem = { [weak self] list in
            guard let self else { return false }
            
            return calendarItemsManager.currentVisibleReminderLists.contains(list)
        }
        
        dataSource.reorderingHandlers.didReorder = { [weak self] transaction in
            guard let self else { return }
            guard let sectionTransaction = transaction.sectionTransactions.first(where: { $0.sectionIdentifier == .currentVisibleLists }) else { return }
            
            calendarItemsManager.reorderCurrentVisibleReminderLists(to: sectionTransaction.finalSnapshot.items)
        }
        
        snapShot.appendSections([.currentVisibleLists, .currentInvisibleLists])
        snapShot.appendItems(calendarItemsManager.currentVisibleReminderLists, toSection: .currentVisibleLists)
        snapShot.appendItems(calendarItemsManager.currentInvisibleReminderLists, toSection: .currentInvisibleLists)
        dataSource.apply(snapShot)
    }
    
    private func setObservers() {
        
        let notificationCenter = NotificationCenter.default
        
        notificationCenter.addObserver(self, selector: #selector(EKEventStoreChanged), name: .EKEventStoreChanged, object: nil)
    }
    
    @objc private func addButtonPressed(_ sender: UIButton) {
        guard let list = calendarItemsManager.newReminderList() else { return }
        
        present(ReminderListEditingViewController(list: list), animated: true)
    }
    
    @objc private func sortButtonPressed(_ sender: UIButton) {
        
        sender.isSelected.toggle()
        collectionView.isEditing = sender.isSelected
    }
    
    @objc private func selectButtonPressed(_ sender: SelectButton) {
        guard !collectionView.isEditing else { return }
        guard let list = sender.list else { return }
        
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
        
        sender.isSelected.toggle()
        if sender.isSelected {
            calendarItemsManager.addVisibleReminderList(list)
        } else {
            calendarItemsManager.removeVisibleReminderList(list)
        }
        
        snapShot.deleteAllItems()
        snapShot.appendSections([.currentVisibleLists, .currentInvisibleLists])
        snapShot.appendItems(calendarItemsManager.currentVisibleReminderLists, toSection: .currentVisibleLists)
        snapShot.appendItems(calendarItemsManager.currentInvisibleReminderLists, toSection: .currentInvisibleLists)
        dataSource.apply(snapShot, animatingDifferences: true)
        
        guard let indexPath = dataSource.indexPath(for: list) else { return }
        guard let cell = collectionView.cellForItem(at: indexPath) as? UICollectionViewListCell else { return }
        
        if indexPath.section == 0 {
            cell.accessories = [cell.accessories[0], cell.accessories[1], .reorder(displayed: .whenEditing)]
        } else {
            cell.accessories = [cell.accessories[0], cell.accessories[1]]
        }
    }
    
    @objc private func detailButtonPressed(_ sender: DetailButton) {
        guard let list = sender.list else { return }
        
        present(ReminderListEditingViewController(list: list), animated: true)
    }
    
    @objc private func EKEventStoreChanged() {
        
        snapShot.deleteAllItems()
        snapShot.appendSections([.currentVisibleLists, .currentInvisibleLists])
        snapShot.appendItems(calendarItemsManager.currentVisibleReminderLists, toSection: .currentVisibleLists)
        snapShot.appendItems(calendarItemsManager.currentInvisibleReminderLists, toSection: .currentInvisibleLists)
        dataSource.applySnapshotUsingReloadData(snapShot)
    }
}

extension ReminderListsViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, targetIndexPathForMoveOfItemFromOriginalIndexPath originalIndexPath: IndexPath, atCurrentIndexPath currentIndexPath: IndexPath, toProposedIndexPath proposedIndexPath: IndexPath) -> IndexPath {
        
        if currentIndexPath.section != 0 || proposedIndexPath.section != 0 {
            return originalIndexPath
        }
        
        return proposedIndexPath
    }
}

private final class SelectButton: CustomButton {
    
    public weak var list: EKCalendar?
}

private final class DetailButton: CustomButton {
    
    public weak var list: EKCalendar?
}
