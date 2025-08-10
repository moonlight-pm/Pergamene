import UIKit

class SettingsViewController: UIViewController {
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let titleLabel = UILabel()
    private let closeButton = UIButton()
    
    // Settings controls
    private let verseNumbersSwitch = UISwitch()
    private let verseNumbersLabel = UILabel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.parchmentTexture
        setupViews()
        loadSettings()
    }
    
    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        // Extend background into safe area
        additionalSafeAreaInsets = UIEdgeInsets(top: -view.safeAreaInsets.top, left: 0, bottom: 0, right: 0)
    }
    
    private func setupViews() {
        // Scroll view setup
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        // Title
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "Settings"
        titleLabel.font = UIFont(name: "Cardo-Bold", size: 28) ?? .systemFont(ofSize: 28, weight: .bold)
        titleLabel.textColor = UIColor(red: 0.15, green: 0.1, blue: 0.05, alpha: 1.0)
        titleLabel.textAlignment = .center
        
        // Close button (pull indicator)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.backgroundColor = UIColor(red: 0.35, green: 0.25, blue: 0.15, alpha: 0.5)
        closeButton.layer.cornerRadius = 2.5
        
        contentView.addSubview(titleLabel)
        contentView.addSubview(closeButton)
        
        // Verse Numbers Setting
        setupVerseNumbersSetting()
        
        // Layout constraints
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // Close button (drag handle) - position at bottom of screen
            closeButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            closeButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            closeButton.widthAnchor.constraint(equalToConstant: 40),
            closeButton.heightAnchor.constraint(equalToConstant: 5),
            
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 60),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            // Verse numbers setting
            verseNumbersLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 40),
            verseNumbersLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            verseNumbersLabel.trailingAnchor.constraint(equalTo: verseNumbersSwitch.leadingAnchor, constant: -20),
            
            verseNumbersSwitch.centerYAnchor.constraint(equalTo: verseNumbersLabel.centerYAnchor),
            verseNumbersSwitch.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            // Content height
            contentView.bottomAnchor.constraint(equalTo: verseNumbersLabel.bottomAnchor, constant: 100)
        ])
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
    
    private func loadSettings() {
        verseNumbersSwitch.isOn = UserDefaults.standard.bool(forKey: "ShowVerseNumbers")
    }
    
    @objc private func verseNumbersSwitchChanged() {
        UserDefaults.standard.set(verseNumbersSwitch.isOn, forKey: "ShowVerseNumbers")
        
        // Post notification to update the reading view
        NotificationCenter.default.post(name: .settingsChanged, object: nil)
    }
}

extension Notification.Name {
    static let settingsChanged = Notification.Name("settingsChanged")
}