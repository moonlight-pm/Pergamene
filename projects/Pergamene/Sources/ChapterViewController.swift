import UIKit

// MARK: - ChapterViewController
// Displays a single chapter with vertical scrolling, settings overlay, etc.
// This is extracted from ReadingViewController to be reusable in the horizontal paging system

class ChapterViewController: UIViewController {
    
    // MARK: - Properties
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let chapterHeaderView = UIView()
    private let bookLabel = UILabel()
    private let chapterLabel = UILabel()
    private let versesStackView = UIStackView()
    
    // Floating chapter indicator
    private let floatingIndicatorView = UIView()
    private let floatingIndicatorLabel = UILabel()
    private var floatingIndicatorVisible = false
    
    // Settings overlay system
    private let settingsOverlayView = UIView()
    private let settingsDimmingView = UIView()
    private var settingsViewController: SettingsViewController?
    private var settingsIsVisible = false
    private let screenHeight: CGFloat = UIScreen.main.bounds.height
    
    // Elastic pull parameters
    private let pullActivationThreshold: CGFloat = 90.0
    private let pushActivationThreshold: CGFloat = 90.0
    private let elasticDamping: CGFloat = 0.6
    private let maxElasticDistance: CGFloat = 120.0
    
    // Animation and state tracking
    private var isAnimatingSettings = false
    private var isDraggingSettings = false
    private var settingsPanGestureRecognizer: UIPanGestureRecognizer?
    private var lastContentOffset: CGFloat = 0
    
    // Chapter data
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
        setupGestures()
        setupNotifications()
    }
    
    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        chapterHeaderTopConstraint?.constant = view.safeAreaInsets.top + 20
    }
    
    // MARK: - Public Methods
    
    func loadChapter(book: Book, chapter: Int) {
        currentBook = book
        currentChapter = chapter
        
        guard let chapterData = book.chapters.first(where: { $0.number == chapter }) else { return }
        
        // Update labels
        bookLabel.text = book.name
        chapterLabel.text = "Chapter \(chapter)"
        floatingIndicatorLabel.text = "\(book.name) • Chapter \(chapter)"
        
        // Clear existing content
        versesStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        verseNumberLabels.forEach { $0.removeFromSuperview() }
        verseNumberLabels.removeAll()
        
        // Get or create cached text
        let cacheKey = "\(book.name)_\(chapter)"
        let fullText: String
        
        if let cachedText = chapterTextCache[cacheKey] {
            fullText = cachedText
        } else {
            fullText = chapterData.verses.map { $0.text }.joined(separator: " ")
            chapterTextCache[cacheKey] = fullText
        }
        
        // Create paragraph view
        let paragraphView = createChapterParagraphView(text: fullText, verses: chapterData.verses)
        versesStackView.addArrangedSubview(paragraphView)
        
        // Restore saved scroll position
        let savedPosition = UserDataManager.shared.getChapterScrollPosition(book: book.name, chapter: chapter)
        if savedPosition > 0 {
            scrollView.setContentOffset(CGPoint(x: 0, y: savedPosition), animated: false)
        } else {
            scrollView.setContentOffset(.zero, animated: false)
        }
        
        // Update reading position
        UserDataManager.shared.saveReadingPosition(
            book: book.name,
            chapter: chapter,
            scrollPosition: savedPosition
        )
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
    }
    
    private func setupScrollView() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.backgroundColor = .clear
        scrollView.delegate = self
        scrollView.showsVerticalScrollIndicator = true
        
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
        
        bookLabel.translatesAutoresizingMaskIntoConstraints = false
        bookLabel.font = UIFont(name: "Cardo-Bold", size: 26) ?? .systemFont(ofSize: 24, weight: .semibold)
        bookLabel.textColor = UIColor(red: 0.15, green: 0.1, blue: 0.05, alpha: 1.0)
        bookLabel.textAlignment = .center
        
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
        
        // Extra bottom padding for comfortable reading
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
        floatingIndicatorView.backgroundColor = UIColor(red: 0.05, green: 0.03, blue: 0.01, alpha: 0.85)
        floatingIndicatorView.alpha = 0
        
        floatingIndicatorLabel.translatesAutoresizingMaskIntoConstraints = false
        floatingIndicatorLabel.font = UIFont(name: "Cardo-Regular", size: 14) ?? .systemFont(ofSize: 14)
        floatingIndicatorLabel.textColor = UIColor(red: 0.95, green: 0.92, blue: 0.88, alpha: 1.0)
        floatingIndicatorLabel.textAlignment = .center
        
        floatingIndicatorView.addSubview(floatingIndicatorLabel)
        view.addSubview(floatingIndicatorView)
        
        NSLayoutConstraint.activate([
            floatingIndicatorView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            floatingIndicatorView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            floatingIndicatorView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            floatingIndicatorView.heightAnchor.constraint(equalToConstant: 28),
            
            floatingIndicatorLabel.centerYAnchor.constraint(equalTo: floatingIndicatorView.centerYAnchor),
            floatingIndicatorLabel.leadingAnchor.constraint(equalTo: floatingIndicatorView.leadingAnchor, constant: 20),
            floatingIndicatorLabel.trailingAnchor.constraint(equalTo: floatingIndicatorView.trailingAnchor, constant: -20)
        ])
        
        floatingIndicatorView.layer.zPosition = 10
    }
    
    private func setupSettingsOverlay() {
        // Similar to ReadingViewController but simplified
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
    
    private func setupGestures() {
        settingsPanGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handleSettingsPanGesture(_:)))
        settingsPanGestureRecognizer?.delegate = self
        view.addGestureRecognizer(settingsPanGestureRecognizer!)
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleSettingsChanged),
            name: .settingsChanged,
            object: nil
        )
    }
    
    // MARK: - Settings Gestures
    
    @objc private func handleSettingsPanGesture(_ gesture: UIPanGestureRecognizer) {
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
    
    // MARK: - Chapter Content Creation
    
    private func createChapterParagraphView(text: String, verses: [Verse] = []) -> UIView {
        // This is a simplified version - the full implementation would be similar to ReadingViewController
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        
        let textView = UITextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.backgroundColor = .clear
        textView.textContainerInset = UIEdgeInsets.zero
        textView.textContainer.lineFragmentPadding = 0
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 10
        paragraphStyle.alignment = .left
        
        let attributedString = NSAttributedString(
            string: text,
            attributes: [
                .font: UIFont(name: "Cardo-Regular", size: 20) ?? .systemFont(ofSize: 18),
                .foregroundColor: UIColor(red: 0.05, green: 0.03, blue: 0.01, alpha: 1.0),
                .paragraphStyle: paragraphStyle
            ]
        )
        
        textView.attributedText = attributedString
        container.addSubview(textView)
        
        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: container.topAnchor),
            textView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            textView.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        
        return container
    }
    
    @objc private func handleSettingsChanged() {
        if let book = currentBook {
            loadChapter(book: book, chapter: currentChapter)
        }
    }
}

// MARK: - UIScrollViewDelegate

extension ChapterViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
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
        
        lastContentOffset = yOffset
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