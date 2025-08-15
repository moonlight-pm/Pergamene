import UIKit

// MARK: - BookmarkPanelDelegate

protocol BookmarkPanelDelegate: AnyObject {
    func bookmarkPanel(_ panel: BookmarkPanelViewController, didSelectBookmark bookmark: BookmarkItem)
    func bookmarkPanelDidRequestReturn(_ panel: BookmarkPanelViewController)
    func bookmarkPanelDidAddBookmark(_ panel: BookmarkPanelViewController)
}

// MARK: - BookmarkButton

class BookmarkButton: UIButton {
    let bookmark: BookmarkItem
    
    init(bookmark: BookmarkItem) {
        self.bookmark = bookmark
        super.init(frame: .zero)
        setupAppearance()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupAppearance() {
        // Ribbon-like appearance extending to left edge
        backgroundColor = BookmarkColors.colorFromHex(bookmark.colorHex)
        layer.cornerRadius = 6
        layer.maskedCorners = [.layerMaxXMinYCorner, .layerMaxXMaxYCorner] // Round only right corners
        
        // Add subtle shadow for depth
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 2, height: 1)
        layer.shadowOpacity = 0.3
        layer.shadowRadius = 4
        
        // Text styling
        setTitle(bookmark.shortName, for: .normal)
        setTitleColor(.white, for: .normal)
        titleLabel?.font = UIFont(name: "Cardo-Bold", size: 14) ?? .systemFont(ofSize: 14, weight: .bold)
        contentHorizontalAlignment = .left
        contentEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)
        
        // Add subtle gradient overlay for ribbon effect
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = bounds
        gradientLayer.colors = [
            UIColor.white.withAlphaComponent(0.2).cgColor,
            UIColor.clear.cgColor,
            UIColor.black.withAlphaComponent(0.2).cgColor
        ]
        gradientLayer.locations = [0, 0.5, 1]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0, y: 1)
        layer.insertSublayer(gradientLayer, at: 0)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        // Update gradient layer frame
        if let gradientLayer = layer.sublayers?.first as? CAGradientLayer {
            gradientLayer.frame = bounds
        }
    }
}

// MARK: - BookmarkPanelViewController

class BookmarkPanelViewController: UIViewController {
    
    // MARK: - Properties
    
    weak var delegate: BookmarkPanelDelegate?
    private var bookmarks: [BookmarkItem] = []
    private var showReturnButton = false
    
    // UI Components
    private let containerView = UIView()
    private let scrollView = UIScrollView()
    private let stackView = UIStackView()
    private let addButton = UIButton()
    private var returnButton: UIButton?
    private var bookmarkButtons: [BookmarkButton] = []
    
    // Panel width
    private let panelWidth: CGFloat = 70
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        loadBookmarks()
    }
    
    // MARK: - Setup
    
    private func setupView() {
        view.backgroundColor = .clear
        
        // Container with parchment-like background
        containerView.backgroundColor = UIColor.parchmentTexture.withAlphaComponent(0.95)
        containerView.layer.cornerRadius = 0
        containerView.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMaxXMaxYCorner]
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOffset = CGSize(width: 3, height: 0)
        containerView.layer.shadowOpacity = 0.3
        containerView.layer.shadowRadius = 5
        
        // Scroll view for bookmarks
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        
        // Stack view for bookmark buttons
        stackView.axis = .vertical
        stackView.spacing = 10
        stackView.alignment = .fill
        stackView.distribution = .fillProportionally
        
        // Add button styling - matching theme
        addButton.setTitle("+", for: .normal)
        addButton.titleLabel?.font = UIFont(name: "Cardo-Bold", size: 28) ?? .systemFont(ofSize: 28, weight: .bold)
        addButton.setTitleColor(UIColor(red: 0.95, green: 0.92, blue: 0.88, alpha: 1.0), for: .normal)
        addButton.backgroundColor = UIColor(red: 0.45, green: 0.35, blue: 0.25, alpha: 0.8)
        addButton.layer.cornerRadius = 25
        addButton.layer.borderWidth = 1
        addButton.layer.borderColor = UIColor(red: 0.35, green: 0.25, blue: 0.15, alpha: 0.5).cgColor
        addButton.addTarget(self, action: #selector(addButtonTapped), for: .touchUpInside)
        
        // Layout
        view.addSubview(containerView)
        containerView.addSubview(scrollView)
        scrollView.addSubview(stackView)
        containerView.addSubview(addButton)
        
        containerView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        stackView.translatesAutoresizingMaskIntoConstraints = false
        addButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // Container - extend into safe areas
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.topAnchor.constraint(equalTo: view.topAnchor),
            containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            containerView.widthAnchor.constraint(equalToConstant: panelWidth),
            
            // Scroll view - with right padding for bookmark spacing
            scrollView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -5),
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 60),
            scrollView.bottomAnchor.constraint(equalTo: addButton.topAnchor, constant: -20),
            
            // Stack view
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // Add button - positioned above safe area
            addButton.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            addButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30),
            addButton.widthAnchor.constraint(equalToConstant: 50),
            addButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    // MARK: - Bookmark Management
    
    func loadBookmarks() {
        bookmarks = BookmarkManager.shared.getBookmarks()
        updateBookmarkButtons()
    }
    
    private func updateBookmarkButtons() {
        // Clear existing buttons
        bookmarkButtons.forEach { $0.removeFromSuperview() }
        bookmarkButtons.removeAll()
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        // Add return button if needed
        if showReturnButton, BookmarkManager.shared.getLastNonBookmarkPosition() != nil {
            let returnBtn = createReturnButton()
            returnButton = returnBtn
            stackView.addArrangedSubview(returnBtn)
            
            // Add separator
            let separator = UIView()
            separator.backgroundColor = UIColor(red: 0.35, green: 0.25, blue: 0.15, alpha: 0.2)
            separator.heightAnchor.constraint(equalToConstant: 1).isActive = true
            stackView.addArrangedSubview(separator)
        }
        
        // Add bookmark buttons
        for bookmark in bookmarks {
            let button = BookmarkButton(bookmark: bookmark)
            button.addTarget(self, action: #selector(bookmarkTapped(_:)), for: .touchUpInside)
            
            // Add long press for customization
            let longPress = UILongPressGestureRecognizer(target: self, action: #selector(bookmarkLongPressed(_:)))
            button.addGestureRecognizer(longPress)
            
            button.heightAnchor.constraint(equalToConstant: 44).isActive = true
            
            bookmarkButtons.append(button)
            stackView.addArrangedSubview(button)
        }
    }
    
    private func createReturnButton() -> UIButton {
        let button = UIButton()
        button.setTitle("↩", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 24)
        button.setTitleColor(UIColor(red: 0.35, green: 0.25, blue: 0.15, alpha: 1.0), for: .normal)
        button.backgroundColor = UIColor(red: 0.95, green: 0.92, blue: 0.88, alpha: 0.5)
        button.layer.cornerRadius = 4
        button.heightAnchor.constraint(equalToConstant: 44).isActive = true
        button.addTarget(self, action: #selector(returnButtonTapped), for: .touchUpInside)
        return button
    }
    
    func setShowReturnButton(_ show: Bool) {
        showReturnButton = show
        updateBookmarkButtons()
    }
    
    // MARK: - Actions
    
    @objc private func addButtonTapped() {
        delegate?.bookmarkPanelDidAddBookmark(self)
        // Panel will be hidden by the delegate
    }
    
    @objc private func bookmarkTapped(_ sender: BookmarkButton) {
        delegate?.bookmarkPanel(self, didSelectBookmark: sender.bookmark)
        // Panel will be hidden by the delegate
    }
    
    @objc private func returnButtonTapped() {
        delegate?.bookmarkPanelDidRequestReturn(self)
        // Panel will be hidden by the delegate
    }
    
    @objc private func bookmarkLongPressed(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began,
              let button = gesture.view as? BookmarkButton else { return }
        
        showCustomizationMenu(for: button.bookmark, sourceView: button)
    }
    
    // MARK: - Customization Menu
    
    private func showCustomizationMenu(for bookmark: BookmarkItem, sourceView: UIView) {
        let alertController = UIAlertController(title: bookmark.shortName, message: "Customize bookmark", preferredStyle: .actionSheet)
        
        // Color options
        for (index, colorHex) in BookmarkColors.themeColors.enumerated() {
            let colorNames = ["Brown", "Red", "Blue", "Green", "Purple", "Orange", "Gold", "Pink", "Teal", "Sienna", "Gray"]
            let colorName = index < colorNames.count ? colorNames[index] : "Color \(index + 1)"
            
            let action = UIAlertAction(title: colorName, style: .default) { [weak self] _ in
                BookmarkManager.shared.updateBookmarkColor(bookmark, colorHex: colorHex)
                self?.loadBookmarks()
                // Dismiss panel after color change
                if let delegate = self?.delegate as? ChapterViewController {
                    delegate.hideBookmarkPanel()
                }
            }
            
            // Add color indicator
            let color = BookmarkColors.colorFromHex(colorHex)
            action.setValue(color, forKey: "titleTextColor")
            
            alertController.addAction(action)
        }
        
        // Delete option
        let deleteAction = UIAlertAction(title: "Delete Bookmark", style: .destructive) { [weak self] _ in
            BookmarkManager.shared.deleteBookmark(bookmark)
            self?.loadBookmarks()
            // Dismiss panel after deletion
            if let delegate = self?.delegate as? ChapterViewController {
                delegate.hideBookmarkPanel()
            }
        }
        alertController.addAction(deleteAction)
        
        // Cancel
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        // iPad support
        if let popover = alertController.popoverPresentationController {
            popover.sourceView = sourceView
            popover.sourceRect = sourceView.bounds
        }
        
        present(alertController, animated: true)
    }
}