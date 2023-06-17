import UIKit
import EventKit

@objc protocol ReminderCellDelegate: AnyObject {
    @objc optional func didExpand(_ isExpanded: Bool, reminder: EKReminder)
}

final class ReminderCell: UICollectionViewCell {
    
    // MARK: - Public Properties
    
    public static let identifier = "ReminderCell"
    
    public weak var delegate: ReminderCellDelegate?
    
    public private (set) var reminder: EKReminder?
    
    // MARK: - Private Properties
    
    private var overdueTimer: Timer?
    private var completionTimer: Timer?
    private let calendarItemsManager = CalendarItemsManager.shared
    
    private let completeButton: CustomButton = {
        let button = CustomButton()
        button.setImage(Constants.SFSymbols.square.withConfiguration(UIImage.SymbolConfiguration(pointSize: 16)), for: .normal)
        button.setImage(Constants.SFSymbols.checkmarkSquare.withConfiguration(UIImage.SymbolConfiguration(pointSize: 16)), for: .selected)
        return button
    }()
    private let priorityIcon: UIImageView = {
        let view = UIImageView()
        view.tintColor = .clear
        return view
    }()
    private let recurrenceIcon: UIImageView = {
        let view = UIImageView()
        view.tintColor = .secondaryLabel
        return view
    }()
    private let expandButton: CustomButton = {
        let button = CustomButton()
        button.setImage(Constants.SFSymbols.chevronDown.withConfiguration(UIImage.SymbolConfiguration(pointSize: 12)), for: .normal)
        button.setImage(Constants.SFSymbols.chevronUp.withConfiguration(UIImage.SymbolConfiguration(pointSize: 12)), for: .selected)
        button.tintColor = .placeholderText
        return button
    }()
    private let titleLabel: TitleLabel = {
        let label = TitleLabel()
        label.font = .rounded(ofSize: 19)
        label.padding = UIEdgeInsets(top: 3, left: 0, bottom: 3, right: 0)
        return label
    }()
    private let timeLabel: UILabel = {
        let label = UILabel()
        label.font = .rounded(ofSize: 16)
        label.textAlignment = .right
        return label
    }()
    private let notesLabel: UILabel = {
        let label = UILabel()
        label.font = .rounded(ofSize: 16)
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        return label
    }()
    
    private var titleLabelIntrinsicHeight: CGFloat!
    private var titleLabelLeadingConstraint: NSLayoutConstraint!
    private var timeLabelLeadingConstraint: NSLayoutConstraint!
    private var timeLabelTrailingConstraint: NSLayoutConstraint!
    
    private var isExpanded: Bool = false {
        didSet {
            expandButton.isSelected = isExpanded
            titleLabel.numberOfLines = isExpanded ? 0 : 1
            notesLabel.text = isExpanded ? reminder?.notes : nil
            UIView.performWithoutAnimation {
                invalidateIntrinsicContentSize()
            }
        }
    }
    
    // MARK: - Override Methods
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        // Global Settings
        contentView.layoutMargins = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
        let anchors = contentView.layoutMarginsGuide
        
        titleLabel.text = "Title"
        titleLabelIntrinsicHeight = titleLabel.intrinsicContentSize.height
        
        // Set CompletedButton
        completeButton.addTarget(self, action: #selector(completeButtonPressed), for: .touchUpInside)
        contentView.addSubview(completeButton)
        completeButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            completeButton.centerYAnchor.constraint(equalTo: anchors.topAnchor, constant: titleLabelIntrinsicHeight / 2),
            completeButton.leadingAnchor.constraint(equalTo: anchors.leadingAnchor)
        ])
        completeButton.setContentHuggingPriority(UILayoutPriority(251), for: .horizontal)
        completeButton.setContentCompressionResistancePriority(UILayoutPriority(751), for: .horizontal)
        
        // Set PriorityIcon
        contentView.addSubview(priorityIcon)
        priorityIcon.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            priorityIcon.centerYAnchor.constraint(equalTo: anchors.topAnchor, constant: titleLabelIntrinsicHeight / 2),
            priorityIcon.leadingAnchor.constraint(equalTo: completeButton.trailingAnchor, constant: 8)
        ])
        priorityIcon.setContentHuggingPriority(UILayoutPriority(251), for: .horizontal)
        priorityIcon.setContentCompressionResistancePriority(UILayoutPriority(751), for: .horizontal)
        
        // Set RecurrenceIcon
        contentView.addSubview(recurrenceIcon)
        recurrenceIcon.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            recurrenceIcon.centerYAnchor.constraint(equalTo: anchors.topAnchor, constant: titleLabelIntrinsicHeight / 2),
            recurrenceIcon.trailingAnchor.constraint(equalTo: anchors.trailingAnchor)
        ])
        recurrenceIcon.setContentHuggingPriority(UILayoutPriority(251), for: .horizontal)
        recurrenceIcon.setContentCompressionResistancePriority(UILayoutPriority(751), for: .horizontal)
        
        // Set TitleLabel
        contentView.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabelLeadingConstraint = titleLabel.leadingAnchor.constraint(equalTo: completeButton.trailingAnchor, constant: 8)
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: anchors.topAnchor),
            titleLabelLeadingConstraint
        ])
        
        // Set TimeLabel
        contentView.addSubview(timeLabel)
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        timeLabelLeadingConstraint = timeLabel.leadingAnchor.constraint(greaterThanOrEqualTo: titleLabel.trailingAnchor, constant: 12)
        timeLabelTrailingConstraint = timeLabel.trailingAnchor.constraint(equalTo: anchors.trailingAnchor)
        NSLayoutConstraint.activate([
            timeLabel.centerYAnchor.constraint(equalTo: anchors.topAnchor, constant: titleLabelIntrinsicHeight / 2),
            timeLabelLeadingConstraint,
            timeLabelTrailingConstraint
        ])
        timeLabel.setContentHuggingPriority(UILayoutPriority(251), for: .horizontal)
        timeLabel.setContentCompressionResistancePriority(UILayoutPriority(751), for: .horizontal)
        
        // Set NotesLabel
        contentView.addSubview(notesLabel)
        notesLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            notesLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor),
            notesLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            notesLabel.trailingAnchor.constraint(equalTo: timeLabel.leadingAnchor, constant: -30),
            notesLabel.bottomAnchor.constraint(equalTo: anchors.bottomAnchor)
        ])
        
        // Set Expand Button
        expandButton.addTarget(self, action: #selector(expandButtonPressed), for: .touchUpInside)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        // Texts
        titleLabel.text = nil
        timeLabel.text = nil
        notesLabel.text = nil
        
        // Buttons & Icons
        completeButton.isSelected = false
        expandButton.isSelected = false
        priorityIcon.image = nil
        recurrenceIcon.image = nil
        
        // Colors
        priorityIcon.tintColor = .clear
        recurrenceIcon.tintColor = .secondaryLabel
        titleLabel.textColor = .label
        notesLabel.textColor = .secondaryLabel
        timeLabel.textColor = .label
        
        // Timers
        overdueTimer?.invalidate()
        overdueTimer = nil
        completionTimer?.invalidate()
        completionTimer = nil
        
        // Expansion
        isExpanded = false
        expandButton.removeFromSuperview()
        
        // Constraints
        titleLabelLeadingConstraint.constant = 8
        timeLabelLeadingConstraint.constant = 12
        timeLabelTrailingConstraint.constant = 0
        
        // Reminder
        reminder = nil
    }
    
    // MARK: - Public Methods
    
    public func configure(with reminder: EKReminder, expand: Bool = false) {
        
        self.reminder = reminder
        
        // Complete Button
        completeButton.tintColor = UIColor(cgColor: reminder.calendar.cgColor)
        
        // Priority Icon
        switch reminder.priority {
        case 1:
            priorityIcon.image = Constants.SFSymbols.exclamationmark3.withConfiguration(UIImage.SymbolConfiguration(pointSize: 16))
        case 5:
            priorityIcon.image = Constants.SFSymbols.exclamationmark2.withConfiguration(UIImage.SymbolConfiguration(pointSize: 16))
        case 9:
            priorityIcon.image = Constants.SFSymbols.exclamationmark.withConfiguration(UIImage.SymbolConfiguration(pointSize: 16))
        default:
            priorityIcon.image = nil
        }
        
        // Title Label
        titleLabel.text = reminder.title
        
        // Time Label
        if let dateComponents = reminder.dueDateComponents, dateComponents.hour != nil {
            timeLabel.text = dateComponents.date!.formatted(date: .omitted, time: .shortened)
        } else {
            timeLabel.text = nil
        }
        
        // Recurrence Icon
        if reminder.hasRecurrenceRules {
            recurrenceIcon.image = Constants.SFSymbols.cycle.withConfiguration(UIImage.SymbolConfiguration(pointSize: 12))
        } else {
            recurrenceIcon.image = nil
        }
        
        // Update Constraints
        if reminder.priority != 0 {
            titleLabelLeadingConstraint.constant = priorityIcon.intrinsicContentSize.width + 14
        }
        if reminder.hasRecurrenceRules {
            timeLabelTrailingConstraint.constant = -24
        }
        
        // Set ExpandButton
        titleLabel.layoutIfNeeded()
        if titleLabel.isTruncated || reminder.hasNotes {
            timeLabelLeadingConstraint.constant = 36
            contentView.addSubview(expandButton)
            expandButton.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                expandButton.centerYAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor, constant: titleLabelIntrinsicHeight / 2),
                expandButton.trailingAnchor.constraint(equalTo: timeLabel.leadingAnchor, constant: -15)
            ])
            expandButton.setContentHuggingPriority(UILayoutPriority(251), for: .horizontal)
            expandButton.setContentCompressionResistancePriority(UILayoutPriority(751), for: .horizontal)
        }
        
        // Set Completion
        setCompleted(reminder.isCompleted)
        
        // Set Expanded
        isExpanded = expand
        
//        contentView.backgroundColor = .orange.withAlphaComponent(0.3)
//        completedButton.backgroundColor = .blue.withAlphaComponent(0.3)
//        priorityIcon.backgroundColor = .red.withAlphaComponent(0.3)
//        titleLabel.backgroundColor = .green.withAlphaComponent(0.3)
//        timeLabel.backgroundColor = .purple.withAlphaComponent(0.3)
//        recurrenceIcon.backgroundColor = .systemIndigo.withAlphaComponent(0.3)
//        expandButton.backgroundColor = .systemPink.withAlphaComponent(0.3)
    }
    
    public func didEndDisplay() {
        
        saveCompletionState()
    }
    
    // MARK: - Private Methods
    
    private func setCompleted(_ completed: Bool) {
        guard let reminder else { return }
        
        reminder.isCompleted = completed
        completeButton.isSelected = completed
        priorityIcon.tintColor = completed ? .placeholderText : (reminder.priority != 0 ? UIColor(cgColor: reminder.calendar.cgColor) : .clear)
        recurrenceIcon.tintColor = completed ? .placeholderText : .secondaryLabel
        titleLabel.textColor = completed ? .placeholderText : .label
        notesLabel.textColor = completed ? .placeholderText : .secondaryLabel
        if completed {
            timeLabel.textColor = .placeholderText
        } else if let dueDate = reminder.dueDateComponents?.date {
            timeLabel.textColor = dueDate <= Date() ? .systemRed : .label
        }
        
        if completed {
            overdueTimer?.invalidate()
            overdueTimer = nil
        } else if let dueDate = reminder.dueDateComponents?.date, dueDate > Date() {
            overdueTimer = Timer(fireAt: dueDate, interval: 0, target: self, selector: #selector(overdueTimerFired), userInfo: nil, repeats: false)
            RunLoop.main.add(overdueTimer!, forMode: .common)
        }
    }
    
    private func saveCompletionState() {
        guard let reminder else { return }
        guard let completionTimer, completionTimer.isValid else { return }
        
        let currentDueDate = reminder.dueDateComponents?.date
        let isCompleted = reminder.isCompleted
        
        calendarItemsManager.saveCompletionState(for: reminder)
        
        if isCompleted, reminder.hasRecurrenceRules, let currentDueDate, let nextDueDate = reminder.dueDateComponents?.date, CalendarPreferenceManager.shared.calendar.isDate(nextDueDate, inSameDayAs: currentDueDate) {
            configure(with: reminder, expand: isExpanded)
        }
    }
    
    @objc private func completeButtonPressed(_ sender: UIButton) {
        
        // 產生觸覺回饋
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
        
        sender.isSelected.toggle()
        setCompleted(sender.isSelected)
        
        completionTimer?.invalidate()
        completionTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false, block: { [weak self] timer in
            
            self?.saveCompletionState()
            self?.completionTimer?.invalidate()
            self?.completionTimer = nil
        })
    }
    
    @objc private func expandButtonPressed(_ sender: UIButton) {
        guard let reminder else { return }
        
        isExpanded = !sender.isSelected
        delegate?.didExpand?(isExpanded, reminder: reminder)
    }
    
    @objc private func overdueTimerFired() {
        
        timeLabel.textColor = .systemRed
        
        overdueTimer?.invalidate()
        overdueTimer = nil
    }
}
