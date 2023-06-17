import UIKit

struct TextFieldConfiguration: UIContentConfiguration {
    
    public let textField = UITextField()
    public var contentInsets: NSDirectionalEdgeInsets = NSDirectionalEdgeInsets(top: 0, leading: 12, bottom: 0, trailing: 12)
    public var height: CGFloat = 44
    
    public func makeContentView() -> UIView & UIContentView {
        
        return TextFieldContentView(configuration: self)
    }
    
    public func updated(for state: UIConfigurationState) -> TextFieldConfiguration {
        
        return self
    }
}

final class TextFieldContentView: UIView, UIContentView {
    
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
    
    public init(configuration: TextFieldConfiguration) {
        
        self.configuration = configuration
        
        super.init(frame: .zero)
        
        addSubview(configuration.textField)
        configuration.textField.translatesAutoresizingMaskIntoConstraints = false
        topConstraint = configuration.textField.topAnchor.constraint(equalTo: topAnchor)
        bottomConstraint = configuration.textField.bottomAnchor.constraint(equalTo: bottomAnchor)
        leadingConstraint = configuration.textField.leadingAnchor.constraint(equalTo: leadingAnchor)
        trailingConstraint = configuration.textField.trailingAnchor.constraint(equalTo: trailingAnchor)
        heightConstraint = configuration.textField.heightAnchor.constraint(equalToConstant: 0)
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
        guard let configuration = configuration as? TextFieldConfiguration else { return }
        
        topConstraint.constant = configuration.contentInsets.top
        bottomConstraint.constant = -configuration.contentInsets.bottom
        leadingConstraint.constant = configuration.contentInsets.leading
        trailingConstraint.constant = -configuration.contentInsets.trailing
        heightConstraint.constant = configuration.height
    }
}
