import UIKit

final class AppearanceChoosingViewController: SettingsViewChildViewController {
    
    // MARK: - Private Properties
    
    private let appearanceManager = AppearanceManager.shared
    
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
        guard let keyPath, keyPath == Constants.UserDefaultsKeys.appearance else { return }
        
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
        UserDefaults.standard.addObserver(self, forKeyPath: Constants.UserDefaultsKeys.appearance, context: nil)
    }
    
    private func removeObserver() {
        UserDefaults.standard.removeObserver(self, forKeyPath: Constants.UserDefaultsKeys.appearance)
    }
}

extension AppearanceChoosingViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: SectionHeader.identifier, for: indexPath) as! SectionHeader
        
        header.setTitle(Strings.appearance)
        
        return header
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return AppearanceOption.allCases.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: UICollectionViewListCell.self.description(), for: indexPath) as! UICollectionViewListCell
        
        var configuration = cell.defaultContentConfiguration()
        configuration.textProperties.font = .rounded(ofSize: configuration.textProperties.font.pointSize)
        configuration.text = AppearanceOption.allCases[indexPath.row].text
        cell.contentConfiguration = configuration
        
        cell.accessories = [.checkmark(options: .init(isHidden: AppearanceOption.allCases[indexPath.row] != appearanceManager.currentChoiceOfAppearance))]
        
        var backgroundConfiguration = cell.backgroundConfiguration
        backgroundConfiguration?.backgroundColor = .tertiarySystemBackground
        cell.backgroundConfiguration = backgroundConfiguration
        
        return cell
    }
}

extension AppearanceChoosingViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        collectionView.deselectItem(at: indexPath, animated: true)
        
        let choice = AppearanceOption.allCases[indexPath.row]
        guard choice != appearanceManager.currentChoiceOfAppearance else { return }
        
        appearanceManager.updateAppearance(to: choice)
    }
}
