import UIKit
import EventKit

@objc protocol EventCellDelegate: AnyObject {
    @objc optional func replacementTitle(withOriginalTitle originalTitle: String) -> String?
    @objc optional func replacementAttributedTitle(withOriginalTitle originalTitle: String, originalFont: UIFont) -> NSAttributedString?
}

final class EventCell: UICollectionViewCell {
    
    // MARK: - Public Properties
    
    public static let identifier = "EventCell"
    
    public weak var delegate: EventCellDelegate?
    
    public private (set) var event: EKEvent?
    
    // MARK: - Private Properties
    
    private var date: Date?
    private var calendar: Calendar {
        return CalendarPreferenceManager.shared.calendar
    }
    
    private var eventEndedTimer: Timer?
    
    private let indicatorBar: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 2
        view.layer.masksToBounds = true
        return view
    }()
    private let titleLabel: TitleLabel = {
        let label = TitleLabel()
        label.font = .rounded(ofSize: 19)
        label.padding = UIEdgeInsets(top: 2, left: 0, bottom: 2, right: 0)
        return label
    }()
    private let startTimeLabel: UILabel = {
        let label = UILabel()
        label.font = .rounded(ofSize: 16)
        label.textAlignment = .right
        return label
    }()
    private let locationLabel: UILabel = {
        let label = UILabel()
        label.font = .rounded(ofSize: 16)
        label.textColor = .secondaryLabel
        return label
    }()
    private let endTimeLabel: UILabel = {
        let label = UILabel()
        label.font = .rounded(ofSize: 16)
        label.textColor = .secondaryLabel
        label.textAlignment = .right
        return label
    }()
    
    private var isTitleLabelUsingAttributedText: Bool = false
    
    private var locationLabelBottomConstraint: NSLayoutConstraint!
    private var endTimeLabelBottomConstraint: NSLayoutConstraint!
    
    // MARK: - Override Methods
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        // Global Settings
        contentView.layoutMargins = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
        let anchors = contentView.layoutMarginsGuide
        
        // Set IndicatorBar
        contentView.addSubview(indicatorBar)
        indicatorBar.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            indicatorBar.leadingAnchor.constraint(equalTo: anchors.leadingAnchor),
            indicatorBar.widthAnchor.constraint(equalToConstant: 4),
            indicatorBar.topAnchor.constraint(equalTo: anchors.topAnchor, constant: 2),
            indicatorBar.bottomAnchor.constraint(equalTo: anchors.bottomAnchor, constant: -2)
        ])
        indicatorBar.setContentHuggingPriority(UILayoutPriority(251), for: .horizontal)
        indicatorBar.setContentCompressionResistancePriority(UILayoutPriority(751), for: .horizontal)
        
        // Set TitleLabel
        contentView.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: anchors.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: indicatorBar.trailingAnchor, constant: 8)
        ])
        
        // Set StartTimeLabel
        contentView.addSubview(startTimeLabel)
        startTimeLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            startTimeLabel.topAnchor.constraint(equalTo: anchors.topAnchor),
            startTimeLabel.bottomAnchor.constraint(equalTo: titleLabel.bottomAnchor),
            startTimeLabel.trailingAnchor.constraint(equalTo: anchors.trailingAnchor),
            startTimeLabel.leadingAnchor.constraint(greaterThanOrEqualTo: titleLabel.trailingAnchor, constant: 12)
        ])
        startTimeLabel.setContentHuggingPriority(UILayoutPriority(251), for: .horizontal)
        startTimeLabel.setContentCompressionResistancePriority(UILayoutPriority(751), for: .horizontal)
        
        // Set LocationLabel
        contentView.addSubview(locationLabel)
        locationLabel.translatesAutoresizingMaskIntoConstraints = false
        locationLabelBottomConstraint = locationLabel.bottomAnchor.constraint(equalTo: anchors.bottomAnchor)
        NSLayoutConstraint.activate([
            locationLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor),
            locationLabel.leadingAnchor.constraint(equalTo: indicatorBar.trailingAnchor, constant: 8),
            locationLabelBottomConstraint
        ])
        
        // Set EndTimeLabel
        contentView.addSubview(endTimeLabel)
        endTimeLabel.translatesAutoresizingMaskIntoConstraints = false
        endTimeLabelBottomConstraint = endTimeLabel.bottomAnchor.constraint(equalTo: anchors.bottomAnchor)
        NSLayoutConstraint.activate([
            endTimeLabel.topAnchor.constraint(equalTo: startTimeLabel.bottomAnchor),
            endTimeLabel.trailingAnchor.constraint(equalTo: anchors.trailingAnchor),
            endTimeLabel.leadingAnchor.constraint(greaterThanOrEqualTo: locationLabel.trailingAnchor, constant: 12),
            endTimeLabelBottomConstraint
        ])
        endTimeLabel.setContentHuggingPriority(UILayoutPriority(251), for: .horizontal)
        endTimeLabel.setContentCompressionResistancePriority(UILayoutPriority(751), for: .horizontal)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        // Texts
        titleLabel.text = nil
        titleLabel.attributedText = nil
        isTitleLabelUsingAttributedText = false
        startTimeLabel.text = nil
        locationLabel.text = nil
        endTimeLabel.text = nil
        
        // Colors
        indicatorBar.backgroundColor = .clear
        titleLabel.textColor = .label
        startTimeLabel.textColor = .label
        locationLabel.textColor = .secondaryLabel
        endTimeLabel.textColor = .secondaryLabel
        
        // Timers
        eventEndedTimer?.invalidate()
        eventEndedTimer = nil
        
        // Constraints
        locationLabelBottomConstraint.constant = 0
        endTimeLabelBottomConstraint.constant = 0
        
        // Event
        event = nil
    }
    
    // MARK: - Public Methods
    
    public func configure(with event: EKEvent, date: Date, setEventEndedOnlyOnToday: Bool = false) {
        
        self.event = event
        self.date = date
        
        // Indicator Bar
        indicatorBar.backgroundColor = UIColor(cgColor: event.calendar.cgColor)
        
        // Title Label
        if let replacementAttributedTitle = delegate?.replacementAttributedTitle?(withOriginalTitle: event.title, originalFont: titleLabel.font) {
            titleLabel.attributedText = replacementAttributedTitle
            isTitleLabelUsingAttributedText = true
        } else if let replacementTitle = delegate?.replacementTitle?(withOriginalTitle: event.title) {
            titleLabel.text = replacementTitle
            isTitleLabelUsingAttributedText = false
        } else {
            titleLabel.text = event.title
            isTitleLabelUsingAttributedText = false
        }
        
        // Start Time Label & End Time Label
        if event.isAllDay {
            startTimeLabel.text = Strings.allDay
            endTimeLabel.text = nil
        } else {
            if event.startDate <= calendar.startOfDay(for: date) && calendar.component(.day, from: event.endDate) != calendar.component(.day, from: date) { // 當天凌晨 12 點或之前開始，午夜 12 點或之後結束
                startTimeLabel.text = Strings.allDay
            } else if event.startDate <= calendar.startOfDay(for: date) { // 當天凌晨 12 點或之前開始
                startTimeLabel.text = "-"
                endTimeLabel.text = event.endDate.formatted(date: .omitted, time: .shortened)
            } else if calendar.component(.day, from: event.endDate) != calendar.component(.day, from: date) { // 午夜 12 點或之後結束
                startTimeLabel.text = event.startDate.formatted(date: .omitted, time: .shortened)
                endTimeLabel.text = "-"
            } else {
                startTimeLabel.text = event.startDate.formatted(date: .omitted, time: .shortened)
                endTimeLabel.text = event.endDate.formatted(date: .omitted, time: .shortened)
            }
        }
        
        // Location Label
        if let location = event.location {
            locationLabel.text = location
        } else {
            locationLabel.text = nil
        }
        
        // Update Constraints
        if locationLabel.text != nil || endTimeLabel.text != nil {
            locationLabelBottomConstraint.constant = -2
            endTimeLabelBottomConstraint.constant = -2
        }
        
        // Check & Set Ended/Timer
        func checkAndSetEventEnded() {
            guard let endDate = event.endDate else { return }
            
            if Date() > endDate { // 過期了，Set Overdue
                if !isTitleLabelUsingAttributedText {
                    titleLabel.textColor = .placeholderText
                }
                locationLabel.textColor = .placeholderText
                startTimeLabel.textColor = .placeholderText
                endTimeLabel.textColor = .placeholderText
                eventEndedTimer?.invalidate()
                eventEndedTimer = nil
            } else { // 還沒過期，Set Timer
                eventEndedTimer = Timer(fireAt: endDate, interval: 0, target: self, selector: #selector(eventEndedTimerFired), userInfo: nil, repeats: false)
                RunLoop.main.add(eventEndedTimer!, forMode: .common)
            }
        }
        if setEventEndedOnlyOnToday {
            // event 為非整天，event 在今天之內結束
            guard calendar.isDateInToday(date), !event.isAllDay, calendar.component(.day, from: event.endDate) == calendar.component(.day, from: date) else { return }
            
            checkAndSetEventEnded()
            
        } else {
            
            checkAndSetEventEnded()
        }
        
//        contentView.backgroundColor = .orange.withAlphaComponent(0.3)
//        titleLabel.backgroundColor = .green.withAlphaComponent(0.3)
//        startTimeLabel.backgroundColor = .purple.withAlphaComponent(0.3)
//        locationLabel.backgroundColor = .red.withAlphaComponent(0.3)
//        endTimeLabel.backgroundColor = .yellow.withAlphaComponent(0.3)
    }
    
    // MARK: - Private Methods
    
    @objc private func eventEndedTimerFired() {
        
        if !isTitleLabelUsingAttributedText {
            titleLabel.textColor = .placeholderText
        }
        locationLabel.textColor = .placeholderText
        startTimeLabel.textColor = .placeholderText
        endTimeLabel.textColor = .placeholderText
        
        eventEndedTimer?.invalidate()
        eventEndedTimer = nil
    }
}
