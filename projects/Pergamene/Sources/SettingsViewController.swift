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
    private let closeButton = UIButton()
    
    // App info
    private let appNameLabel = UILabel()
    private let bibleTextsLabel = UILabel()
    private let instructionsButton = UIButton(type: .system)
    
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
        setupAppInfo()
        setupInstructionsButton()
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
        // Removed Settings title - no longer needed
    }
    
    private func setupCloseButton() {
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.backgroundColor = UIColor(red: 0.35, green: 0.25, blue: 0.15, alpha: 0.5)
        closeButton.layer.cornerRadius = 2.5
        
        contentView.addSubview(closeButton)
    }
    
    private func setupAppInfo() {
        // App name in Gothic font
        appNameLabel.translatesAutoresizingMaskIntoConstraints = false
        appNameLabel.text = "Pergamene"
        let gothicFont = UIFont(name: "UnifrakturMaguntia-Book", size: 36) ??
                        UIFont(name: "UnifrakturMaguntia", size: 36) ??
                        UIFont(name: "Unifraktur Maguntia", size: 36)
        appNameLabel.font = gothicFont ?? UIFont(name: "Cardo-Bold", size: 36) ?? .systemFont(ofSize: 36, weight: .bold)
        appNameLabel.textColor = UIColor(red: 0.15, green: 0.1, blue: 0.05, alpha: 1.0)
        appNameLabel.textAlignment = .center
        
        // Bible texts info
        bibleTextsLabel.translatesAutoresizingMaskIntoConstraints = false
        let textsInfo = """
        Old Testament: Brenton Septuagint
        New Testament: Berean Standard Bible
        """
        bibleTextsLabel.text = textsInfo
        bibleTextsLabel.font = UIFont(name: "Cardo-Regular", size: 14) ?? .systemFont(ofSize: 14)
        bibleTextsLabel.textColor = UIColor(red: 0.25, green: 0.18, blue: 0.12, alpha: 1.0)
        bibleTextsLabel.textAlignment = .center
        bibleTextsLabel.numberOfLines = 0
        
        contentView.addSubview(appNameLabel)
        contentView.addSubview(bibleTextsLabel)
    }
    
    private func setupInstructionsButton() {
        instructionsButton.translatesAutoresizingMaskIntoConstraints = false
        instructionsButton.setTitle("How to Use", for: .normal)
        instructionsButton.titleLabel?.font = UIFont(name: "Cardo-Regular", size: 16) ?? .systemFont(ofSize: 16)
        instructionsButton.tintColor = UIColor(red: 0.35, green: 0.25, blue: 0.15, alpha: 1.0)
        instructionsButton.addTarget(self, action: #selector(instructionsTapped), for: .touchUpInside)
        
        contentView.addSubview(instructionsButton)
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
            
            // App name constraints (now at the top since Settings title is removed)
            appNameLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 60),
            appNameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            appNameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            // Bible texts info constraints
            bibleTextsLabel.topAnchor.constraint(equalTo: appNameLabel.bottomAnchor, constant: 15),
            bibleTextsLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            bibleTextsLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            // Instructions button constraints
            instructionsButton.topAnchor.constraint(equalTo: bibleTextsLabel.bottomAnchor, constant: 20),
            instructionsButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            
            // Verse numbers setting constraints - more centered with less spacing
            verseNumbersLabel.topAnchor.constraint(equalTo: instructionsButton.bottomAnchor, constant: 40),
            verseNumbersLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 60),
            verseNumbersLabel.trailingAnchor.constraint(equalTo: verseNumbersSwitch.leadingAnchor, constant: -10),
            
            verseNumbersSwitch.centerYAnchor.constraint(equalTo: verseNumbersLabel.centerYAnchor),
            verseNumbersSwitch.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -60),
            
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
    
    @objc private func instructionsTapped() {
        let instructionsVC = InstructionsViewController()
        instructionsVC.modalPresentationStyle = .pageSheet
        if let sheet = instructionsVC.sheetPresentationController {
            sheet.detents = [.medium()]
            sheet.prefersGrabberVisible = true
        }
        present(instructionsVC, animated: true)
    }
}

// MARK: - InstructionsViewController

/// Modal view controller displaying app usage instructions
class InstructionsViewController: UIViewController {
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let titleLabel = UILabel()
    private let instructionsLabel = UILabel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.parchmentTexture
        setupViews()
    }
    
    private func setupViews() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        // Title
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "How to Use Pergamene"
        titleLabel.font = UIFont(name: "Cardo-Bold", size: 24) ?? .systemFont(ofSize: 24, weight: .bold)
        titleLabel.textColor = UIColor(red: 0.15, green: 0.1, blue: 0.05, alpha: 1.0)
        titleLabel.textAlignment = .center
        
        // Instructions
        instructionsLabel.translatesAutoresizingMaskIntoConstraints = false
        let instructions = """
        Navigation
        • Swipe left/right to navigate between chapters
        • Tap the book name to select a different book
        
        Sharing (Coming Soon)
        • Long press on text to share verses
        
        Tips
        • Your reading position is saved automatically
        • Positions reset after 24 hours of inactivity
        """
        
        instructionsLabel.text = instructions
        instructionsLabel.font = UIFont(name: "Cardo-Regular", size: 16) ?? .systemFont(ofSize: 16)
        instructionsLabel.textColor = UIColor(red: 0.1, green: 0.07, blue: 0.04, alpha: 1.0)
        instructionsLabel.numberOfLines = 0
        instructionsLabel.textAlignment = .left
        
        contentView.addSubview(titleLabel)
        contentView.addSubview(instructionsLabel)
        
        NSLayoutConstraint.activate([
            // Scroll view
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Content view
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // Title
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 30),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            // Instructions
            instructionsLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 30),
            instructionsLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 30),
            instructionsLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -30),
            instructionsLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -30)
        ])
    }
}