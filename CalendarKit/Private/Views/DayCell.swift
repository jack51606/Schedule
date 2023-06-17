import UIKit

final class DayCell: UICollectionViewCell {
    
    // MARK: - Public Properties
    
    public static let identifier = "DayCell"
    public var day: Int? {
        didSet {
            if let day {
                dayLabel.text = String(day)
            } else {
                dayLabel.text = nil
            }
        }
    }
    public override var isSelected: Bool {
        didSet {
            setSelected(isSelected)
        }
    }
    public var isWeekend = false
    public var isToday = false {
        didSet {
            setToday(isToday)
        }
    }
    
    // MARK: - Private Properties
    
    private static let fontSize: CGFloat = 19
    private static let textColor: UIColor = {
        return UIColor { traitCollection in
            if traitCollection.userInterfaceStyle != .dark {
                return .tertiarySystemGroupedBackground.resolvedColor(with: UITraitCollection(userInterfaceStyle: .dark))
            } else {
                return .tertiarySystemGroupedBackground.resolvedColor(with: UITraitCollection(userInterfaceStyle: .light))
            }
        }
    }()
    private var items = [Item]()
    private var dayLabel: PaddingLabel = {
        let label = PaddingLabel()
        label.font = .rounded(ofSize: fontSize)
        label.textAlignment = .center
        label.padding = UIEdgeInsets(top: 2, left: 4, bottom: 2, right: 4)
        label.layer.cornerRadius = 8
        label.clipsToBounds = true
        return label
    }()
    private let iconsView: UIStackView = {
        let view = UIStackView()
        view.axis = .horizontal
        view.alignment = .center
        view.distribution = .equalSpacing
        view.spacing = 1
        view.heightAnchor.constraint(equalToConstant: 6).isActive = true
        return view
    }()
    
    private var dotIcon: UIImage {
        return Constants.SFSymbols.circleFill.withConfiguration(UIImage.SymbolConfiguration(pointSize: 5)).withRenderingMode(.alwaysOriginal)
    }
    private var checkmarkIcon: UIImage {
        return Constants.SFSymbols.checkmark.withConfiguration(UIImage.SymbolConfiguration(pointSize: 5, weight: .bold)).withRenderingMode(.alwaysOriginal)
    }
    private var ellipsisIcon: UIImage {
        return Constants.SFSymbols.ellipsis.withConfiguration(UIImage.SymbolConfiguration(pointSize: 5, weight: .bold)).withRenderingMode(.alwaysOriginal)
    }
    
    // MARK: - Override Methods
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let stackView: UIStackView = {
            let view = UIStackView()
            view.axis = .vertical
            view.alignment = .center
            view.distribution = .fill
            view.spacing = 3
            return view
        }()
        stackView.addArrangedSubview(dayLabel)
        stackView.addArrangedSubview(iconsView)
        
        contentView.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            stackView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
        
        updateIconsView()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        dayLabel.text = nil
        isWeekend = false
        updateItems(items: [], withUIupdate: true)
    }
    
    // MARK: - Public Methods
    
    public func updateItems(items: [Item], withUIupdate: Bool) {

        self.items = items
        if withUIupdate {
            updateIconsView()
        }
    }
    
    // MARK: - Private Methods
    
    private func setSelected(_ selected: Bool) {
        if selected {
            dayLabel.backgroundColor = isToday ? .tintColor : Self.textColor
            dayLabel.textColor = isToday ? .tertiarySystemGroupedBackground.resolvedColor(with: UITraitCollection(userInterfaceStyle: .light)) : .tertiarySystemGroupedBackground
            dayLabel.font = .rounded(ofSize: Self.fontSize, weight: .medium)
        } else {
            dayLabel.backgroundColor = .clear
            dayLabel.textColor = isToday ? .tintColor : (isWeekend ? .secondaryLabel : Self.textColor)
            dayLabel.font = .rounded(ofSize: Self.fontSize, weight: isToday ? .medium : .regular)
        }
    }
    
    private func setToday(_ today: Bool) {
        if today {
            dayLabel.backgroundColor = isSelected ? .tintColor : .clear
            dayLabel.textColor = isSelected ? .tertiarySystemGroupedBackground.resolvedColor(with: UITraitCollection(userInterfaceStyle: .light)) : .tintColor
            dayLabel.font = .rounded(ofSize: Self.fontSize, weight: .medium)
        } else {
            dayLabel.backgroundColor = isSelected ? Self.textColor : .clear
            dayLabel.textColor = isSelected ? .tertiarySystemGroupedBackground : (isWeekend ? .secondaryLabel : Self.textColor)
            dayLabel.font = .rounded(ofSize: Self.fontSize, weight: isSelected ? .medium : .regular)
        }
    }
    
    private func updateIconsView() {
        
        for icon in iconsView.arrangedSubviews {
            icon.removeFromSuperview()
        }
        
        for index in items.indices {
            
            if index >= 4 {
                iconsView.addArrangedSubview(UIImageView(image: ellipsisIcon.withTintColor(.label)))
                break
            }
            
            let item = items[index]
            let image = item.type == .event ? dotIcon : checkmarkIcon
            iconsView.addArrangedSubview(UIImageView(image: image.withTintColor(item.color)))
        }
    }
}
