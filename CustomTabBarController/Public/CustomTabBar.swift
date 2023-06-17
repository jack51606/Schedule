import UIKit

@MainActor public final class CustomTabBar: UIView {
    
    // MARK: - Public Properties
    
    public var hideSeparator: Bool = false {
        didSet {
            separator.isHidden = hideSeparator
        }
    }
    public var horizontalInset: CGFloat = 0.0 {
        didSet {
            stackViewLeadingConstraint.constant = horizontalInset
            stackViewTrailingConstraint.constant = -horizontalInset
        }
    }
    public var tintColorForUnselectedItems: UIColor = UIColor(white: 0.572549, alpha: 0.85)
    public var symbolPointSize: CGFloat = 17.0 {
        didSet {
            buttons.forEach {
                $0.configuration?.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: symbolPointSize, weight: symbolWeight)
            }
        }
    }
    public var symbolWeight: UIImage.SymbolWeight = .regular {
        didSet {
            buttons.forEach {
                $0.configuration?.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: symbolPointSize, weight: symbolWeight)
            }
        }
    }
    public var imagePointSize: CGFloat = 17.0 * 1.618
    public var preferAnimationOnTap: Bool = true
    
    public weak var delegate: CustomTabBarDelegate?
    
    // MARK: - Internal Properties
    
    internal var bottomInset: CGFloat = 0.0 {
        didSet {
            stackViewBottomConstraint?.constant = -bottomInset
        }
    }
    
    // MARK: - Private Properties
    
    private var buttons: [UIButton] = []
    private var regularImages: [UIImage?] = []
    private var selectedImages: [UIImage?] = []
    private var symbolConfiguration: UIImage.SymbolConfiguration {
        return UIImage.SymbolConfiguration(pointSize: symbolPointSize, weight: symbolWeight)
    }
    
    private let stackView: UIStackView = {
        let view = UIStackView()
        view.axis = .horizontal
        view.alignment = .fill
        view.distribution = .fillEqually
        return view
    }()
    private let separator: UIView = {
        let view = UIView()
        view.backgroundColor = .separator
        return view
    }()
    private var stackViewLeadingConstraint: NSLayoutConstraint!
    private var stackViewTrailingConstraint: NSLayoutConstraint!
    private var stackViewBottomConstraint: NSLayoutConstraint!
    
    // MARK: - Internal Methods
    
    internal override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    internal required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    internal func setTabs(numberOfTabs: Int) {
        guard numberOfTabs > 0 else { return }
        
        regularImages = [UIImage?](repeating: nil, count: numberOfTabs)
        selectedImages = [UIImage?](repeating: nil, count: numberOfTabs)
        
        for index in 0...numberOfTabs - 1 {
            
            let button = CustomButton()
            button.tag = index
            
            var configuration = UIButton.Configuration.plain()
            configuration = UIButton.Configuration.plain()
            configuration.baseBackgroundColor = .clear
            configuration.baseForegroundColor = tintColorForUnselectedItems
            configuration.preferredSymbolConfigurationForImage = symbolConfiguration
            configuration.imageColorTransformer = UIConfigurationColorTransformer { [weak self] color in
                guard let self else { return color }
                return button.isSelected ? .tintColor : self.tintColorForUnselectedItems
            }
            button.configuration = configuration
            
            button.configurationUpdateHandler = { [weak self] button in
                guard let self else { return }
                guard button.state == .normal || button.state == .selected else { return }
                
                let image = button.state == .normal ? self.regularImages[button.tag] : self.selectedImages[button.tag]
                
                // resize image here
                var renderedImage: UIImage?
                if let image, !image.isSymbolImage {
                    
                    UIGraphicsBeginImageContextWithOptions(image.size, false, 1)
                    image.draw(at: .zero, blendMode: .normal, alpha: button.state == .normal ? 0.8 : 1)
                    let newImage = UIGraphicsGetImageFromCurrentImageContext()!
                    UIGraphicsEndImageContext()
                    
                    let pointSize = self.imagePointSize
                    let size = CGSize(width: pointSize + 4, height: pointSize + 4)
                    let renderer = UIGraphicsImageRenderer(size: size)
                    renderedImage = renderer.image(actions: { context in
                        
                        if button.state != .normal {
                            let containerRect = CGRect(x: 2, y: 2, width: pointSize, height: pointSize)
                            context.cgContext.setStrokeColor(UIColor.tintColor.cgColor)
                            context.cgContext.setLineWidth(1.6)
                            context.cgContext.addEllipse(in: containerRect)
                            context.cgContext.drawPath(using: .stroke)
                        }
                        
                        let imageRect = CGRect(x: 4, y: 4, width: pointSize - 4, height: pointSize - 4)
                        let circle = UIBezierPath(ovalIn: imageRect)
                        circle.addClip()
                        newImage.draw(in: imageRect)
                    })
                } else {
                    renderedImage = image
                }
                
                button.configuration?.image = renderedImage
            }
            
            button.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
            button.isSelected = index == 0
            
            buttons.append(button)
            
            let container = UIView()
            container.addSubview(button)
            button.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                button.centerXAnchor.constraint(equalTo: container.centerXAnchor),
                button.centerYAnchor.constraint(equalTo: container.centerYAnchor)
            ])
            
            stackView.addArrangedSubview(container)
        }
    }
    
    internal func setImage(_ image: UIImage?, forTab index: Int, state: UIButton.State = .normal) {
        guard index >= 0, index < buttons.count else { return }
        
        if state == .normal {
            regularImages[index] = image
        } else if state == .selected {
            selectedImages[index] = image
        }
    }
    
    // MARK: - Private Methods
    
    private func setup() {
        
        addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackViewLeadingConstraint = stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: horizontalInset)
        stackViewTrailingConstraint = stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -horizontalInset)
        stackViewBottomConstraint = stackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackViewLeadingConstraint,
            stackViewTrailingConstraint,
            stackViewBottomConstraint
        ])
        
        addSubview(separator)
        separator.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            separator.topAnchor.constraint(equalTo: topAnchor),
            separator.leadingAnchor.constraint(equalTo: leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: trailingAnchor),
            separator.heightAnchor.constraint(equalToConstant: 0.3)
        ])
    }
    
    @objc private func buttonTapped(_ sender: UIButton) {
        
        if let delegate, let shouldSelect = delegate.tabBar?(self, shouldSelect: sender.tag), !shouldSelect { return }
        
        if preferAnimationOnTap, let imageView = sender.imageView {
            let animation = CAKeyframeAnimation(keyPath: "transform.scale")
            animation.values = [1.0, 1.08, 1.15, 1.08, 1.0, 0.95, 0.9, 0.95, 1.0, 1.05, 1.0]
            animation.duration = TimeInterval(0.3)
            animation.calculationMode = .cubic
            imageView.layer.add(animation, forKey: nil)
        }
        
        buttons.forEach {
            $0.isSelected = $0 == sender
        }
        
        delegate?.tabBar?(self, didSelect: sender.tag)
    }
}

@MainActor @objc public protocol CustomTabBarDelegate: NSObjectProtocol {
    
    @objc optional func tabBar(_ tabBar: CustomTabBar, shouldSelect index: Int) -> Bool
    
    @objc optional func tabBar(_ tabBar: CustomTabBar, didSelect index: Int)
}

private final class CustomButton: UIButton {
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        return bounds.insetBy(dx: -20, dy: -20).contains(point)
    }
}
