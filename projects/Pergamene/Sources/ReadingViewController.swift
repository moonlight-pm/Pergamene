import UIKit

class ReadingViewController: UIViewController {
    
    private let scrollView = UIScrollView()
    private let contentView = UIView() // Only contains reading content
    private let topFadeView = UIView()
    private let topFadeGradient = CAGradientLayer()
    private let chapterHeaderView = UIView()
    private let bookLabel = UILabel()
    private let chapterLabel = UILabel()
    private let versesStackView = UIStackView()
    
    // Floating chapter indicator
    private let floatingIndicatorView = UIView()
    private let floatingIndicatorLabel = UILabel()
    private var floatingIndicatorVisible = false
    
    // Settings overlay system - completely separate from scroll content
    private let settingsOverlayView = UIView()
    private let settingsDimmingView = UIView()
    private var settingsViewController: SettingsViewController?
    private var settingsIsVisible = false
    private let screenHeight: CGFloat = UIScreen.main.bounds.height
    
    // Enhanced elastic pull parameters
    private let pullActivationThreshold: CGFloat = 90.0  // Distance to trigger show (150% more)
    private let pushActivationThreshold: CGFloat = 90.0   // Distance to trigger hide (same as pull)
    private let elasticDamping: CGFloat = 0.6            // Controls resistance feel
    private let maxElasticDistance: CGFloat = 120.0     // Maximum elastic pull
    
    // Animation and state tracking
    private var isAnimatingSettings = false
    private var isDraggingSettings = false
    private var settingsPanGestureRecognizer: UIPanGestureRecognizer?
    
    private var currentBook: Book?
    private var currentChapter: Int = 1
    private var chapterTextCache: [String: String] = [:]
    private var chapterHeaderTopConstraint: NSLayoutConstraint?
    private var verseNumberLabels: [UILabel] = []
    private var verseNumbersVisible: Bool {
        return UserDefaults.standard.bool(forKey: "ShowVerseNumbers")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set default for verse numbers if not set
        if UserDefaults.standard.object(forKey: "ShowVerseNumbers") == nil {
            UserDefaults.standard.set(true, forKey: "ShowVerseNumbers")
        }
        
        view.backgroundColor = .black // Black for overscroll areas
        scrollView.contentInsetAdjustmentBehavior = .never // Disable automatic inset adjustment
        
        setupViews()
        setupSettingsOverlay()
        setupGestures()
        setupNotifications()
        loadLastReadingPosition()
    }
    
    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        // Update top padding based on safe area
        chapterHeaderTopConstraint?.constant = view.safeAreaInsets.top + 20
        updateGradientMask()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateGradientMask()
    }
    
    private func updateGradientMask() {
        // Update gradient frame
        topFadeGradient.frame = topFadeView.bounds
        
        // Adjust gradient height based on safe area
        let safeAreaTop = view.safeAreaInsets.top
        if safeAreaTop > 0 {
            topFadeView.constraints.first { $0.firstAttribute == .height }?.constant = safeAreaTop + 20
        }
    }
    
    private func setupViews() {
        setupScrollView()
        setupChapterHeader()
        setupVersesStackView()
        setupFloatingIndicator()
    }
    
    private func setupScrollView() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.backgroundColor = .black
        scrollView.delegate = self
        scrollView.clipsToBounds = false  // Allow bounce beyond bounds
        scrollView.alwaysBounceVertical = true
        scrollView.bounces = true
        scrollView.bouncesZoom = false
        scrollView.showsVerticalScrollIndicator = true
        scrollView.decelerationRate = .normal
        scrollView.contentInsetAdjustmentBehavior = .never
        
        // Content view only contains reading content - much simpler
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.backgroundColor = UIColor.parchmentTexture
        contentView.clipsToBounds = false // Don't clip verse numbers
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        // Setup gradient mask for fading text in safe area
        setupGradientMask()
        
        NSLayoutConstraint.activate([
            // Scroll view fills the entire view
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Content view defines scroll content - starts at y=0 (no offset needed)
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
        
        // No need to set initial offset - content starts at y=0 naturally
        scrollView.contentInset = UIEdgeInsets.zero
        scrollView.scrollIndicatorInsets = UIEdgeInsets.zero
    }
    
    private func setupGradientMask() {
        topFadeView.translatesAutoresizingMaskIntoConstraints = false
        topFadeView.isUserInteractionEnabled = false
        
        // Configure gradient layer with ease-in curve - more color stops for smoother transition
        topFadeGradient.colors = [
            UIColor.black.withAlphaComponent(0.7).cgColor,   // 70% black at top
            UIColor.black.withAlphaComponent(0.65).cgColor,  // Gradual fade starts
            UIColor.black.withAlphaComponent(0.5).cgColor,   
            UIColor.black.withAlphaComponent(0.35).cgColor,  
            UIColor.black.withAlphaComponent(0.2).cgColor,   
            UIColor.black.withAlphaComponent(0.1).cgColor,   
            UIColor.black.withAlphaComponent(0.05).cgColor,  
            UIColor.black.withAlphaComponent(0.02).cgColor,  
            UIColor.black.withAlphaComponent(0).cgColor      // Transparent at bottom
        ]
        // Ease-in curve positioning - more gradual at the bottom
        topFadeGradient.locations = [0, 0.2, 0.35, 0.5, 0.65, 0.75, 0.85, 0.95, 1]
        topFadeGradient.startPoint = CGPoint(x: 0.5, y: 0)
        topFadeGradient.endPoint = CGPoint(x: 0.5, y: 1)
        
        topFadeView.layer.addSublayer(topFadeGradient)
        view.addSubview(topFadeView)
        
        NSLayoutConstraint.activate([
            topFadeView.topAnchor.constraint(equalTo: view.topAnchor),
            topFadeView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topFadeView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            topFadeView.heightAnchor.constraint(equalToConstant: 100) // Adjust height as needed
        ])
    }
    
    private func setupChapterHeader() {
        chapterHeaderView.translatesAutoresizingMaskIntoConstraints = false
        chapterHeaderView.backgroundColor = .clear
        
        // Make the header tappable
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(bookTitleTapped))
        chapterHeaderView.addGestureRecognizer(tapGesture)
        chapterHeaderView.isUserInteractionEnabled = true
        
        bookLabel.translatesAutoresizingMaskIntoConstraints = false
        bookLabel.font = UIFont(name: "Cardo-Bold", size: 26) ?? .systemFont(ofSize: 24, weight: .semibold)
        bookLabel.textColor = UIColor(red: 0.15, green: 0.1, blue: 0.05, alpha: 1.0) // Much darker
        bookLabel.textAlignment = .center
        bookLabel.isUserInteractionEnabled = true
        
        chapterLabel.translatesAutoresizingMaskIntoConstraints = false
        chapterLabel.font = UIFont(name: "Cardo-Regular", size: 20) ?? .systemFont(ofSize: 18, weight: .regular)
        chapterLabel.textColor = UIColor(red: 0.25, green: 0.18, blue: 0.12, alpha: 1.0) // Darker
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
        versesStackView.clipsToBounds = false // Don't clip verse numbers
        
        contentView.addSubview(versesStackView)
        
        // Add extra bottom padding for comfortable reading (1/2 of screen height)
        let extraBottomSpace = UIScreen.main.bounds.height * 0.5
        
        NSLayoutConstraint.activate([
            versesStackView.topAnchor.constraint(equalTo: chapterHeaderView.bottomAnchor, constant: 20),
            versesStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            versesStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            versesStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -extraBottomSpace)
        ])
    }
    
    private func setupFloatingIndicator() {
        // Setup floating indicator view
        floatingIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        floatingIndicatorView.backgroundColor = UIColor(red: 0.05, green: 0.03, blue: 0.01, alpha: 0.85) // Dark semi-transparent
        floatingIndicatorView.alpha = 0 // Start hidden
        
        // Setup label
        floatingIndicatorLabel.translatesAutoresizingMaskIntoConstraints = false
        floatingIndicatorLabel.font = UIFont(name: "Cardo-Regular", size: 14) ?? .systemFont(ofSize: 14)
        floatingIndicatorLabel.textColor = UIColor(red: 0.95, green: 0.92, blue: 0.88, alpha: 1.0) // Light parchment color
        floatingIndicatorLabel.textAlignment = .center
        
        floatingIndicatorView.addSubview(floatingIndicatorLabel)
        view.addSubview(floatingIndicatorView)
        
        // Position just below safe area
        NSLayoutConstraint.activate([
            floatingIndicatorView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            floatingIndicatorView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            floatingIndicatorView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            floatingIndicatorView.heightAnchor.constraint(equalToConstant: 28),
            
            floatingIndicatorLabel.centerYAnchor.constraint(equalTo: floatingIndicatorView.centerYAnchor),
            floatingIndicatorLabel.leadingAnchor.constraint(equalTo: floatingIndicatorView.leadingAnchor, constant: 20),
            floatingIndicatorLabel.trailingAnchor.constraint(equalTo: floatingIndicatorView.trailingAnchor, constant: -20)
        ])
        
        // Ensure it stays above scroll content but below fade gradient
        floatingIndicatorView.layer.zPosition = 10
    }
    
    // MARK: - Settings Overlay System
    
    private func setupSettingsOverlay() {
        // Setup dimming view (sits between reader and settings)
        settingsDimmingView.translatesAutoresizingMaskIntoConstraints = false
        settingsDimmingView.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        settingsDimmingView.alpha = 0
        settingsDimmingView.isHidden = true
        settingsDimmingView.isUserInteractionEnabled = false  // No tap to dismiss
        
        // Setup settings overlay view (floats above everything)
        settingsOverlayView.translatesAutoresizingMaskIntoConstraints = false
        settingsOverlayView.backgroundColor = UIColor.parchmentTexture
        
        // Setup the settings view controller content
        setupSettingsViewController()
        
        // Add shadow to show it's floating
        settingsOverlayView.layer.shadowColor = UIColor.black.cgColor
        settingsOverlayView.layer.shadowOffset = CGSize(width: 0, height: 4)
        settingsOverlayView.layer.shadowOpacity = 0.3
        settingsOverlayView.layer.shadowRadius = 8
        
        // Add to view hierarchy
        view.addSubview(settingsDimmingView)
        view.addSubview(settingsOverlayView)
        
        // Position settings off-screen above the view
        NSLayoutConstraint.activate([
            // Dimming view covers the entire view
            settingsDimmingView.topAnchor.constraint(equalTo: view.topAnchor),
            settingsDimmingView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            settingsDimmingView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            settingsDimmingView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Settings overlay starts positioned off-screen above
            settingsOverlayView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            settingsOverlayView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            settingsOverlayView.heightAnchor.constraint(equalToConstant: screenHeight),
            settingsOverlayView.bottomAnchor.constraint(equalTo: view.topAnchor) // Initially off-screen above
        ])
        
        // Create and setup settings view controller
        setupSettingsViewController()
        
        // Ensure overlay is above other views
        settingsOverlayView.layer.zPosition = 100
        settingsDimmingView.layer.zPosition = 50
    }
    
    private func setupSettingsViewController() {
        settingsViewController = SettingsViewController()
        
        guard let settingsVC = settingsViewController else { return }
        
        // Add as child view controller
        addChild(settingsVC)
        
        // Add settings view to the overlay
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
    
    // MARK: - Gesture System
    
    private func setupGestures() {
        // Settings overlay pan gesture - only activates when at scroll position 0
        settingsPanGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handleSettingsPanGesture(_:)))
        settingsPanGestureRecognizer?.delegate = self
        view.addGestureRecognizer(settingsPanGestureRecognizer!)
        
        // Configure swipe gestures for chapter navigation
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeLeft))
        swipeLeft.direction = .left
        swipeLeft.delegate = self
        contentView.addGestureRecognizer(swipeLeft)
        
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeRight))
        swipeRight.direction = .right
        swipeRight.delegate = self
        contentView.addGestureRecognizer(swipeRight)
        
        // No swipe-up to dismiss - only push-up gesture works
    }
    
    @objc private func handleSettingsPanGesture(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: view)
        let velocity = gesture.velocity(in: view)
        
        switch gesture.state {
        case .began:
            // Only begin if we're at the top of scroll view and pulling down, or settings are visible and pushing up
            let atScrollTop = scrollView.contentOffset.y <= 0
            let canPullDown = !settingsIsVisible && atScrollTop && velocity.y > 0
            let canPushUp = settingsIsVisible && velocity.y < 0
            
            if canPullDown || canPushUp {
                isDraggingSettings = true
            }
            
        case .changed:
            guard isDraggingSettings else { return }
            
            if !settingsIsVisible {
                // Pulling down from reader to reveal settings
                handlePullDownToRevealSettings(translation: translation.y)
            } else {
                // Pushing up from settings to hide
                handlePushUpToHideSettings(translation: translation.y)
            }
            
        case .ended, .cancelled:
            guard isDraggingSettings else { return }
            
            if !settingsIsVisible {
                // Determine if we should show settings based on pull distance and velocity
                if translation.y >= pullActivationThreshold || velocity.y > 800 {
                    animateShowSettings()
                } else {
                    animateHideSettings()
                }
            } else {
                // Determine if we should hide settings based on push distance and velocity
                if abs(translation.y) >= pushActivationThreshold || velocity.y < -800 {
                    animateHideSettings()
                } else {
                    animateShowSettings()
                }
            }
            
            // Reset state
            isDraggingSettings = false
            gesture.setTranslation(.zero, in: view)
            
        default:
            break
        }
    }
    
    private func handlePullDownToRevealSettings(translation: CGFloat) {
        // Apply elastic resistance
        let resistance = elasticResistanceCurve(distance: translation, maxDistance: maxElasticDistance)
        let elasticTranslation = translation * resistance
        
        // Move settings overlay down from off-screen position
        // Settings start at -screenHeight, pull them down
        let yTranslation = min(elasticTranslation, screenHeight)
        let progress = yTranslation / screenHeight
        
        settingsOverlayView.transform = CGAffineTransform(translationX: 0, y: yTranslation)
        
        // Fade in dimming as we pull
        settingsDimmingView.alpha = progress * 0.4
        if progress > 0 && settingsDimmingView.isHidden {
            settingsDimmingView.isHidden = false
        }
    }
    
    private func handlePushUpToHideSettings(translation: CGFloat) {
        // translation is negative when pushing up, make it positive
        let upwardTranslation = abs(translation)
        
        // Apply elastic resistance for upward push
        let resistance = elasticResistanceCurve(distance: upwardTranslation, maxDistance: maxElasticDistance)
        let elasticTranslation = upwardTranslation * resistance
        
        // Move settings overlay back up from visible position
        // Start at screenHeight (visible), push up towards 0
        let yTranslation = max(0, screenHeight - elasticTranslation)
        
        settingsOverlayView.transform = CGAffineTransform(translationX: 0, y: yTranslation)
        
        // Fade out dimming as we push
        let progress = yTranslation / screenHeight
        settingsDimmingView.alpha = 0.4 * progress
    }
    
    private func elasticResistanceCurve(distance: CGFloat, maxDistance: CGFloat) -> CGFloat {
        // Natural elastic curve - starts easy, gets harder as you pull further
        let normalizedDistance = min(distance / maxDistance, 1.0)
        let resistance = elasticDamping * (1.0 - pow(1.0 - normalizedDistance, 3.0))
        return max(0.1, resistance) // Minimum resistance to maintain responsiveness
    }
    
    private func animateShowSettings() {
        guard !settingsIsVisible && !isAnimatingSettings else { return }
        
        isAnimatingSettings = true
        settingsIsVisible = true
        
        // Show dimming view
        settingsDimmingView.isHidden = false
        
        UIView.animate(
            withDuration: 0.5,
            delay: 0,
            usingSpringWithDamping: 0.8,
            initialSpringVelocity: 0.3,
            options: [.curveEaseOut, .allowUserInteraction]
        ) {
            // Slide settings down to cover the screen (translate by full height)
            self.settingsOverlayView.transform = CGAffineTransform(translationX: 0, y: self.screenHeight)
            // Fade in dimming
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
            // Reset to initial off-screen position (identity since it's positioned off-screen by constraints)
            self.settingsOverlayView.transform = .identity
            // Fade out dimming
            self.settingsDimmingView.alpha = 0
        } completion: { _ in
            self.settingsDimmingView.isHidden = true
            self.isAnimatingSettings = false
        }
    }
    
    @objc private func dismissSettings() {
        animateHideSettings()
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleChapterSelection(_:)),
            name: .chapterSelected,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleSettingsChanged),
            name: .settingsChanged,
            object: nil
        )
    }
    
    // MARK: - Scripture Loading
    
    private func loadChapter() {
        guard let book = currentBook else { return }
        guard let chapter = book.chapters.first(where: { $0.number == currentChapter }) else { return }
        
        // Update labels
        bookLabel.text = book.name
        chapterLabel.text = "Chapter \(currentChapter)"
        
        // Update floating indicator
        floatingIndicatorLabel.text = "\(book.name) • Chapter \(currentChapter)"
        
        // Clear existing content and verse numbers
        versesStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        verseNumberLabels.forEach { $0.removeFromSuperview() }
        verseNumberLabels.removeAll()
        
        // Check cache first
        let cacheKey = "\(book.name)_\(currentChapter)"
        let fullText: String
        
        if let cachedText = chapterTextCache[cacheKey] {
            fullText = cachedText
        } else {
            // Combine all verses into a single paragraph
            fullText = chapter.verses.map { $0.text }.joined(separator: " ")
            // Cache the text
            chapterTextCache[cacheKey] = fullText
        }
        
        // Create single paragraph view with drop cap and verse markers
        let paragraphView = createChapterParagraphView(text: fullText, verses: chapter.verses)
        versesStackView.addArrangedSubview(paragraphView)
        
        // Restore saved scroll position for this chapter (no offset needed)
        let savedPosition = UserDataManager.shared.getChapterScrollPosition(book: book.name, chapter: currentChapter)
        if savedPosition > 0 {
            scrollView.setContentOffset(CGPoint(x: 0, y: savedPosition), animated: false)
        } else {
            // Start at top of content
            scrollView.setContentOffset(CGPoint(x: 0, y: 0), animated: false)
        }
        
        // Update current reading position
        UserDataManager.shared.saveReadingPosition(
            book: book.name,
            chapter: currentChapter,
            scrollPosition: savedPosition
        )
        
        // Preload adjacent chapters in background
        preloadAdjacentChapters()
    }
    
    private func preloadAdjacentChapters() {
        guard let book = currentBook else { return }
        
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self else { return }
            
            // Preload previous chapter
            if self.currentChapter > 1 {
                let prevChapter = self.currentChapter - 1
                let cacheKey = "\(book.name)_\(prevChapter)"
                if self.chapterTextCache[cacheKey] == nil,
                   let chapter = book.chapters.first(where: { $0.number == prevChapter }) {
                    let text = chapter.verses.map { $0.text }.joined(separator: " ")
                    DispatchQueue.main.async {
                        self.chapterTextCache[cacheKey] = text
                    }
                }
            }
            
            // Preload next chapter
            if self.currentChapter < book.chapters.count {
                let nextChapter = self.currentChapter + 1
                let cacheKey = "\(book.name)_\(nextChapter)"
                if self.chapterTextCache[cacheKey] == nil,
                   let chapter = book.chapters.first(where: { $0.number == nextChapter }) {
                    let text = chapter.verses.map { $0.text }.joined(separator: " ")
                    DispatchQueue.main.async {
                        self.chapterTextCache[cacheKey] = text
                    }
                }
            }
        }
    }
    
    private func createChapterParagraphView(text: String, verses: [Verse] = []) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.clipsToBounds = false // Don't clip verse numbers in margin
        
        // Get the first character (but don't remove it from the text yet)
        let firstChar = String(text.prefix(1)).uppercased()
        
        // Create simple boxed drop cap placeholder with parchment-toned colors
        let dropCapContainer = UIView()
        dropCapContainer.translatesAutoresizingMaskIntoConstraints = false
        dropCapContainer.backgroundColor = UIColor(red: 0.82, green: 0.72, blue: 0.58, alpha: 0.5) // Semi-transparent parchment tone
        dropCapContainer.layer.borderColor = UIColor(red: 0.35, green: 0.25, blue: 0.15, alpha: 1.0).cgColor
        dropCapContainer.layer.borderWidth = 2
        
        let dropCapLabel = UILabel()
        dropCapLabel.translatesAutoresizingMaskIntoConstraints = false
        dropCapLabel.text = firstChar
        // Use UnifrakturMaguntia at 60 points
        let gothicFont = UIFont(name: "UnifrakturMaguntia-Book", size: 60) ??
                        UIFont(name: "UnifrakturMaguntia", size: 60) ??
                        UIFont(name: "Unifraktur Maguntia", size: 60)
        dropCapLabel.font = gothicFont ?? UIFont(name: "Cardo-Bold", size: 60) ?? .systemFont(ofSize: 60, weight: .bold)
        
        dropCapLabel.textColor = UIColor(red: 0.15, green: 0.1, blue: 0.05, alpha: 1.0) // Dark text
        dropCapLabel.textAlignment = .center
        
        dropCapContainer.addSubview(dropCapLabel)
        
        // Create text view for proper text wrapping
        let textView = UITextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.backgroundColor = .clear
        textView.textContainerInset = UIEdgeInsets.zero
        textView.textContainer.lineFragmentPadding = 0
        
        // Create attributed string with verse markers
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 10
        paragraphStyle.alignment = .left // Left-aligned for consistent verse number positioning
        
        // Build attributed string with verse positions marked
        let attributedString = NSMutableAttributedString()
        
        // Remove first character for drop cap
        let textWithoutFirstChar = String(text.dropFirst())
        
        // If we have verse data, create markers
        if !verses.isEmpty {
            for (index, verse) in verses.enumerated() {
                let verseText = verse.text
                
                // For verse 1, account for the dropped first character
                let adjustedText = index == 0 ? String(verseText.dropFirst()) : verseText
                
                // Add verse text with extra space between verses
                let verseAttrString = NSAttributedString(
                    string: adjustedText + (index < verses.count - 1 ? "  " : ""), // Two spaces between verses
                    attributes: [
                        .font: UIFont(name: "Cardo-Regular", size: 20) ?? .systemFont(ofSize: 18),
                        .foregroundColor: UIColor(red: 0.05, green: 0.03, blue: 0.01, alpha: 1.0),
                        .paragraphStyle: paragraphStyle
                    ]
                )
                
                // Store the range for this verse (skip verse 1 for numbering)
                // Note: We'll create the actual labels during positioning, not here
                
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
        
        container.addSubview(textView)
        container.addSubview(dropCapContainer) // Add drop cap on top
        
        // Don't add verse number labels yet - they'll be added during positioning
        
        NSLayoutConstraint.activate([
            // Drop cap container
            dropCapContainer.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            dropCapContainer.topAnchor.constraint(equalTo: container.topAnchor),
            dropCapContainer.widthAnchor.constraint(equalToConstant: 70),
            dropCapContainer.heightAnchor.constraint(equalToConstant: 70),
            
            // Drop cap label centered horizontally, moved down 5 pixels
            dropCapLabel.centerXAnchor.constraint(equalTo: dropCapContainer.centerXAnchor),
            dropCapLabel.centerYAnchor.constraint(equalTo: dropCapContainer.centerYAnchor, constant: 5),
            
            // Text view fills the container (with slight vertical offset)
            textView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            textView.topAnchor.constraint(equalTo: container.topAnchor, constant: 3),
            textView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            textView.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        
        // Store references for positioning after layout
        textView.tag = 999 // Tag to identify this text view
        
        // Store verse data for positioning after layout
        if !verses.isEmpty {
            // Force initial layout
            textView.setNeedsLayout()
            textView.layoutIfNeeded()
            container.setNeedsLayout()
            container.layoutIfNeeded()
            
            // Use layout manager's completion to know when text is ready
            DispatchQueue.main.async { [weak self] in
                // Ensure layout manager has finished
                textView.layoutManager.ensureLayout(for: textView.textContainer)
                
                // Now position the verse numbers
                self?.positionVerseNumbers(in: textView, container: container, verses: verses)
                
                // Apply current visibility state with animation
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
    
    
    // MARK: - Actions
    
    @objc private func bookTitleTapped() {
        let bookVC = BookSelectionViewController()
        bookVC.delegate = self
        bookVC.modalPresentationStyle = .pageSheet
        if let sheet = bookVC.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
        }
        present(bookVC, animated: true)
    }
    
    @objc private func previousChapter() {
        guard let book = currentBook else { return }
        
        if currentChapter > 1 {
            currentChapter -= 1
            loadChapter()
        } else {
            // Go to previous book's last chapter
            if let currentIndex = ScriptureManager.shared.books.firstIndex(where: { $0.name == book.name }),
               currentIndex > 0 {
                let previousBook = ScriptureManager.shared.books[currentIndex - 1]
                currentBook = previousBook
                currentChapter = previousBook.chapters.count
                loadChapter()
            }
        }
    }
    
    @objc private func nextChapter() {
        guard let book = currentBook else { return }
        
        if currentChapter < book.chapters.count {
            currentChapter += 1
            loadChapter()
        } else {
            // Go to next book's first chapter
            if let currentIndex = ScriptureManager.shared.books.firstIndex(where: { $0.name == book.name }),
               currentIndex < ScriptureManager.shared.books.count - 1 {
                let nextBook = ScriptureManager.shared.books[currentIndex + 1]
                currentBook = nextBook
                currentChapter = 1
                loadChapter()
            }
        }
    }
    
    @objc private func handleSwipeLeft() {
        nextChapter()
    }
    
    @objc private func handleSwipeRight() {
        previousChapter()
    }
    
    private func positionVerseNumbers(in textView: UITextView, container: UIView, verses: [Verse]) {
        let layoutManager = textView.layoutManager
        let textContainer = textView.textContainer
        
        // Ensure layout is complete
        layoutManager.ensureLayout(for: textContainer)
        
        // Clear any existing verse labels
        verseNumberLabels.forEach { $0.removeFromSuperview() }
        verseNumberLabels.removeAll()
        
        // Calculate position for each verse
        var currentLocation = 0
        
        for (index, verse) in verses.enumerated() {
            // Skip verse 1
            if verse.number == 1 {
                currentLocation += index == 0 ? verse.text.count - 1 + 2 : verse.text.count + 2 // Account for dropped first char and double space
                continue
            }
            
            // Create verse number label
            let verseLabel = UILabel()
            verseLabel.text = "\(verse.number)"
            verseLabel.font = UIFont(name: "Cardo-Bold", size: 11) ?? .systemFont(ofSize: 11, weight: .bold)
            verseLabel.textColor = UIColor(red: 0.05, green: 0.03, blue: 0.01, alpha: 1.0) // Same as main text
            verseLabel.backgroundColor = .clear
            verseLabel.alpha = 0 // Start hidden for animation
            verseLabel.tag = verse.number
            verseNumberLabels.append(verseLabel)
            
            // Get the character range for this verse start
            // Find the first non-whitespace character to handle line breaks properly
            var searchLocation = currentLocation
            let textString = textView.text as NSString
            
            // Skip any leading whitespace to find the actual first character
            while searchLocation < textString.length {
                let char = textString.character(at: searchLocation)
                if char != 32 && char != 10 && char != 13 { // Not space, newline, or carriage return
                    break
                }
                searchLocation += 1
            }
            
            let glyphRange = layoutManager.glyphRange(forCharacterRange: NSRange(location: searchLocation, length: 1), actualCharacterRange: nil)
            let rect = layoutManager.boundingRect(forGlyphRange: glyphRange, in: textContainer)
            
            // Position the label with better visibility
            verseLabel.sizeToFit()
            
            // Position just above and to the left of the first character of the verse
            // The rect is relative to the text view's text container, we need to add textView's position
            let xPosition: CGFloat = rect.origin.x + textView.frame.origin.x - verseLabel.bounds.width - 2 // Move 2px more left
            let yPosition = rect.origin.y + textView.frame.origin.y - verseLabel.bounds.height + 14 // Move 10px down
            
            verseLabel.frame = CGRect(
                x: xPosition,
                y: yPosition,
                width: verseLabel.bounds.width,
                height: verseLabel.bounds.height
            )
            
            // Add to container now that it's positioned
            container.addSubview(verseLabel)
            verseLabel.layer.zPosition = 100 // Ensure they're on top
            
            // Update location for next verse (2 spaces between verses now)
            currentLocation += verse.text.count + 2 // Add 2 for double space
        }
    }
    
    @objc private func handleChapterSelection(_ notification: Notification) {
        guard let book = notification.userInfo?["book"] as? Book,
              let chapter = notification.userInfo?["chapter"] as? Int else { return }
        
        currentBook = book
        currentChapter = chapter
        loadChapter()
    }
    
    @objc private func handleSettingsChanged() {
        // Reload the chapter to update verse numbers visibility
        loadChapter()
    }
    
    // MARK: - Helpers
    
    private func loadLastReadingPosition() {
        // Scripture data is already loaded in memory
        if let position = UserDataManager.shared.readingPosition {
            currentBook = ScriptureManager.shared.book(named: position.bookName)
            currentChapter = position.chapter
            loadChapter()
        } else {
            // Default to Genesis 1 or first available book
            if let firstBook = ScriptureManager.shared.books.first {
                currentBook = firstBook
                currentChapter = 1
                loadChapter()
            }
        }
    }
}

// MARK: - UIScrollViewDelegate

extension ReadingViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let yOffset = scrollView.contentOffset.y
        
        // Only handle vertical scrolling, ignore horizontal swipes
        if abs(scrollView.contentOffset.x) > 0 {
            scrollView.contentOffset.x = 0
            return
        }
        
        // Skip if we're animating settings
        if isAnimatingSettings {
            return
        }
        
        // Update floating indicator visibility
        // Show when header is scrolled out of view (simplified without settings height offset)
        let headerBottom = chapterHeaderView.frame.height + 20
        let shouldShowIndicator = yOffset > headerBottom && !settingsIsVisible
        
        if shouldShowIndicator != floatingIndicatorVisible {
            floatingIndicatorVisible = shouldShowIndicator
            UIView.animate(withDuration: 0.2) {
                self.floatingIndicatorView.alpha = shouldShowIndicator ? 1.0 : 0.0
            }
        }
        
        // Save scroll position (no offset needed - direct position)
        if yOffset >= 0 {
            if let book = currentBook {
                UserDataManager.shared.saveReadingPosition(
                    book: book.name,
                    chapter: currentChapter,
                    scrollPosition: yOffset
                )
            }
        }
    }
    
    // Simplified scroll delegate methods - no settings snapping needed
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        // Only handle chapter navigation gestures here if needed
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        // No settings snapping needed anymore
    }
}

// MARK: - BookSelectionDelegate

extension ReadingViewController: BookSelectionDelegate {
    func didSelectBook(_ book: Book) {
        currentBook = book
        currentChapter = 1
        loadChapter()
    }
}

// MARK: - UIGestureRecognizerDelegate

extension ReadingViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // Allow settings pan gesture to work alongside scroll view's pan when at top
        if gestureRecognizer == settingsPanGestureRecognizer && otherGestureRecognizer == scrollView.panGestureRecognizer {
            // Only allow simultaneous recognition when at the top of content
            return scrollView.contentOffset.y <= 0
        }
        
        // Don't allow swipe gestures when settings are visible
        if gestureRecognizer is UISwipeGestureRecognizer {
            return !settingsIsVisible && !isDraggingSettings
        }
        
        return false
    }
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        // Only allow swipe gestures when settings are not visible
        if gestureRecognizer is UISwipeGestureRecognizer {
            return !settingsIsVisible && !isDraggingSettings
        }
        
        // Settings pan gesture logic
        if gestureRecognizer == settingsPanGestureRecognizer {
            if let panGesture = gestureRecognizer as? UIPanGestureRecognizer {
                let velocity = panGesture.velocity(in: view)
                let location = panGesture.location(in: view)
                
                // Check if gesture is primarily vertical
                let isVerticalGesture = abs(velocity.y) > abs(velocity.x) * 0.5  // More lenient
                
                if settingsIsVisible {
                    // When settings are visible, allow push up from anywhere on settings
                    let touchingSettings = settingsOverlayView.frame.contains(location)
                    return touchingSettings && isVerticalGesture && velocity.y < 0
                } else {
                    // When settings hidden, only allow pull down from top of scroll
                    let atScrollTop = scrollView.contentOffset.y <= 0
                    return atScrollTop && isVerticalGesture && velocity.y > 0
                }
            }
        }
        
        return true
    }
}