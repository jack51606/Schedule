import UIKit
import EventKit
import CalendarKit
import CustomNavigationController

final class EventCalendarEditingViewController: CustomNavigationChildViewController {
    
    // MARK: - Private Properties
    
    private enum Mode {
        case create, edit
    }
    private let mode: Mode
    
    private let calendarItemsManager = CalendarItemsManager.shared
    private let calendar: EKCalendar
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .navigationBarButton
        return label
    }()
    private let cancelButton: UIButton = {
        
        let button = UIButton()
        
        var configuration = UIButton.Configuration.plain()
        
        var attributedTitle = AttributedString(Strings.cancel)
        attributedTitle.font = .navigationBarButton
        configuration.attributedTitle = attributedTitle
        
        configuration.contentInsets.leading = 0
        button.configuration = configuration
        
        return button
    }()
    private let doneButton: UIButton = {
        
        let button = UIButton()
        
        var configuration = UIButton.Configuration.plain()
        
        var attributedTitle = AttributedString(Strings.done)
        attributedTitle.font = .navigationBarButton
        configuration.attributedTitle = attributedTitle
        
        configuration.contentInsets.trailing = 0
        button.configuration = configuration
        
        return button
    }()
    
    private var collectionView: UICollectionView!
    
    private enum Section: CaseIterable {
        
        case title, color, delete
        
        var title: String? {
            switch self {
            case .title:
                return Strings.title
            case .color:
                return Strings.color
            case .delete:
                return nil
            }
        }
    }
    private enum CellName: String, CaseIterable {
        
        case BlankCell
        case TitleCell
        case ColorCell
        case DeleteCell
        
        var tag: Int {
            switch self {
            case .BlankCell:
                return 0
            case .TitleCell:
                return 1
            case .ColorCell:
                return 2
            case .DeleteCell:
                return 3
            }
        }
    }
    
    private let colorIcon: UIImageView = {
        let view = UIImageView()
        view.image = Constants.SFSymbols.circleFill.withConfiguration(UIImage.SymbolConfiguration(pointSize: 14))
        return view
    }()
    private let colorWell: UIColorWell = {
        let colorWell = UIColorWell()
        colorWell.supportsAlpha = false
        return colorWell
    }()
    
    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .secondarySystemBackground
        
        presentationController?.delegate = self
        
        setNavigationItems()
        setCollectionView()
    }
    
    // MARK: - Public Methods
    
    public init(calendar: EKCalendar) {
        
        self.calendar = calendar
        self.mode = calendar.isNew ? .create : .edit
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Private Methods
    
    private func setNavigationItems() {
        
        navigationBar.backgroundColor = view.backgroundColor
        
        titleLabel.text = mode == .create ? Strings.newCalendar : Strings.editCalendar
        cancelButton.addTarget(self, action: #selector(cancelButtonPressed), for: .touchUpInside)
        doneButton.addTarget(self, action: #selector(saveButtonPressed), for: .touchUpInside)
        
        customNavigationItem.titleView = titleLabel
        customNavigationItem.leftBarButtonItem = UIBarButtonItem(customView: cancelButton)
        customNavigationItem.rightBarButtonItem = UIBarButtonItem(customView: doneButton)
        
        doneButton.isEnabled = false
    }
    
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
    
    private func cellName(at indexPath: IndexPath) -> CellName {
        
        switch indexPath {
            
        case IndexPath(item: 0, section: 0):
            return .TitleCell
        case IndexPath(item: 0, section: 1):
            return .ColorCell
        case IndexPath(item: 0, section: 2):
            return .DeleteCell
        default:
            return .BlankCell
        }
    }
    
    private func indexPathForCell(name: CellName) -> IndexPath? {
        
        for section in 0...collectionView.numberOfSections - 1 {
            for item in 0...collectionView.numberOfItems(inSection: section) {
                let indexPath = IndexPath(item: item, section: section)
                if let item = collectionView.cellForItem(at: indexPath) {
                    if item.tag == name.tag {
                        return indexPath
                    }
                }
            }
        }
        
        return nil
    }
    
    private func checkAndSetDoneButtonEnabled() {
        
        if calendar.title.isEmpty || calendar.cgColor == nil {
            doneButton.isEnabled = false
        } else {
            if calendar.isNew {
                doneButton.isEnabled = true
            } else if calendar.hasChanges {
                doneButton.isEnabled = true
            } else {
                doneButton.isEnabled = false
            }
        }
    }
    
    @objc private func cancelButtonPressed() {
        
        if mode == .edit {
            calendar.reset()
        } else {
            calendarItemsManager.deleteEventCalendar(calendar)
        }
        
        dismiss(animated: true)
    }
    
    @objc private func saveButtonPressed() {
        
        calendarItemsManager.saveEventCalendar(calendar)
        
        dismiss(animated: true)
    }
    
    @objc private func titleTextFieldTextDidChange(_ sender: UITextField) {
        guard let text = sender.text else { return }
        
        calendar.title = text
        checkAndSetDoneButtonEnabled()
    }
    
    @objc private func colorTextFieldTextDidChange(_ sender: UITextField) {
        guard let hex = sender.text, let color = UIColor(hex: hex) else { return }
        
        colorIcon.tintColor = color
        colorWell.selectedColor = color
        
        guard color.cgColor != calendar.cgColor else { return }
        
        calendar.cgColor = color.cgColor
        checkAndSetDoneButtonEnabled()
    }
    
    @objc private func colorWellColorDidChange(_ sender: UIColorWell) {
        guard let color = sender.selectedColor else { return }
        
        colorIcon.tintColor = color
        colorWell.selectedColor = color
        if let indexPath = indexPathForCell(name: .ColorCell), let cell = collectionView.cellForItem(at: indexPath), let textField = cell.viewWithTag(1) as? UITextField {
            
            textField.text = color.hex
        }
        
        guard color.cgColor != calendar.cgColor else { return }
        
        calendar.cgColor = color.cgColor
        checkAndSetDoneButtonEnabled()
    }
}

extension EventCalendarEditingViewController: UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        
        if mode == .create || calendar.type == .birthday {
            return Section.allCases.count - 1
        } else {
            return Section.allCases.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: SectionHeader.identifier, for: indexPath) as! SectionHeader
        
        if let title = Section.allCases[indexPath.section].title {
            header.setTitle(title)
        }
        
        return header
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        switch Section.allCases[section] {
        case .title:
            return 1
        case .color:
            return 1
        case .delete:
            return 1
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: UICollectionViewListCell.self.description(), for: indexPath) as! UICollectionViewListCell
        
        let cellName = cellName(at: indexPath)
        switch cellName {
        case .BlankCell:
            break
        case .TitleCell:
            
            var configuration = TextFieldConfiguration()
            
            configuration.textField.delegate = self
            
            configuration.textField.addTarget(self, action: #selector(titleTextFieldTextDidChange), for: .editingChanged)
            
            configuration.contentInsets.leading = 20
            configuration.height = 48
            configuration.textField.clearButtonMode = .whileEditing
            configuration.textField.font = .rounded(ofSize: 19)
            if calendar.type == .birthday {
                configuration.textField.isEnabled = false
                configuration.textField.textColor = .secondaryLabel
            }
            
            configuration.textField.placeholder = Strings.title
            configuration.textField.text = calendar.title
            if calendar.isNew {
                configuration.textField.becomeFirstResponder()
            }
            
            cell.contentConfiguration = configuration
            
        case .ColorCell:
            
            var configuration = TextFieldConfiguration()
            
            configuration.textField.delegate = self
            configuration.textField.tag = 1
            
            configuration.textField.addTarget(self, action: #selector(colorTextFieldTextDidChange), for: .editingChanged)
            
            configuration.height = 48
            configuration.textField.clearButtonMode = .whileEditing
            configuration.textField.font = .rounded(ofSize: 19)
            configuration.textField.autocapitalizationType = .allCharacters
            
            configuration.textField.placeholder = Strings.color
            var color: UIColor {
                if let calendarColor = calendar.cgColor {
                    return UIColor(cgColor: calendarColor)
                } else {
                    return .tintColor
                }
            }
            configuration.textField.text = color.hex
            
            cell.contentConfiguration = configuration
            
            colorIcon.tintColor = color
            colorWell.selectedColor = color
            
            colorWell.addTarget(self, action: #selector(colorWellColorDidChange), for: .valueChanged)
            
            let colorIconAccessoryViewConfiguration = UICellAccessory.CustomViewConfiguration(customView: colorIcon, placement: .leading(), reservedLayoutWidth: .actual)
            
            let colorWellAccessoryViewConfiguration = UICellAccessory.CustomViewConfiguration(customView: colorWell, placement: .trailing())
            
            cell.accessories = [.customView(configuration: colorIconAccessoryViewConfiguration), .customView(configuration: colorWellAccessoryViewConfiguration)]
            
        case .DeleteCell:
            
            var configuration = LabelConfiguration()
            
            configuration.height = 48
            configuration.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20)
            configuration.label.font = .rounded(ofSize: 19)
            configuration.label.textColor = .systemRed
            configuration.label.textAlignment = .center
            configuration.label.text = calendar.type == .subscription ? Strings.unsubscribe : Strings.deleteCalendar
            
            cell.contentConfiguration = configuration
        }
        
        var backgroundConfiguration = cell.backgroundConfiguration
        backgroundConfiguration?.backgroundColor = .tertiarySystemBackground
        cell.backgroundConfiguration = backgroundConfiguration
        
        cell.tag = cellName.tag
        
        return cell
    }
}

extension EventCalendarEditingViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        collectionView.deselectItem(at: indexPath, animated: true)
        
        let cellName = cellName(at: indexPath)
        
        switch cellName {
        case .DeleteCell:
            let alertTitle = calendar.type == .subscription ? Strings.sureToUnsubscribeFrom + " \"\(calendar.title)\"" + Strings.questionMark : Strings.sureToDelete + " \"\(calendar.title)\"" + Strings.questionMark
            let alert = UIAlertController(title: alertTitle, message: nil, preferredStyle: .actionSheet)
            let deleteActionTitle = calendar.type == .subscription ? Strings.unsubscribe : Strings.deleteCalendar
            let deleteAction = UIAlertAction(title: deleteActionTitle, style: .destructive) { [weak self] _ in
                guard let self else { return }
                
                calendarItemsManager.deleteEventCalendar(calendar)
                
                dismiss(animated: true)
            }
            let cancelAction = UIAlertAction(title: Strings.cancel, style: .cancel)
            alert.addAction(deleteAction)
            alert.addAction(cancelAction)
            present(alert, animated: true)
        default:
            break
        }
    }
}

extension EventCalendarEditingViewController: UIAdaptivePresentationControllerDelegate {
    
    func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        
        // 隱藏鍵盤
        view.endEditing(true)
        
        switch mode {
        case .create:
            return calendar.title.isEmpty && calendar.cgColor == nil
        case .edit:
            return !calendar.hasChanges
        }
    }
    
    func presentationControllerDidAttemptToDismiss(_ presentationController: UIPresentationController) {
        
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let discardAction = UIAlertAction(title: Strings.discardChanges, style: .destructive) { [weak self] _ in
            guard let self else { return }
            
            if mode == .edit {
                calendar.reset()
            } else {
                calendarItemsManager.deleteEventCalendar(calendar)
            }
            
            dismiss(animated: true)
        }
        let cancelAction = UIAlertAction(title: Strings.cancel, style: .cancel)
        alert.addAction(discardAction)
        alert.addAction(cancelAction)
        present(alert, animated: true)
    }
    
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        
        if calendar.isNew {
            calendarItemsManager.deleteEventCalendar(calendar)
        }
    }
}

extension EventCalendarEditingViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        view.endEditing(true)
        
        return true
    }
}
