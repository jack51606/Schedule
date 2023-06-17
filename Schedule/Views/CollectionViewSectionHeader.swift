import UIKit

final class SectionHeader: UICollectionReusableView {
    
    // MARK: - Public Properties
    
    public static let identifier = "SectionHeader"
    
    // MARK: - Private Properties
    
    private let label: UILabel = {
        let label = UILabel()
        label.font = .rounded(ofSize: 14)
        label.textColor = .secondaryLabel
        return label
    }()
    
    // MARK: - Override Methods
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4),
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Public Methods
    
    public func setTitle(_ title: String) {
        label.text = title.uppercased()
    }
}
