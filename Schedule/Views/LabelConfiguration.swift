import UIKit

struct LabelConfiguration: UIContentConfiguration {
    
    public let label = UILabel()
    
    public var contentInsets: NSDirectionalEdgeInsets = NSDirectionalEdgeInsets(top: 0, leading: 12, bottom: 0, trailing: 12)
    public var height: CGFloat = 44
    
    public func makeContentView() -> UIView & UIContentView {
        
        return LabelContentView(configuration: self)
    }
    
    public func updated(for state: UIConfigurationState) -> LabelConfiguration {
        
        return self
    }
}

final class LabelContentView: UIView, UIContentView {
    
    public var configuration: UIContentConfiguration {
        didSet {
            updateContents()
        }
    }
    
    private var topConstraint: NSLayoutConstraint!
    private var bottomConstraint: NSLayoutConstraint!
    private var leadingConstraint: NSLayoutConstraint!
    private var trailingConstraint: NSLayoutConstraint!
    private var heightConstraint: NSLayoutConstraint!
    
    public init(configuration: LabelConfiguration) {
        
        self.configuration = configuration
        
        super.init(frame: .zero)
        
        addSubview(configuration.label)
        configuration.label.translatesAutoresizingMaskIntoConstraints = false
        topConstraint = configuration.label.topAnchor.constraint(equalTo: topAnchor)
        bottomConstraint = configuration.label.bottomAnchor.constraint(equalTo: bottomAnchor)
        leadingConstraint = configuration.label.leadingAnchor.constraint(equalTo: leadingAnchor)
        trailingConstraint = configuration.label.trailingAnchor.constraint(equalTo: trailingAnchor)
        heightConstraint = configuration.label.heightAnchor.constraint(equalToConstant: 0)
        NSLayoutConstraint.activate([
            topConstraint,
            bottomConstraint,
            leadingConstraint,
            trailingConstraint,
            heightConstraint
        ])
    }
    
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func updateContents() {
        guard let configuration = configuration as? LabelConfiguration else { return }
        
        topConstraint.constant = configuration.contentInsets.top
        bottomConstraint.constant = -configuration.contentInsets.bottom
        leadingConstraint.constant = configuration.contentInsets.leading
        trailingConstraint.constant = -configuration.contentInsets.trailing
        heightConstraint.constant = configuration.height
    }
}
