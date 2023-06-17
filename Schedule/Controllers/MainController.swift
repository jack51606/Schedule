import UIKit
import EventKit
import CalendarKit
import CustomTabBarController
import CustomNavigationController
import Lottie

@objc protocol LaunchAnimationDelegate: AnyObject {
    @objc optional func didFinishLaunchAnimation()
}

final class MainController: CustomTabBarController {
    
    // MARK: - Public Properties
    
    public var pages: [Page?] = []
    
    public weak var launchAnimationDelegate: LaunchAnimationDelegate?
    
    // MARK: - Private Properties
    
    private var startPageIndex: Int = 0
    
    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .secondarySystemBackground
        
        tabBar.hideSeparator = true
        
        setPages()
        setTabBarImages()
        
        performLaunchAnimation()
    }
    
    // MARK: - Override Methods
    
    override func tabBar(_ tabBar: CustomTabBar, shouldSelect index: Int) -> Bool {
        guard index == 2 else {
            return super.tabBar(tabBar, shouldSelect: index)
        }
        
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let newEvent = UIAlertAction(title: Strings.newEvent, style: .default) { [weak self] _ in
            guard let self else { return }
            guard let event = CalendarItemsManager.shared.newEvent() else { return }
            
            let hour = CalendarPreferenceManager.shared.calendar.component(.hour, from: Date())
            let date: Date
            if let homeViewController = (self.pages[0]?.rootViewController as? HomeViewController) {
                date = homeViewController.selectedDate
            } else {
                date = CalendarPreferenceManager.shared.calendar.startOfDay(for: Date())
            }
            let startDate = CalendarPreferenceManager.shared.calendar.date(bySettingHour: hour, minute: 0, second: 0, of: date)
            let endDate = CalendarPreferenceManager.shared.calendar.date(bySettingHour: hour + 1, minute: 0, second: 0, of: date)
            event.startDate = startDate
            event.endDate = endDate
            let viewController = CustomNavigationController(rootViewController: EventEditingViewController(event: event))
            viewController.isPresentedModally = true
            
            present(viewController, animated: true)
        }
        
        let newReminder = UIAlertAction(title: Strings.newReminder, style: .default) { [weak self] _ in
            guard let self else { return }
            guard let reminder = CalendarItemsManager.shared.newReminder() else { return }
            
            let viewController = CustomNavigationController(rootViewController: ReminderEditingViewController(reminder: reminder))
            viewController.isPresentedModally = true
            
            present(viewController, animated: true)
        }
        
        let cancelAction = UIAlertAction(title: Strings.cancel, style: .cancel)
        
        alert.addAction(newEvent)
        alert.addAction(newReminder)
        alert.addAction(cancelAction)
        
        present(alert, animated: true)
        
        return false
    }
    
    // MARK: - Private Methods
    
    private func setPages() {
        
        let homeViewController = HomeViewController()
        launchAnimationDelegate = homeViewController
        
        
        pages = [
            Page(rootViewController: homeViewController),
            Page(rootViewController: VC2()),
            nil,
            Page(rootViewController: VC4()),
            Page(rootViewController: SettingsViewController())
        ]
        
        
        setViewControllers(pages)
        selectedIndex = startPageIndex
    }
    
    private func setTabBarImages() {
        
        let images: [UIImage?] = [
            Constants.SFSymbols.house,
            Constants.SFSymbols.checklist,
            Constants.SFSymbols.plusApp,
            Constants.SFSymbols.magnifyingglass,
            Constants.SFSymbols.gear
        ]

        let selectedImages: [UIImage?] = [
            Constants.SFSymbols.houseFill,
            Constants.SFSymbols.checklist,
            Constants.SFSymbols.plusAppFill,
            Constants.SFSymbols.magnifyingglass,
            Constants.SFSymbols.gearFill
        ]
        
        for index in images.indices {
            setTabImage(images[index]?.applyingSymbolConfiguration(UIImage.SymbolConfiguration(weight: .medium)), forIndex: index)
        }
        
        for index in selectedImages.indices {
            setSelectedTabImage(selectedImages[index]?.applyingSymbolConfiguration(UIImage.SymbolConfiguration(weight: .medium)), forIndex: index)
        }
    }
    
    private func performLaunchAnimation() {
        
        tabBar.alpha = 0
        
        let launchAnimationView = LottieAnimationView()
        launchAnimationView.contentMode = .scaleAspectFit
        launchAnimationView.animation = LottieAnimation.named("LogoAnimation")
        
        let animationViewContainer = UIView()
        animationViewContainer.backgroundColor = UIColor(named: "LaunchScreenBackground")
        
        view.addSubview(animationViewContainer)
        view.bringSubviewToFront(animationViewContainer)
        animationViewContainer.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            animationViewContainer.topAnchor.constraint(equalTo: view.topAnchor),
            animationViewContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            animationViewContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            animationViewContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        animationViewContainer.addSubview(launchAnimationView)
        launchAnimationView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            launchAnimationView.centerXAnchor.constraint(equalTo: animationViewContainer.centerXAnchor),
            launchAnimationView.centerYAnchor.constraint(equalTo: animationViewContainer.centerYAnchor)
        ])
        
        launchAnimationView.play { finished in
            if finished {
                UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseInOut) { [weak self] in
                    guard let self else { return }
                    launchAnimationView.alpha = 0
                    animationViewContainer.alpha = 0
                    self.tabBar.alpha = 1
                } completion: { [weak self] completed in
                    guard let self else { return }
                    animationViewContainer.removeFromSuperview()
                    self.launchAnimationDelegate?.didFinishLaunchAnimation?()
                }
            }
        }
    }
}

// ---------------------------------------------------------------------

import Alatsi

class VC1: CustomNavigationChildViewController {
    
    private let titleButton: UIButton = {
        let button = UIButton()
        button.titleLabel?.font = .regularTitle
        button.setTitleColor(.tintColor, for: .normal)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .clear
        
        navigationBar.addSubview(titleButton)
        titleButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            titleButton.centerYAnchor.constraint(equalTo: navigationBar.centerYAnchor),
            titleButton.leadingAnchor.constraint(equalTo: navigationBar.leadingAnchor, constant: 20)
        ])
        
        titleButton.setTitle("Home", for: .normal)
    }
}

class VC2: CustomNavigationChildViewController {
    
    private let titleButton: UIButton = {
        let button = UIButton()
        button.titleLabel?.font = .regularTitle
        button.setTitleColor(.tintColor, for: .normal)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .clear
        
        navigationBar.addSubview(titleButton)
        titleButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            titleButton.centerYAnchor.constraint(equalTo: navigationBar.centerYAnchor),
            titleButton.leadingAnchor.constraint(equalTo: navigationBar.leadingAnchor, constant: 20)
        ])
        
        titleButton.setTitle(Strings.reminders, for: .normal)
    }
}

class VC3: CustomNavigationChildViewController {
    
    private let titleButton: UIButton = {
        let button = UIButton()
        button.titleLabel?.font = .regularTitle
        button.setTitleColor(.tintColor, for: .normal)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .clear
        
        navigationBar.addSubview(titleButton)
        titleButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            titleButton.centerYAnchor.constraint(equalTo: navigationBar.centerYAnchor),
            titleButton.leadingAnchor.constraint(equalTo: navigationBar.leadingAnchor, constant: 20)
        ])
        
        titleButton.setTitle("Add Event", for: .normal)
    }
}

class VC4: CustomNavigationChildViewController {
    
    private let titleButton: UIButton = {
        let button = UIButton()
        button.titleLabel?.font = .regularTitle
        button.setTitleColor(.tintColor, for: .normal)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .clear
        
        navigationBar.addSubview(titleButton)
        titleButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            titleButton.centerYAnchor.constraint(equalTo: navigationBar.centerYAnchor),
            titleButton.leadingAnchor.constraint(equalTo: navigationBar.leadingAnchor, constant: 20)
        ])
        
        titleButton.setTitle(Strings.search, for: .normal)
    }
}

class VC5: CustomNavigationChildViewController {
    
    private let titleButton: UIButton = {
        let button = UIButton()
        button.titleLabel?.font = .regularTitle
        button.setTitleColor(.tintColor, for: .normal)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .clear
        
        navigationBar.addSubview(titleButton)
        titleButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            titleButton.centerYAnchor.constraint(equalTo: navigationBar.centerYAnchor),
            titleButton.leadingAnchor.constraint(equalTo: navigationBar.leadingAnchor, constant: 20)
        ])
        
        titleButton.setTitle(Strings.settings, for: .normal)
    }
}
