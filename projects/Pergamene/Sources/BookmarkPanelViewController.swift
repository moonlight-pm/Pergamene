import UIKit

// MARK: - BookmarkPanelDelegate

protocol BookmarkPanelDelegate: AnyObject {
    func bookmarkPanel(_ panel: BookmarkPanelViewController, didSelectBookmark bookmark: BookmarkItem)
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

class BookmarkPanelViewController: UIViewController, UIGestureRecognizerDelegate {
    
    // MARK: - Properties
    
    weak var delegate: BookmarkPanelDelegate?
    private var bookmarks: [BookmarkItem] = []
    
    // UI Components
    private let containerView = UIView()
    private let scrollView = UIScrollView()
    private let stackView = UIStackView()
    private let addButton = UIButton()
    private var bookmarkButtons: [BookmarkButton] = []
    
    // Drag and drop properties
    private var draggedButton: BookmarkButton?
    private var draggedButtonOriginalIndex: Int?
    private var placeholderView: UIView?
    
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
        
        // Add bookmark buttons
        for bookmark in bookmarks {
            let button = BookmarkButton(bookmark: bookmark)
            button.addTarget(self, action: #selector(bookmarkTapped(_:)), for: .touchUpInside)
            
            // Add long press for customization and drag
            let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
            longPress.minimumPressDuration = 0.5
            button.addGestureRecognizer(longPress)
            
            // Add pan gesture for dragging
            let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
            panGesture.delegate = self
            button.addGestureRecognizer(panGesture)
            
            // Add double tap for customization menu
            let doubleTap = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
            doubleTap.numberOfTapsRequired = 2
            button.addGestureRecognizer(doubleTap)
            
            button.heightAnchor.constraint(equalToConstant: 44).isActive = true
            
            bookmarkButtons.append(button)
            stackView.addArrangedSubview(button)
        }
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
    
    
    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard let button = gesture.view as? BookmarkButton else { return }
        
        switch gesture.state {
        case .began:
            // Start dragging
            beginDragging(button)
        case .changed:
            // Update drag position
            let location = gesture.location(in: scrollView)
            updateDragPosition(location)
        case .ended, .cancelled:
            // End dragging
            endDragging()
        default:
            break
        }
    }
    
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let button = gesture.view as? BookmarkButton,
              draggedButton == button else { return }
        
        switch gesture.state {
        case .changed:
            let location = gesture.location(in: scrollView)
            updateDragPosition(location)
        case .ended, .cancelled:
            endDragging()
        default:
            break
        }
    }
    
    @objc private func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
        guard let button = gesture.view as? BookmarkButton else { return }
        showCustomizationMenu(for: button.bookmark, sourceView: button)
    }
    
    // MARK: - Drag and Drop
    
    private func beginDragging(_ button: BookmarkButton) {
        draggedButton = button
        draggedButtonOriginalIndex = bookmarkButtons.firstIndex(of: button)
        
        // Create placeholder view
        placeholderView = UIView()
        placeholderView?.backgroundColor = UIColor.gray.withAlphaComponent(0.3)
        placeholderView?.layer.cornerRadius = 6
        placeholderView?.heightAnchor.constraint(equalToConstant: 44).isActive = true
        
        // Animate button lift
        UIView.animate(withDuration: 0.2) {
            button.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
            button.alpha = 0.8
        }
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
    
    private func updateDragPosition(_ location: CGPoint) {
        guard let draggedButton = draggedButton,
              let placeholder = placeholderView else { return }
        
        // Find the index where the button should be moved
        var targetIndex = 0
        for (index, button) in bookmarkButtons.enumerated() {
            if button == draggedButton { continue }
            
            let buttonFrame = button.convert(button.bounds, to: scrollView)
            if location.y < buttonFrame.midY {
                targetIndex = index
                break
            }
            targetIndex = index + 1
        }
        
        // Move the button in the stack view if needed
        if let currentIndex = stackView.arrangedSubviews.firstIndex(of: draggedButton),
           targetIndex != currentIndex {
            
            stackView.removeArrangedSubview(placeholder)
            stackView.removeArrangedSubview(draggedButton)
            
            // Insert placeholder at target position
            if targetIndex < stackView.arrangedSubviews.count {
                stackView.insertArrangedSubview(placeholder, at: targetIndex)
                stackView.insertArrangedSubview(draggedButton, at: targetIndex)
            } else {
                stackView.addArrangedSubview(placeholder)
                stackView.addArrangedSubview(draggedButton)
            }
            
            // Light haptic feedback for crossing threshold
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
        }
    }
    
    private func endDragging() {
        guard let draggedButton = draggedButton else { return }
        
        // Remove placeholder
        placeholderView?.removeFromSuperview()
        placeholderView = nil
        
        // Animate button back to normal
        UIView.animate(withDuration: 0.2) {
            draggedButton.transform = .identity
            draggedButton.alpha = 1.0
        }
        
        // Update the order in the data model
        var reorderedBookmarks: [BookmarkItem] = []
        for view in stackView.arrangedSubviews {
            if let button = view as? BookmarkButton {
                reorderedBookmarks.append(button.bookmark)
            }
        }
        
        // Save the new order
        if reorderedBookmarks.count == bookmarks.count {
            bookmarks = reorderedBookmarks
            BookmarkManager.shared.reorderBookmarks(reorderedBookmarks)
            
            // Update button array to match new order
            bookmarkButtons = stackView.arrangedSubviews.compactMap { $0 as? BookmarkButton }
        }
        
        self.draggedButton = nil
        self.draggedButtonOriginalIndex = nil
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
    
    // MARK: - UIGestureRecognizerDelegate
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // Allow pan gesture to work with long press
        if gestureRecognizer is UIPanGestureRecognizer && otherGestureRecognizer is UILongPressGestureRecognizer {
            return true
        }
        if gestureRecognizer is UILongPressGestureRecognizer && otherGestureRecognizer is UIPanGestureRecognizer {
            return true
        }
        return false
    }
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        // Only start pan gesture if we're already dragging
        if gestureRecognizer is UIPanGestureRecognizer {
            return draggedButton != nil
        }
        return true
    }
}