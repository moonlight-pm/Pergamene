import UIKit

// MARK: - ChapterViewController

/// Displays a single chapter with vertical scrolling, settings overlay, and verse numbers
/// Designed for reuse within the horizontal paging system
class ChapterViewController: UIViewController {
    
    // MARK: - UI Components
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let topFadeView = UIView()
    private let topFadeGradient = CAGradientLayer()
    private let chapterHeaderView = UIView()
    private let bookLabel = UILabel()
    private let chapterLabel = UILabel()
    private let versesStackView = UIStackView()
    
    // Verse selection properties
    private var currentChapterVerses: [Verse] = []
    private var selectedVerseStart: Int = 1
    private var selectedVerseEnd: Int = 1
    
    // Floating chapter indicator
    private let floatingIndicatorView = UIView()
    private let floatingIndicatorLabel = UILabel()
    private var floatingIndicatorVisible = false
    private var floatingIndicatorHeightConstraint: NSLayoutConstraint?
    
    // Bookmark panel
    private var bookmarkPanelViewController: BookmarkPanelViewController?
    private var bookmarkPanelContainerView: UIView?
    private var bookmarkPanelLeadingConstraint: NSLayoutConstraint?
    private var bookmarkPanelVisible = false
    
    // Settings overlay system
    private let settingsOverlayView = UIView()
    private let settingsDimmingView = UIView()
    private var settingsViewController: SettingsViewController?
    private var settingsIsVisible = false
    private let screenHeight: CGFloat = UIScreen.main.bounds.height
    
    // MARK: - Settings Gesture Properties
    
    private let pullActivationThreshold: CGFloat = 90.0
    private let pushActivationThreshold: CGFloat = 90.0
    private let elasticDamping: CGFloat = 0.6
    private let maxElasticDistance: CGFloat = 120.0
    
    private var isAnimatingSettings = false
    private var isDraggingSettings = false
    private var settingsPanGestureRecognizer: UIPanGestureRecognizer?
    
    // MARK: - Chapter Data Properties
    
    private var currentBook: Book?
    private var currentChapter: Int = 1
    private var chapterTextCache: [String: String] = [:]
    private var chapterHeaderTopConstraint: NSLayoutConstraint?
    private var verseNumberLabels: [UILabel] = []
    
    private var verseNumbersVisible: Bool {
        return UserDefaults.standard.bool(forKey: "ShowVerseNumbers")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set default for verse numbers if not set
        if UserDefaults.standard.object(forKey: "ShowVerseNumbers") == nil {
            UserDefaults.standard.set(true, forKey: "ShowVerseNumbers")
        }
        
        view.backgroundColor = .black
        scrollView.contentInsetAdjustmentBehavior = .never
        
        setupViews()
        setupSettingsOverlay()
        setupBookmarkPanel()
        setupGestures()
        setupNotifications()
    }
    
    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        chapterHeaderTopConstraint?.constant = view.safeAreaInsets.top + 20
        updateGradientMask()
        
        // Update floating indicator height to cover safe area + label
        let labelHeight: CGFloat = 28
        floatingIndicatorHeightConstraint?.constant = view.safeAreaInsets.top + labelHeight
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateGradientMask()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Public Interface
    
    func loadChapter(book: Book, chapter: Int) {
        currentBook = book
        currentChapter = chapter
        
        guard let chapterData = book.chapters.first(where: { $0.number == chapter }) else { return }
        
        updateLabels(book: book, chapter: chapter)
        clearExistingContent()
        
        let fullText = getCachedOrCreateText(book: book, chapter: chapter, verses: chapterData.verses)
        let paragraphView = createChapterParagraphView(text: fullText, verses: chapterData.verses)
        versesStackView.addArrangedSubview(paragraphView)
        
        restoreScrollPosition(book: book, chapter: chapter)
        updateReadingPosition(book: book, chapter: chapter)
    }
    
    func getCurrentBook() -> Book? {
        return currentBook
    }
    
    func getCurrentChapter() -> Int {
        return currentChapter
    }
    
    // MARK: - Setup Methods
    
    private func setupViews() {
        setupScrollView()
        setupChapterHeader()
        setupVersesStackView()
        setupFloatingIndicator()
        setupGradientMask()
    }
    
    private func setupScrollView() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.backgroundColor = .clear
        scrollView.delegate = self
        scrollView.showsVerticalScrollIndicator = false  // Hide scroll bar for cleaner look
        scrollView.isDirectionalLockEnabled = true // Lock to vertical scrolling only
        
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.backgroundColor = UIColor.parchmentTexture
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
    }
    
    private func setupChapterHeader() {
        chapterHeaderView.translatesAutoresizingMaskIntoConstraints = false
        chapterHeaderView.backgroundColor = .clear
        chapterHeaderView.isUserInteractionEnabled = true
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(bookTitleTapped))
        chapterHeaderView.addGestureRecognizer(tapGesture)
        
        bookLabel.translatesAutoresizingMaskIntoConstraints = false
        bookLabel.font = UIFont(name: "Cardo-Bold", size: 26) ?? .systemFont(ofSize: 24, weight: .semibold)
        bookLabel.textColor = UIColor(red: 0.15, green: 0.1, blue: 0.05, alpha: 1.0)
        bookLabel.textAlignment = .center
        bookLabel.isUserInteractionEnabled = true
        
        chapterLabel.translatesAutoresizingMaskIntoConstraints = false
        chapterLabel.font = UIFont(name: "Cardo-Regular", size: 20) ?? .systemFont(ofSize: 18)
        chapterLabel.textColor = UIColor(red: 0.25, green: 0.18, blue: 0.12, alpha: 1.0)
        chapterLabel.textAlignment = .center
        
        contentView.addSubview(chapterHeaderView)
        chapterHeaderView.addSubview(bookLabel)
        chapterHeaderView.addSubview(chapterLabel)
        
        chapterHeaderTopConstraint = chapterHeaderView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20)
        
        NSLayoutConstraint.activate([
            chapterHeaderTopConstraint!,
            chapterHeaderView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            chapterHeaderView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            chapterHeaderView.heightAnchor.constraint(equalToConstant: 80),
            
            bookLabel.topAnchor.constraint(equalTo: chapterHeaderView.topAnchor),
            bookLabel.leadingAnchor.constraint(equalTo: chapterHeaderView.leadingAnchor, constant: 20),
            bookLabel.trailingAnchor.constraint(equalTo: chapterHeaderView.trailingAnchor, constant: -20),
            
            chapterLabel.topAnchor.constraint(equalTo: bookLabel.bottomAnchor, constant: 4),
            chapterLabel.leadingAnchor.constraint(equalTo: chapterHeaderView.leadingAnchor, constant: 20),
            chapterLabel.trailingAnchor.constraint(equalTo: chapterHeaderView.trailingAnchor, constant: -20)
        ])
    }
    
    private func setupVersesStackView() {
        versesStackView.translatesAutoresizingMaskIntoConstraints = false
        versesStackView.axis = .vertical
        versesStackView.spacing = 12
        versesStackView.alignment = .fill
        
        contentView.addSubview(versesStackView)
        
        // Extra bottom padding for comfortable reading (half screen height)
        let extraBottomSpace = UIScreen.main.bounds.height * 0.5
        
        NSLayoutConstraint.activate([
            versesStackView.topAnchor.constraint(equalTo: chapterHeaderView.bottomAnchor, constant: 20),
            versesStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            versesStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            versesStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -extraBottomSpace)
        ])
    }
    
    private func setupFloatingIndicator() {
        floatingIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        // Changed: Use 70% opacity (30% transparent) and extend to top of view
        floatingIndicatorView.backgroundColor = UIColor(red: 0.05, green: 0.03, blue: 0.01, alpha: 0.7)
        floatingIndicatorView.alpha = 0
        
        floatingIndicatorLabel.translatesAutoresizingMaskIntoConstraints = false
        floatingIndicatorLabel.font = UIFont(name: "Cardo-Regular", size: 14) ?? .systemFont(ofSize: 14)
        floatingIndicatorLabel.textColor = UIColor(red: 0.95, green: 0.92, blue: 0.88, alpha: 1.0)
        floatingIndicatorLabel.textAlignment = .center
        
        floatingIndicatorView.addSubview(floatingIndicatorLabel)
        view.addSubview(floatingIndicatorView)
        
        // Initial height - will be updated in viewSafeAreaInsetsDidChange
        floatingIndicatorHeightConstraint = floatingIndicatorView.heightAnchor.constraint(equalToConstant: 72)
        
        NSLayoutConstraint.activate([
            // Changed: Extend to top of view (not safe area) to cover status bar
            floatingIndicatorView.topAnchor.constraint(equalTo: view.topAnchor),
            floatingIndicatorView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            floatingIndicatorView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            floatingIndicatorHeightConstraint!,
            
            // Position label just below safe area
            floatingIndicatorLabel.bottomAnchor.constraint(equalTo: floatingIndicatorView.bottomAnchor, constant: -4),
            floatingIndicatorLabel.leadingAnchor.constraint(equalTo: floatingIndicatorView.leadingAnchor, constant: 20),
            floatingIndicatorLabel.trailingAnchor.constraint(equalTo: floatingIndicatorView.trailingAnchor, constant: -20),
            floatingIndicatorLabel.heightAnchor.constraint(equalToConstant: 20)
        ])
        
        floatingIndicatorView.layer.zPosition = 25
    }
    
    private func setupGradientMask() {
        topFadeView.translatesAutoresizingMaskIntoConstraints = false
        topFadeView.isUserInteractionEnabled = false
        
        // Configure gradient with smooth transitions
        topFadeGradient.colors = [
            UIColor.black.withAlphaComponent(0.7).cgColor,
            UIColor.black.withAlphaComponent(0.65).cgColor,
            UIColor.black.withAlphaComponent(0.5).cgColor,
            UIColor.black.withAlphaComponent(0.35).cgColor,
            UIColor.black.withAlphaComponent(0.2).cgColor,
            UIColor.black.withAlphaComponent(0.1).cgColor,
            UIColor.black.withAlphaComponent(0.05).cgColor,
            UIColor.black.withAlphaComponent(0.02).cgColor,
            UIColor.black.withAlphaComponent(0).cgColor
        ]
        topFadeGradient.locations = [0, 0.2, 0.35, 0.5, 0.65, 0.75, 0.85, 0.95, 1]
        topFadeGradient.startPoint = CGPoint(x: 0.5, y: 0)
        topFadeGradient.endPoint = CGPoint(x: 0.5, y: 1)
        
        topFadeView.layer.addSublayer(topFadeGradient)
        view.addSubview(topFadeView)
        
        // Ensure gradient is above bookmark panel
        topFadeView.layer.zPosition = 20
        
        NSLayoutConstraint.activate([
            topFadeView.topAnchor.constraint(equalTo: view.topAnchor),
            topFadeView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topFadeView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            topFadeView.heightAnchor.constraint(equalToConstant: 100)
        ])
    }
    
    private func updateGradientMask() {
        topFadeGradient.frame = topFadeView.bounds
        
        let safeAreaTop = view.safeAreaInsets.top
        if safeAreaTop > 0 {
            topFadeView.constraints.first { $0.firstAttribute == .height }?.constant = safeAreaTop + 20
        }
    }
    
    // MARK: - Settings Overlay
    
    private func setupSettingsOverlay() {
        settingsDimmingView.translatesAutoresizingMaskIntoConstraints = false
        settingsDimmingView.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        settingsDimmingView.alpha = 0
        settingsDimmingView.isHidden = true
        settingsDimmingView.isUserInteractionEnabled = false
        
        settingsOverlayView.translatesAutoresizingMaskIntoConstraints = false
        settingsOverlayView.backgroundColor = UIColor.parchmentTexture
        
        settingsOverlayView.layer.shadowColor = UIColor.black.cgColor
        settingsOverlayView.layer.shadowOffset = CGSize(width: 0, height: 4)
        settingsOverlayView.layer.shadowOpacity = 0.3
        settingsOverlayView.layer.shadowRadius = 8
        
        view.addSubview(settingsDimmingView)
        view.addSubview(settingsOverlayView)
        
        NSLayoutConstraint.activate([
            settingsDimmingView.topAnchor.constraint(equalTo: view.topAnchor),
            settingsDimmingView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            settingsDimmingView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            settingsDimmingView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            settingsOverlayView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            settingsOverlayView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            settingsOverlayView.heightAnchor.constraint(equalToConstant: screenHeight),
            settingsOverlayView.bottomAnchor.constraint(equalTo: view.topAnchor)
        ])
        
        setupSettingsViewController()
        
        settingsOverlayView.layer.zPosition = 100
        settingsDimmingView.layer.zPosition = 50
    }
    
    private func setupBookmarkPanel() {
        // Container view for the bookmark panel
        bookmarkPanelContainerView = UIView()
        bookmarkPanelContainerView?.translatesAutoresizingMaskIntoConstraints = false
        bookmarkPanelContainerView?.isHidden = true
        
        // Create and configure bookmark panel
        bookmarkPanelViewController = BookmarkPanelViewController()
        bookmarkPanelViewController?.delegate = self
        
        if let containerView = bookmarkPanelContainerView,
           let panelVC = bookmarkPanelViewController {
            view.addSubview(containerView)
            
            addChild(panelVC)
            containerView.addSubview(panelVC.view)
            panelVC.didMove(toParent: self)
            
            panelVC.view.translatesAutoresizingMaskIntoConstraints = false
            
            // Setup constraints
            bookmarkPanelLeadingConstraint = containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: -70)
            
            NSLayoutConstraint.activate([
                containerView.topAnchor.constraint(equalTo: view.topAnchor),
                containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                containerView.widthAnchor.constraint(equalToConstant: 70),
                bookmarkPanelLeadingConstraint!,
                
                panelVC.view.topAnchor.constraint(equalTo: containerView.topAnchor),
                panelVC.view.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
                panelVC.view.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
                panelVC.view.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
            ])
            
            // Set z-order so bookmark panel is below the top gradient
            containerView.layer.zPosition = 10
        }
    }
    
    private func setupSettingsViewController() {
        settingsViewController = SettingsViewController()
        
        guard let settingsVC = settingsViewController else { return }
        
        addChild(settingsVC)
        
        let settingsView = settingsVC.view!
        settingsView.translatesAutoresizingMaskIntoConstraints = false
        settingsOverlayView.addSubview(settingsView)
        
        NSLayoutConstraint.activate([
            settingsView.topAnchor.constraint(equalTo: settingsOverlayView.topAnchor),
            settingsView.leadingAnchor.constraint(equalTo: settingsOverlayView.leadingAnchor),
            settingsView.trailingAnchor.constraint(equalTo: settingsOverlayView.trailingAnchor),
            settingsView.bottomAnchor.constraint(equalTo: settingsOverlayView.bottomAnchor)
        ])
        
        settingsVC.didMove(toParent: self)
    }
    
    // MARK: - Gesture Setup
    
    private func setupGestures() {
        settingsPanGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handleSettingsPanGesture(_:)))
        settingsPanGestureRecognizer?.delegate = self
        view.addGestureRecognizer(settingsPanGestureRecognizer!)
        
        scrollView.panGestureRecognizer.require(toFail: settingsPanGestureRecognizer!)
        
        // Add single tap gesture to handle both bookmark panel show/hide
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleSettingsChanged),
            name: .settingsChanged,
            object: nil
        )
    }
    
    // MARK: - Chapter Content Management
    
    private func updateLabels(book: Book, chapter: Int) {
        bookLabel.text = book.name
        chapterLabel.text = "Chapter \(chapter)"
        floatingIndicatorLabel.text = "\(book.name) • Chapter \(chapter)"
    }
    
    private func clearExistingContent() {
        versesStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        verseNumberLabels.forEach { $0.removeFromSuperview() }
        verseNumberLabels.removeAll()
    }
    
    private func getCachedOrCreateText(book: Book, chapter: Int, verses: [Verse]) -> String {
        let cacheKey = "\(book.name)_\(chapter)"
        
        if let cachedText = chapterTextCache[cacheKey] {
            return cachedText
        } else {
            let fullText = verses.map { $0.text }.joined(separator: " ")
            chapterTextCache[cacheKey] = fullText
            return fullText
        }
    }
    
    private func restoreScrollPosition(book: Book, chapter: Int) {
        // Update timestamp to mark this chapter as currently being viewed
        UserDataManager.shared.updateChapterViewTimestamp(book: book.name, chapter: chapter)
        
        // Get saved position (will be 0 if > 24 hours old)
        let savedPosition = UserDataManager.shared.getChapterScrollPosition(book: book.name, chapter: chapter)
        if savedPosition > 0 {
            scrollView.setContentOffset(CGPoint(x: 0, y: savedPosition), animated: false)
        } else {
            scrollView.setContentOffset(.zero, animated: false)
        }
    }
    
    private func updateReadingPosition(book: Book, chapter: Int) {
        let savedPosition = UserDataManager.shared.getChapterScrollPosition(book: book.name, chapter: chapter)
        UserDataManager.shared.saveReadingPosition(
            book: book.name,
            chapter: chapter,
            scrollPosition: savedPosition
        )
    }
    
    // MARK: - Settings Gesture Handlers
    
    @objc private func handleSettingsPanGesture(_ gesture: UIPanGestureRecognizer) {
        // Dismiss bookmark panel when interacting with settings
        if bookmarkPanelVisible {
            hideBookmarkPanel()
        }
        
        let translation = gesture.translation(in: view)
        let velocity = gesture.velocity(in: view)
        
        switch gesture.state {
        case .began:
            let atScrollTop = scrollView.contentOffset.y <= 0
            let canPullDown = !settingsIsVisible && atScrollTop && velocity.y > 0
            let canPushUp = settingsIsVisible && velocity.y < 0
            
            if canPullDown || canPushUp {
                isDraggingSettings = true
            }
            
        case .changed:
            guard isDraggingSettings else { return }
            
            if !settingsIsVisible {
                handlePullDownToRevealSettings(translation: translation.y)
            } else {
                handlePushUpToHideSettings(translation: translation.y)
            }
            
        case .ended, .cancelled:
            guard isDraggingSettings else { return }
            
            if !settingsIsVisible {
                if translation.y >= pullActivationThreshold || velocity.y > 800 {
                    animateShowSettings()
                } else {
                    animateHideSettings()
                }
            } else {
                if abs(translation.y) >= pushActivationThreshold || velocity.y < -800 {
                    animateHideSettings()
                } else {
                    animateShowSettings()
                }
            }
            
            isDraggingSettings = false
            gesture.setTranslation(.zero, in: view)
            
        default:
            break
        }
    }
    
    private func handlePullDownToRevealSettings(translation: CGFloat) {
        let resistance = elasticResistanceCurve(distance: translation, maxDistance: maxElasticDistance)
        let elasticTranslation = translation * resistance
        let yTranslation = min(elasticTranslation, screenHeight)
        
        settingsOverlayView.transform = CGAffineTransform(translationX: 0, y: yTranslation)
        
        let progress = yTranslation / screenHeight
        settingsDimmingView.alpha = progress * 0.4
        if !settingsDimmingView.isHidden && settingsDimmingView.alpha > 0 {
            settingsDimmingView.isHidden = false
        }
    }
    
    private func handlePushUpToHideSettings(translation: CGFloat) {
        let upwardTranslation = abs(translation)
        let resistance = elasticResistanceCurve(distance: upwardTranslation, maxDistance: maxElasticDistance)
        let elasticTranslation = upwardTranslation * resistance
        let yTranslation = max(0, screenHeight - elasticTranslation)
        
        settingsOverlayView.transform = CGAffineTransform(translationX: 0, y: yTranslation)
        
        let progress = yTranslation / screenHeight
        settingsDimmingView.alpha = 0.4 * progress
    }
    
    private func elasticResistanceCurve(distance: CGFloat, maxDistance: CGFloat) -> CGFloat {
        let normalizedDistance = min(distance / maxDistance, 1.0)
        let resistance = elasticDamping * (1.0 - pow(1.0 - normalizedDistance, 3.0))
        return max(0.1, resistance)
    }
    
    private func animateShowSettings() {
        guard !settingsIsVisible && !isAnimatingSettings else { return }
        
        isAnimatingSettings = true
        settingsIsVisible = true
        settingsDimmingView.isHidden = false
        
        UIView.animate(
            withDuration: 0.5,
            delay: 0,
            usingSpringWithDamping: 0.8,
            initialSpringVelocity: 0.3,
            options: [.curveEaseOut, .allowUserInteraction]
        ) {
            self.settingsOverlayView.transform = CGAffineTransform(translationX: 0, y: self.screenHeight)
            self.settingsDimmingView.alpha = 0.4
        } completion: { _ in
            self.isAnimatingSettings = false
        }
    }
    
    private func animateHideSettings() {
        guard !isAnimatingSettings else { return }
        
        isAnimatingSettings = true
        settingsIsVisible = false
        
        UIView.animate(
            withDuration: 0.5,
            delay: 0,
            usingSpringWithDamping: 0.8,
            initialSpringVelocity: 0.3,
            options: [.curveEaseOut, .allowUserInteraction]
        ) {
            self.settingsOverlayView.transform = .identity
            self.settingsDimmingView.alpha = 0
        } completion: { _ in
            self.settingsDimmingView.isHidden = true
            self.isAnimatingSettings = false
        }
    }
    
    // MARK: - Action Handlers
    
    @objc private func handleSettingsChanged() {
        if let book = currentBook {
            loadChapter(book: book, chapter: currentChapter)
        }
    }
    
    @objc private func bookTitleTapped() {
        // Dismiss bookmark panel when opening book selection
        if bookmarkPanelVisible {
            hideBookmarkPanel()
        }
        
        // Clear current bookmark when using book selector
        BookmarkManager.shared.clearCurrentBookmark()
        
        let bookVC = BookSelectionViewController()
        bookVC.delegate = self
        bookVC.modalPresentationStyle = .pageSheet
        if let sheet = bookVC.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
        }
        present(bookVC, animated: true)
    }
    
    // MARK: - Verse Selection Handlers
    
    @objc private func handleVerseLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else { return }
        
        // Try to detect which verse was pressed (simplified - just use verse 1 for now)
        // In a full implementation, we'd calculate based on the touch location
        let touchPoint = gesture.location(in: gesture.view)
        let detectedVerse = detectVerseAtPoint(touchPoint, in: gesture.view as? UITextView)
        
        // Set initial selection to the detected verse
        selectedVerseStart = detectedVerse
        selectedVerseEnd = detectedVerse
        
        // Present the selection sheet
        presentVerseSelectionSheet()
    }
    
    private func detectVerseAtPoint(_ point: CGPoint, in textView: UITextView?) -> Int {
        // Simplified implementation - in reality we'd calculate based on text layout
        // For now, just return verse 1 or a middle verse
        guard let verses = currentChapterVerses.first else { return 1 }
        return verses.number
    }
    
    private func presentVerseSelectionSheet() {
        let selectionVC = VerseSelectionViewController()
        
        // Update with current data
        selectionVC.currentBook = currentBook
        selectionVC.currentChapter = currentChapter
        selectionVC.verses = currentChapterVerses
        selectionVC.startVerse = selectedVerseStart
        selectionVC.endVerse = selectedVerseEnd
        selectionVC.delegate = self
        
        // Configure presentation
        selectionVC.modalPresentationStyle = .pageSheet
        if let sheet = selectionVC.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
            sheet.prefersScrollingExpandsWhenScrolledToEdge = false
            sheet.preferredCornerRadius = 20
        }
        
        present(selectionVC, animated: true)
    }
}

// MARK: - Chapter Content Creation

extension ChapterViewController {
    
    private func createChapterParagraphView(text: String, verses: [Verse] = []) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.clipsToBounds = false // Don't clip verse numbers in margin
        
        let firstChar = String(text.prefix(1)).uppercased()
        
        let dropCapContainer = createDropCap(with: firstChar)
        let textView = createTextView(with: text, verses: verses)
        
        container.addSubview(textView)
        container.addSubview(dropCapContainer) // Add drop cap on top
        
        // Add long press gesture recognizer to text view for sharing
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleVerseLongPress(_:)))
        longPress.minimumPressDuration = 0.5
        textView.addGestureRecognizer(longPress)
        
        // Store current chapter verses for sharing
        currentChapterVerses = verses
        
        NSLayoutConstraint.activate([
            // Drop cap container
            dropCapContainer.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            dropCapContainer.topAnchor.constraint(equalTo: container.topAnchor),
            dropCapContainer.widthAnchor.constraint(equalToConstant: 70),
            dropCapContainer.heightAnchor.constraint(equalToConstant: 70),
            
            // Text view fills the container (with slight vertical offset)
            textView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            textView.topAnchor.constraint(equalTo: container.topAnchor, constant: 3),
            textView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            textView.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        
        // Position verse numbers after layout
        if !verses.isEmpty {
            textView.tag = 999 // Tag to identify this text view
            
            textView.setNeedsLayout()
            textView.layoutIfNeeded()
            container.setNeedsLayout()
            container.layoutIfNeeded()
            
            DispatchQueue.main.async { [weak self] in
                // Force layout without accessing layoutManager
                textView.setNeedsLayout()
                textView.layoutIfNeeded()
                self?.positionVerseNumbers(in: textView, container: container, verses: verses)
                
                if let visible = self?.verseNumbersVisible {
                    UIView.animate(withDuration: 0.2) {
                        self?.verseNumberLabels.forEach { label in
                            label.alpha = visible ? 1.0 : 0.0
                        }
                    }
                }
            }
        }
        
        return container
    }
    
    private func createDropCap(with character: String) -> UIView {
        let dropCapContainer = UIView()
        dropCapContainer.translatesAutoresizingMaskIntoConstraints = false
        dropCapContainer.backgroundColor = UIColor(red: 0.82, green: 0.72, blue: 0.58, alpha: 0.5)
        dropCapContainer.layer.borderColor = UIColor(red: 0.35, green: 0.25, blue: 0.15, alpha: 1.0).cgColor
        dropCapContainer.layer.borderWidth = 2
        
        let dropCapLabel = UILabel()
        dropCapLabel.translatesAutoresizingMaskIntoConstraints = false
        dropCapLabel.text = character
        
        // Try gothic font, fallback to Cardo Bold
        let gothicFont = UIFont(name: "UnifrakturMaguntia-Book", size: 60) ??
                        UIFont(name: "UnifrakturMaguntia", size: 60) ??
                        UIFont(name: "Unifraktur Maguntia", size: 60)
        dropCapLabel.font = gothicFont ?? UIFont(name: "Cardo-Bold", size: 60) ?? .systemFont(ofSize: 60, weight: .bold)
        
        dropCapLabel.textColor = UIColor(red: 0.15, green: 0.1, blue: 0.05, alpha: 1.0)
        dropCapLabel.textAlignment = .center
        
        dropCapContainer.addSubview(dropCapLabel)
        
        NSLayoutConstraint.activate([
            dropCapLabel.centerXAnchor.constraint(equalTo: dropCapContainer.centerXAnchor),
            dropCapLabel.centerYAnchor.constraint(equalTo: dropCapContainer.centerYAnchor, constant: 5)
        ])
        
        return dropCapContainer
    }
    
    private func createTextView(with text: String, verses: [Verse]) -> UITextView {
        let textView = UITextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.isEditable = false
        textView.isSelectable = false  // Disable text selection
        textView.isScrollEnabled = false
        textView.backgroundColor = .clear
        textView.textContainerInset = UIEdgeInsets.zero
        textView.textContainer.lineFragmentPadding = 0
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 10
        paragraphStyle.alignment = .left // Left-aligned for consistent verse number positioning
        
        let attributedString = NSMutableAttributedString()
        let textWithoutFirstChar = String(text.dropFirst())
        
        if !verses.isEmpty {
            for (index, verse) in verses.enumerated() {
                let verseText = verse.text
                let adjustedText = index == 0 ? String(verseText.dropFirst()) : verseText
                
                let verseAttrString = NSAttributedString(
                    string: adjustedText + (index < verses.count - 1 ? "  " : ""), // Two spaces between verses
                    attributes: [
                        .font: UIFont(name: "Cardo-Regular", size: 20) ?? .systemFont(ofSize: 18),
                        .foregroundColor: UIColor(red: 0.05, green: 0.03, blue: 0.01, alpha: 1.0),
                        .paragraphStyle: paragraphStyle
                    ]
                )
                
                attributedString.append(verseAttrString)
            }
        } else {
            // Fallback if no verse data
            attributedString.append(NSAttributedString(
                string: textWithoutFirstChar,
                attributes: [
                    .font: UIFont(name: "Cardo-Regular", size: 20) ?? .systemFont(ofSize: 18),
                    .foregroundColor: UIColor(red: 0.05, green: 0.03, blue: 0.01, alpha: 1.0),
                    .paragraphStyle: paragraphStyle
                ]
            ))
        }
        
        textView.attributedText = attributedString
        
        // Create exclusion path for text to wrap around drop cap
        let exclusionPath = UIBezierPath(rect: CGRect(x: 0, y: 0, width: 80, height: 70))
        textView.textContainer.exclusionPaths = [exclusionPath]
        
        return textView
    }
    
    private func positionVerseNumbers(in textView: UITextView, container: UIView, verses: [Verse]) {
        verseNumberLabels.forEach { $0.removeFromSuperview() }
        verseNumberLabels.removeAll()
        
        var currentLocation = 0
        
        for (index, verse) in verses.enumerated() {
            // Skip verse 1
            if verse.number == 1 {
                currentLocation += index == 0 ? verse.text.count - 1 + 2 : verse.text.count + 2
                continue
            }
            
            let verseLabel = createVerseNumberLabel(for: verse.number)
            
            var searchLocation = currentLocation
            let textString = textView.text as NSString
            
            // Skip leading whitespace
            while searchLocation < textString.length {
                let char = textString.character(at: searchLocation)
                if char != 32 && char != 10 && char != 13 { // Not space, newline, or carriage return
                    break
                }
                searchLocation += 1
            }
            
            // Use TextKit 2 approach - get the frame directly from textView
            guard searchLocation < textString.length else { continue }
            
            // Get the rect for the character position without accessing layoutManager
            guard let position = textView.position(from: textView.beginningOfDocument, offset: searchLocation),
                  let range = textView.textRange(from: position, to: position) else { continue }
            
            let rect = textView.firstRect(for: range)
            
            verseLabel.sizeToFit()
            
            let xPosition: CGFloat = rect.origin.x + textView.frame.origin.x - verseLabel.bounds.width - 2
            let yPosition = rect.origin.y + textView.frame.origin.y - verseLabel.bounds.height + 14
            
            verseLabel.frame = CGRect(
                x: xPosition,
                y: yPosition,
                width: verseLabel.bounds.width,
                height: verseLabel.bounds.height
            )
            
            container.addSubview(verseLabel)
            verseLabel.layer.zPosition = 100
            
            currentLocation += verse.text.count + 2
        }
    }
    
    private func createVerseNumberLabel(for verseNumber: Int) -> UILabel {
        let verseLabel = UILabel()
        verseLabel.text = "\(verseNumber)"
        verseLabel.font = UIFont(name: "Cardo-Bold", size: 11) ?? .systemFont(ofSize: 11, weight: .bold)
        verseLabel.textColor = UIColor(red: 0.05, green: 0.03, blue: 0.01, alpha: 1.0)
        verseLabel.backgroundColor = .clear
        verseLabel.alpha = 0 // Start hidden for animation
        verseLabel.tag = verseNumber
        verseNumberLabels.append(verseLabel)
        return verseLabel
    }
}

// MARK: - BookSelectionDelegate

extension ChapterViewController: BookSelectionDelegate {
    func didSelectBook(_ book: Book) {
        NotificationCenter.default.post(
            name: .chapterSelected,
            object: nil,
            userInfo: ["book": book, "chapter": 1]
        )
    }
}

// MARK: - UIScrollViewDelegate

extension ChapterViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // Dismiss bookmark panel on scroll
        if bookmarkPanelVisible {
            hideBookmarkPanel()
        }
        
        let yOffset = scrollView.contentOffset.y
        
        // Update floating indicator visibility
        let headerBottom = chapterHeaderView.frame.height + 20
        let shouldShowIndicator = yOffset > headerBottom
        
        if shouldShowIndicator != floatingIndicatorVisible {
            floatingIndicatorVisible = shouldShowIndicator
            UIView.animate(withDuration: 0.2) {
                self.floatingIndicatorView.alpha = shouldShowIndicator ? 1.0 : 0.0
            }
        }
        
        // Save scroll position
        if let book = currentBook {
            UserDataManager.shared.saveChapterScrollPosition(
                book: book.name,
                chapter: currentChapter,
                scrollPosition: yOffset
            )
        }
    }
}

// MARK: - VerseSelectionViewControllerDelegate

extension ChapterViewController: VerseSelectionViewControllerDelegate {
    func verseSelectionViewController(_ controller: VerseSelectionViewController, didSelectVerses verses: [(Int, String)], book: Book, chapter: Int) {
        // Verse sharing completed - could add additional handling here if needed
    }
}

// MARK: - UIGestureRecognizerDelegate

extension ChapterViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer == settingsPanGestureRecognizer && otherGestureRecognizer == scrollView.panGestureRecognizer {
            return scrollView.contentOffset.y <= 0
        }
        return false
    }
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer == settingsPanGestureRecognizer {
            if let panGesture = gestureRecognizer as? UIPanGestureRecognizer {
                let velocity = panGesture.velocity(in: view)
                let location = panGesture.location(in: view)
                
                let isVerticalGesture = abs(velocity.y) > abs(velocity.x) * 0.5
                
                if settingsIsVisible {
                    let touchingSettings = settingsOverlayView.frame.contains(location)
                    return touchingSettings && isVerticalGesture && velocity.y < 0
                } else {
                    let atScrollTop = scrollView.contentOffset.y <= 0
                    return atScrollTop && isVerticalGesture && velocity.y > 0
                }
            }
        }
        return true
    }
}

// MARK: - Bookmark Panel Methods

extension ChapterViewController {
    
    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: view)
        
        if location.x < 80 {
            // Left edge tap - toggle bookmark panel (wider zone)
            if !bookmarkPanelVisible {
                showBookmarkPanel()
            }
        } else if bookmarkPanelVisible && location.x > 80 {
            // Tap outside panel - hide it
            hideBookmarkPanel()
        }
    }
    
    private func toggleBookmarkPanel() {
        if bookmarkPanelVisible {
            hideBookmarkPanel()
        } else {
            showBookmarkPanel()
        }
    }
    
    private func showBookmarkPanel() {
        guard let containerView = bookmarkPanelContainerView else { return }
        
        // Refresh bookmarks
        bookmarkPanelViewController?.loadBookmarks()
        
        // Show and animate panel
        containerView.isHidden = false
        bookmarkPanelLeadingConstraint?.constant = 0
        
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5) {
            self.view.layoutIfNeeded()
        } completion: { _ in
            self.bookmarkPanelVisible = true
        }
    }
    
    func hideBookmarkPanel() {
        bookmarkPanelLeadingConstraint?.constant = -70
        
        UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseInOut) {
            self.view.layoutIfNeeded()
        } completion: { _ in
            self.bookmarkPanelContainerView?.isHidden = true
            self.bookmarkPanelVisible = false
        }
    }
}

// MARK: - BookmarkPanelDelegate

extension ChapterViewController: BookmarkPanelDelegate {
    
    func bookmarkPanelDidAddBookmark(_ panel: BookmarkPanelViewController) {
        guard let book = currentBook else { return }
        
        // Add bookmark and set as current
        let bookmark = BookmarkManager.shared.addBookmark(bookName: book.name, chapter: currentChapter)
        BookmarkManager.shared.setCurrentBookmark(bookmark)
        
        // Reload bookmarks in panel
        panel.loadBookmarks()
        
        // Hide panel after adding
        hideBookmarkPanel()
    }
    
    func bookmarkPanel(_ panel: BookmarkPanelViewController, didSelectBookmark bookmark: BookmarkItem) {
        // Set as current bookmark
        BookmarkManager.shared.setCurrentBookmark(bookmark)
        
        // Navigate to bookmark - delegate to parent container instead of handling locally
        navigateToBookmark(bookmark)
        
        // Hide panel
        hideBookmarkPanel()
    }
    
    private func navigateToBookmark(_ bookmark: BookmarkItem) {
        // Find the book
        guard let targetBook = ScriptureManager.shared.books.first(where: { $0.name == bookmark.bookName }) else { 
            print("ERROR: Could not find book named: \(bookmark.bookName)")
            return 
        }
        
        // The parent is UIPageViewController, so we need to go up one more level to get ChapterContainerViewController
        if let pageVC = parent as? UIPageViewController,
           let containerVC = pageVC.parent as? ChapterContainerViewController {
            print("Navigating to bookmark: \(bookmark.bookName) \(bookmark.chapter)")
            containerVC.navigateToBookmark(book: targetBook, chapter: bookmark.chapter, scrollPosition: 0)
        } else {
            print("ERROR: Could not find ChapterContainerViewController in hierarchy")
            print("Parent: \(String(describing: parent))")
            if let pageVC = parent as? UIPageViewController {
                print("PageVC parent: \(String(describing: pageVC.parent))")
            }
        }
    }
}