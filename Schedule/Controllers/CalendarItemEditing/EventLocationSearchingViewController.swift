import UIKit
import MapKit
import EventKit
import CustomNavigationController

final class EventLocationSearchingViewController: CalendarItemEditingChildViewController {
    
    // MARK: - Private Properties
    
    private let event: EKEvent
    
    private let searchCompleter = MKLocalSearchCompleter()
    
    private let searchBar: UISearchBar = {
        let bar = UISearchBar()
        bar.placeholder = Strings.searchPlaces
        bar.setBackgroundImage(UIImage(), for: .any, barMetrics: .default)
        return bar
    }()
    
    private var collectionView: UICollectionView!
    private var results: [MKLocalSearchCompletion] = []
    
    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setSearchCompleter()
        setSearchBar()
        setCollectionView()
    }
    
    // MARK: - Public Methods
    
    public init(event: EKEvent) {
        
        self.event = event
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Private Methods
    
    private func setSearchCompleter() {
        
        searchCompleter.delegate = self
        searchCompleter.resultTypes = [.address, .pointOfInterest]
    }
    
    private func setSearchBar() {
        
        searchBar.delegate = self
        searchBar.text = event.structuredLocation?.title
        searchBar.becomeFirstResponder()
        
        view.addSubview(searchBar)
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8)
        ])
    }
    
    private func setCollectionView() {
        
        var configuration = UICollectionLayoutListConfiguration(appearance: .grouped)
        configuration.backgroundColor = .clear
        configuration.headerMode = .supplementary
        let layout = UICollectionViewCompositionalLayout.list(using: configuration)
        
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(UICollectionViewListCell.self, forCellWithReuseIdentifier: UICollectionViewListCell.self.description())
        collectionView.contentInset.bottom = 60
        collectionView.backgroundColor = .clear
        
        view.addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: searchBar.bottomAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
}

extension EventLocationSearchingViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return results.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: UICollectionViewListCell.self.description(), for: indexPath) as! UICollectionViewListCell
        
        var configuration = cell.defaultContentConfiguration()
        configuration.textProperties.font = .rounded(ofSize: configuration.textProperties.font.pointSize)
        configuration.secondaryTextProperties.font = .rounded(ofSize: configuration.secondaryTextProperties.font.pointSize)
        configuration.secondaryTextProperties.color = .secondaryLabel
        
        configuration.text = results[indexPath.row].title
        configuration.secondaryText = results[indexPath.row].subtitle
        
        cell.contentConfiguration = configuration
        
        return cell
    }
}

extension EventLocationSearchingViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        collectionView.deselectItem(at: indexPath, animated: true)
        
        let result = results[indexPath.row]
        
        if let item = result.value(forKey: "mapItem") as? MKMapItem {
            
            item.name = results[indexPath.row].title
            event.structuredLocation = EKStructuredLocation(mapItem: item)
            
        } else {
            
            event.structuredLocation = EKStructuredLocation(title: results[indexPath.row].title)
        }
        
        guard let eventEditingViewController = (parent as? CustomNavigationController)?.rootViewController as? EventEditingViewController else { return }
        
        eventEditingViewController.reloadItem(at: IndexPath(item: 1, section: 1))
        eventEditingViewController.checkAndSetDoneButtonEnabled()
        
        (parent as? CustomNavigationController)?.popViewController(animated: true)
    }
}

extension EventLocationSearchingViewController: UISearchBarDelegate {
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        
        results = []
        collectionView.reloadData()
        
        searchCompleter.queryFragment = searchText
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        
        searchBar.resignFirstResponder()
    }
}

extension EventLocationSearchingViewController: MKLocalSearchCompleterDelegate {
    
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        
        results = completer.results
        
        collectionView.reloadData()
    }
}
