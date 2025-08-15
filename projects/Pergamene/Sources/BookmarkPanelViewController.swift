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
        
        // Use configuration instead of deprecated contentEdgeInsets
        var config = UIButton.Configuration.plain()
        config.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 8, bottom: 0, trailing: 8)
        config.titleAlignment = .leading
        self.configuration = config
        
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
    private let editButton = UIButton()
    private var bookmarkButtons: [BookmarkButton] = []
    
    // Edit mode
    private var isEditMode = false
    
    // Drag and drop properties
    private var draggedButton: BookmarkButton?
    private var draggedButtonOriginalIndex: Int?
    private var lastTargetIndex: Int?
    
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
        
        // Add tap gesture to container to close panel when tapping blank area
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleContainerTap(_:)))
        tapGesture.delegate = self
        containerView.addGestureRecognizer(tapGesture)
        
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
        
        // Edit button styling - using lock icons
        let lockConfig = UIImage.SymbolConfiguration(pointSize: 20, weight: .regular)
        let lockedImage = UIImage(systemName: "lock.fill", withConfiguration: lockConfig)
        let unlockedImage = UIImage(systemName: "lock.open.fill", withConfiguration: lockConfig)
        editButton.setImage(lockedImage, for: .normal)
        editButton.setImage(unlockedImage, for: .selected)
        editButton.tintColor = UIColor(red: 0.45, green: 0.35, blue: 0.25, alpha: 0.8)
        editButton.addTarget(self, action: #selector(editButtonTapped), for: .touchUpInside)
        
        // Layout
        view.addSubview(containerView)
        containerView.addSubview(scrollView)
        scrollView.addSubview(stackView)
        containerView.addSubview(addButton)
        containerView.addSubview(editButton)
        
        containerView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        stackView.translatesAutoresizingMaskIntoConstraints = false
        addButton.translatesAutoresizingMaskIntoConstraints = false
        editButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // Container - extend into safe areas
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.topAnchor.constraint(equalTo: view.topAnchor),
            containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            containerView.widthAnchor.constraint(equalToConstant: panelWidth),
            
            // Edit button - positioned at top
            editButton.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            editButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
            editButton.widthAnchor.constraint(equalToConstant: 40),
            editButton.heightAnchor.constraint(equalToConstant: 40),
            
            // Scroll view - with right padding for bookmark spacing
            scrollView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -5),
            scrollView.topAnchor.constraint(equalTo: editButton.bottomAnchor, constant: 10),
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
            
            // Add pan gesture for dragging (only active in edit mode)
            let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
            panGesture.delegate = self
            button.addGestureRecognizer(panGesture)
            
            button.heightAnchor.constraint(equalToConstant: 44).isActive = true
            
            bookmarkButtons.append(button)
            stackView.addArrangedSubview(button)
        }
    }
    
    
    // MARK: - Actions
    
    @objc private func addButtonTapped() {
        delegate?.bookmarkPanelDidAddBookmark(self)
        // Don't hide panel - let user continue managing bookmarks
    }
    
    @objc private func bookmarkTapped(_ sender: BookmarkButton) {
        if isEditMode {
            // In edit mode, show customization menu
            showCustomizationMenu(for: sender.bookmark, sourceView: sender)
        } else {
            // In normal mode, navigate to bookmark
            delegate?.bookmarkPanel(self, didSelectBookmark: sender.bookmark)
            // Don't hide panel - let user continue navigating bookmarks
        }
    }
    
    @objc private func editButtonTapped() {
        isEditMode.toggle()
        editButton.isSelected = isEditMode
        
        // Update visual feedback
        UIView.animate(withDuration: 0.3) {
            self.bookmarkButtons.forEach { button in
                button.alpha = self.isEditMode ? 0.8 : 1.0
                // Add wiggle animation in edit mode
                if self.isEditMode {
                    self.startWiggleAnimation(for: button)
                } else {
                    self.stopWiggleAnimation(for: button)
                }
            }
        }
    }
    
    @objc private func handleContainerTap(_ gesture: UITapGestureRecognizer) {
        // Close the panel when tapping blank area
        if let delegate = delegate as? ChapterViewController {
            delegate.hideBookmarkPanel()
        }
    }
    
    private func startWiggleAnimation(for view: UIView) {
        let wiggleAnimation = CABasicAnimation(keyPath: "transform.rotation")
        wiggleAnimation.duration = 0.15
        wiggleAnimation.repeatCount = .infinity
        wiggleAnimation.autoreverses = true
        wiggleAnimation.fromValue = -0.02
        wiggleAnimation.toValue = 0.02
        view.layer.add(wiggleAnimation, forKey: "wiggle")
    }
    
    private func stopWiggleAnimation(for view: UIView) {
        view.layer.removeAnimation(forKey: "wiggle")
    }
    
    
    
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        // Only allow dragging in edit mode
        guard isEditMode,
              let button = gesture.view as? BookmarkButton else { return }
        
        switch gesture.state {
        case .began:
            // Start dragging
            beginDragging(button)
        case .changed:
            // Update drag position
            let location = gesture.location(in: scrollView)
            updateDragPosition(location)
        case .ended, .cancelled, .failed:
            // End dragging
            endDragging()
        default:
            break
        }
    }
    
    
    // MARK: - Drag and Drop
    
    private func beginDragging(_ button: BookmarkButton) {
        draggedButton = button
        draggedButtonOriginalIndex = bookmarkButtons.firstIndex(of: button)
        lastTargetIndex = draggedButtonOriginalIndex
        
        // Animate button lift
        UIView.animate(withDuration: 0.2) {
            button.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
            button.alpha = 0.8
            button.layer.shadowOpacity = 0.5
            button.layer.shadowOffset = CGSize(width: 0, height: 4)
        }
        
        // Single haptic feedback on pickup
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
    
    private func updateDragPosition(_ location: CGPoint) {
        guard let draggedButton = draggedButton else { return }
        
        // Only process if location is within scroll view bounds
        let scrollBounds = scrollView.bounds
        guard location.y >= 0 && location.y <= scrollBounds.height else { return }
        
        // Find the current index of the dragged button
        guard let currentIndex = bookmarkButtons.firstIndex(of: draggedButton) else { return }
        
        // Find the index where the button should be moved
        var targetIndex = bookmarkButtons.count // Start with "after everything"
        
        for (index, button) in bookmarkButtons.enumerated() {
            if button == draggedButton { continue }
            
            let buttonFrame = button.convert(button.bounds, to: scrollView)
            if location.y < buttonFrame.midY {
                // Adjust target index based on whether it's before or after current position
                targetIndex = index < currentIndex ? index : index - 1
                break
            }
        }
        
        // If targetIndex is still at the end, adjust it
        if targetIndex >= bookmarkButtons.count {
            targetIndex = bookmarkButtons.count - 1
        }
        
        // Move the button in the stack view if needed
        if targetIndex != currentIndex {
            // Remove from current position
            bookmarkButtons.remove(at: currentIndex)
            stackView.removeArrangedSubview(draggedButton)
            
            // Insert at new position
            bookmarkButtons.insert(draggedButton, at: targetIndex)
            stackView.insertArrangedSubview(draggedButton, at: targetIndex)
            
            // Animate the rearrangement
            UIView.animate(withDuration: 0.3) {
                self.stackView.layoutIfNeeded()
            }
            
            // Only trigger haptic if this is a new position
            if lastTargetIndex != targetIndex {
                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                impactFeedback.impactOccurred()
                lastTargetIndex = targetIndex
            }
        }
    }
    
    private func endDragging() {
        guard let draggedButton = draggedButton else { return }
        
        // Animate button back to normal
        UIView.animate(withDuration: 0.2) {
            draggedButton.transform = .identity
            draggedButton.alpha = 1.0
            draggedButton.layer.shadowOpacity = 0.3
            draggedButton.layer.shadowOffset = CGSize(width: 2, height: 1)
        }
        
        // Update the order in the data model
        var reorderedBookmarks: [BookmarkItem] = []
        for button in bookmarkButtons {
            reorderedBookmarks.append(button.bookmark)
        }
        
        // Save the new order
        if reorderedBookmarks.count == bookmarks.count {
            bookmarks = reorderedBookmarks
            BookmarkManager.shared.reorderBookmarks(reorderedBookmarks)
        }
        
        self.draggedButton = nil
        self.draggedButtonOriginalIndex = nil
        self.lastTargetIndex = nil
    }
    
    // MARK: - Customization Menu
    
    private func showCustomizationMenu(for bookmark: BookmarkItem, sourceView: UIView) {
        let alertController = UIAlertController(title: bookmark.shortName, message: "Customize bookmark", preferredStyle: .actionSheet)
        
        // Color options
        for (index, colorHex) in BookmarkColors.themeColors.enumerated() {
            let colorNames = ["Brown", "Red", "Blue", "Green", "Purple", "Orange", "Gold"]
            let colorName = index < colorNames.count ? colorNames[index] : "Color \(index + 1)"
            
            let action = UIAlertAction(title: colorName, style: .default) { [weak self] _ in
                // Use random brown for "Brown" option, fixed color for others
                let finalColorHex = (index == 0) ? BookmarkColors.randomBrownShade() : colorHex
                BookmarkManager.shared.updateBookmarkColor(bookmark, colorHex: finalColorHex)
                self?.loadBookmarks()
                // Don't hide panel - let user continue customizing bookmarks
            }
            
            // Add color indicator (show the base brown for Brown option)
            let color = BookmarkColors.colorFromHex(colorHex)
            action.setValue(color, forKey: "titleTextColor")
            
            alertController.addAction(action)
        }
        
        // Delete option
        let deleteAction = UIAlertAction(title: "Delete Bookmark", style: .destructive) { [weak self] _ in
            BookmarkManager.shared.deleteBookmark(bookmark)
            self?.loadBookmarks()
            // Don't hide panel - let user continue managing bookmarks
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
        return false
    }
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        // Only allow pan gesture in edit mode
        if gestureRecognizer is UIPanGestureRecognizer {
            return isEditMode
        }
        return true
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        // Only allow tap gesture on blank areas (not on buttons or other interactive elements)
        if gestureRecognizer is UITapGestureRecognizer {
            let location = touch.location(in: containerView)
            
            // Check if tap is on any button or interactive element
            for subview in [editButton, addButton] + bookmarkButtons {
                if subview.frame.contains(location) {
                    return false
                }
            }
            
            // Check if tap is on scroll view content
            if scrollView.frame.contains(location) {
                let scrollLocation = touch.location(in: scrollView)
                for button in bookmarkButtons {
                    if button.frame.contains(scrollLocation) {
                        return false
                    }
                }
            }
        }
        return true
    }
}