import UIKit
import CustomNavigationController

class SettingsViewChildViewController: CustomNavigationChildViewController {
    
    // MARK: - Private Properties
    
    private let backButton: UIButton = {
        
        let button = UIButton()
        
        var configuration = UIButton.Configuration.plain()
        
        var attributedTitle = AttributedString(Strings.back)
        attributedTitle.font = .navigationBarButton
        configuration.attributedTitle = attributedTitle
        
        let imageConfiguration = UIImage.SymbolConfiguration(font: UIFont.navigationBarButton, scale: .small)
        configuration.image = Constants.SFSymbols.chevronLeft.withConfiguration(imageConfiguration)
        configuration.imagePlacement = .leading
        configuration.imagePadding = 5
        
        configuration.contentInsets.leading = 0
        button.configuration = configuration
        
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        backButton.addAction(UIAction(handler: { [weak self] _ in
            self?.navigationController?.popViewController(animated: true)
        }), for: .touchUpInside)
        navigationBar.addSubview(backButton)
        backButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            backButton.centerYAnchor.constraint(equalTo: navigationBar.centerYAnchor),
            backButton.leadingAnchor.constraint(equalTo: navigationBar.leadingAnchor, constant: 20)
        ])
    }
}
