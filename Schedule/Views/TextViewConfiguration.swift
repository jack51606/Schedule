import UIKit

struct TextViewConfiguration: UIContentConfiguration {
    
    public let textView = UITextView()
    public var contentInsets: NSDirectionalEdgeInsets = NSDirectionalEdgeInsets(top: 0, leading: 12, bottom: 0, trailing: 12)
    
    public func makeContentView() -> UIView & UIContentView {
        
        return TextViewContentView(configuration: self)
    }
    
    public func updated(for state: UIConfigurationState) -> TextViewConfiguration {
        
        return self
    }
}

final class TextViewContentView: UIView, UIContentView {
    
    public var configuration: UIContentConfiguration {
        didSet {
            updateContents()
        }
    }
    
    private var topConstraint: NSLayoutConstraint!
    private var bottomConstraint: NSLayoutConstraint!
    private var leadingConstraint: NSLayoutConstraint!
    private var trailingConstraint: NSLayoutConstraint!
    
    public init(configuration: TextViewConfiguration) {
        
        self.configuration = configuration
        
        super.init(frame: .zero)
        
        addSubview(configuration.textView)
        configuration.textView.translatesAutoresizingMaskIntoConstraints = false
        topConstraint = configuration.textView.topAnchor.constraint(equalTo: topAnchor)
        bottomConstraint = configuration.textView.bottomAnchor.constraint(equalTo: bottomAnchor)
        leadingConstraint = configuration.textView.leadingAnchor.constraint(equalTo: leadingAnchor)
        trailingConstraint = configuration.textView.trailingAnchor.constraint(equalTo: trailingAnchor)
        NSLayoutConstraint.activate([
            topConstraint,
            bottomConstraint,
            leadingConstraint,
            trailingConstraint
        ])
    }
    
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func updateContents() {
        guard let configuration = configuration as? TextViewConfiguration else { return }
        
        topConstraint.constant = configuration.contentInsets.top
        bottomConstraint.constant = -configuration.contentInsets.bottom
        leadingConstraint.constant = configuration.contentInsets.leading
        trailingConstraint.constant = -configuration.contentInsets.trailing
    }
}

extension UITextView {
    
    public var placeholder: String? {
        get {
            let label = value(forKey: "_placeholderLabel") as? UILabel
            return label?.text
        }
        set {
            if value(forKey: "_placeholderLabel") == nil {
                let label = UILabel()
                label.text = newValue
                label.font = font
                label.textColor = .placeholderText
                setValue(label, forKey: "_placeholderLabel")
                addSubview(label)
            }
        }
    }
}
