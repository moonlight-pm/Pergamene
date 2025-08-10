import UIKit

// MARK: - Settings Notifications

extension Notification.Name {
    static let settingsChanged = Notification.Name("settingsChanged")
}

// MARK: - SettingsViewController

/// Displays app settings in a parchment-styled overlay panel
/// Currently manages verse number visibility settings
class SettingsViewController: UIViewController {
    
    // MARK: - UI Components
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let titleLabel = UILabel()
    private let closeButton = UIButton()
    
    // Settings controls
    private let verseNumbersSwitch = UISwitch()
    private let verseNumbersLabel = UILabel()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.parchmentTexture
        setupViews()
        loadSettings()
    }
    
    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        // Extend background into safe area for full overlay effect
        additionalSafeAreaInsets = UIEdgeInsets(top: -view.safeAreaInsets.top, left: 0, bottom: 0, right: 0)
    }
    
    // MARK: - Setup Methods
    
    private func setupViews() {
        setupScrollView()
        setupTitle()
        setupCloseButton()
        setupVerseNumbersSetting()
        setupConstraints()
    }
    
    private func setupScrollView() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
    }
    
    private func setupTitle() {
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "Settings"
        titleLabel.font = UIFont(name: "Cardo-Bold", size: 28) ?? .systemFont(ofSize: 28, weight: .bold)
        titleLabel.textColor = UIColor(red: 0.15, green: 0.1, blue: 0.05, alpha: 1.0)
        titleLabel.textAlignment = .center
        
        contentView.addSubview(titleLabel)
    }
    
    private func setupCloseButton() {
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.backgroundColor = UIColor(red: 0.35, green: 0.25, blue: 0.15, alpha: 0.5)
        closeButton.layer.cornerRadius = 2.5
        
        contentView.addSubview(closeButton)
    }
    
    private func setupVerseNumbersSetting() {
        verseNumbersLabel.translatesAutoresizingMaskIntoConstraints = false
        verseNumbersLabel.text = "Show Verse Numbers"
        verseNumbersLabel.font = UIFont(name: "Cardo-Regular", size: 18) ?? .systemFont(ofSize: 18)
        verseNumbersLabel.textColor = UIColor(red: 0.1, green: 0.07, blue: 0.04, alpha: 1.0)
        
        verseNumbersSwitch.translatesAutoresizingMaskIntoConstraints = false
        verseNumbersSwitch.onTintColor = UIColor(red: 0.45, green: 0.35, blue: 0.25, alpha: 1.0)
        verseNumbersSwitch.addTarget(self, action: #selector(verseNumbersSwitchChanged), for: .valueChanged)
        
        contentView.addSubview(verseNumbersLabel)
        contentView.addSubview(verseNumbersSwitch)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Scroll view constraints
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Content view constraints
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // Title constraints
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 60),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            // Verse numbers setting constraints
            verseNumbersLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 40),
            verseNumbersLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            verseNumbersLabel.trailingAnchor.constraint(equalTo: verseNumbersSwitch.leadingAnchor, constant: -20),
            
            verseNumbersSwitch.centerYAnchor.constraint(equalTo: verseNumbersLabel.centerYAnchor),
            verseNumbersSwitch.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            // Close button (drag handle) at bottom
            closeButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            closeButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            closeButton.widthAnchor.constraint(equalToConstant: 40),
            closeButton.heightAnchor.constraint(equalToConstant: 5),
            
            // Content height
            contentView.bottomAnchor.constraint(equalTo: verseNumbersLabel.bottomAnchor, constant: 100)
        ])
    }
    
    // MARK: - Settings Management
    
    private func loadSettings() {
        verseNumbersSwitch.isOn = UserDefaults.standard.bool(forKey: "ShowVerseNumbers")
    }
    
    // MARK: - Action Handlers
    
    @objc private func verseNumbersSwitchChanged() {
        UserDefaults.standard.set(verseNumbersSwitch.isOn, forKey: "ShowVerseNumbers")
        
        // Notify other parts of the app that settings have changed
        NotificationCenter.default.post(name: .settingsChanged, object: nil)
    }
}