import UIKit

class ReadingViewController: UIViewController {
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let topFadeView = UIView()
    private let topFadeGradient = CAGradientLayer()
    private let chapterHeaderView = UIView()
    private let bookLabel = UILabel()
    private let chapterLabel = UILabel()
    private let versesStackView = UIStackView()
    
    private var currentBook: Book?
    private var currentChapter: Int = 1
    private var chapterTextCache: [String: String] = [:]
    private var chapterHeaderTopConstraint: NSLayoutConstraint?
    private var verseNumberLabels: [UILabel] = []
    private var verseNumbersVisible = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .black // Black for overscroll areas
        scrollView.contentInsetAdjustmentBehavior = .never // Disable automatic inset adjustment
        
        setupViews()
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
    }
    
    private func setupScrollView() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.backgroundColor = .clear
        scrollView.delegate = self
        
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.backgroundColor = UIColor.parchmentTexture // Texture on content view
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        // Setup gradient mask for fading text in safe area
        setupGradientMask()
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor), // Extend into safe area
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor), // Extend into safe area
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
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
        
        contentView.addSubview(versesStackView)
        
        NSLayoutConstraint.activate([
            versesStackView.topAnchor.constraint(equalTo: chapterHeaderView.bottomAnchor, constant: 20),
            versesStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            versesStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            versesStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])
    }
    
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleChapterSelection(_:)),
            name: .chapterSelected,
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
        
        // Scroll to top
        scrollView.setContentOffset(.zero, animated: false)
        
        // Save reading position
        UserDataManager.shared.saveReadingPosition(
            book: book.name,
            chapter: currentChapter,
            scrollPosition: 0
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
        paragraphStyle.alignment = .justified
        
        // Build attributed string with verse positions marked
        let attributedString = NSMutableAttributedString()
        
        // Remove first character for drop cap
        let textWithoutFirstChar = String(text.dropFirst())
        
        // If we have verse data, create markers
        if !verses.isEmpty {
            var currentPosition = 0
            
            for (index, verse) in verses.enumerated() {
                let verseText = verse.text
                
                // For verse 1, account for the dropped first character
                let adjustedText = index == 0 ? String(verseText.dropFirst()) : verseText
                
                // Add verse text
                let verseAttrString = NSAttributedString(
                    string: adjustedText + (index < verses.count - 1 ? " " : ""),
                    attributes: [
                        .font: UIFont(name: "Cardo-Regular", size: 20) ?? .systemFont(ofSize: 18),
                        .foregroundColor: UIColor(red: 0.05, green: 0.03, blue: 0.01, alpha: 1.0),
                        .paragraphStyle: paragraphStyle
                    ]
                )
                
                // Store the range for this verse (skip verse 1 for numbering)
                if verse.number > 1 {
                    let range = NSRange(location: attributedString.length, length: 0)
                    
                    // Create verse number label
                    let verseLabel = UILabel()
                    verseLabel.text = "\(verse.number)"
                    verseLabel.font = UIFont(name: "Cardo-Regular", size: 12) ?? .systemFont(ofSize: 12)
                    verseLabel.textColor = UIColor(red: 0.7, green: 0.1, blue: 0.1, alpha: 1.0) // Red color
                    verseLabel.alpha = 0 // Start hidden
                    verseLabel.translatesAutoresizingMaskIntoConstraints = false
                    
                    // We'll position these after the text view is laid out
                    verseLabel.tag = verse.number
                    verseNumberLabels.append(verseLabel)
                }
                
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
        
        // Add verse number labels to container
        verseNumberLabels.forEach { label in
            container.addSubview(label)
        }
        
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
        
        // Position verse numbers after layout
        if !verses.isEmpty {
            DispatchQueue.main.async { [weak self] in
                self?.positionVerseNumbers(in: textView, container: container, verses: verses)
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
    
    
    private func setupGestures() {
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeLeft))
        swipeLeft.direction = .left
        view.addGestureRecognizer(swipeLeft)
        
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeRight))
        swipeRight.direction = .right
        view.addGestureRecognizer(swipeRight)
        
        // Add tap gesture for verse numbers
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        tapGesture.numberOfTapsRequired = 1
        scrollView.addGestureRecognizer(tapGesture)
    }
    
    @objc private func handleSwipeLeft() {
        nextChapter()
    }
    
    @objc private func handleSwipeRight() {
        previousChapter()
    }
    
    @objc private func handleTap() {
        toggleVerseNumbers()
    }
    
    private func toggleVerseNumbers() {
        verseNumbersVisible.toggle()
        
        UIView.animate(withDuration: 0.3) {
            self.verseNumberLabels.forEach { label in
                label.alpha = self.verseNumbersVisible ? 1.0 : 0.0
            }
        }
    }
    
    private func positionVerseNumbers(in textView: UITextView, container: UIView, verses: [Verse]) {
        let layoutManager = textView.layoutManager
        let textContainer = textView.textContainer
        
        // Calculate position for each verse
        var currentLocation = 0
        
        for (index, verse) in verses.enumerated() {
            // Skip verse 1
            if verse.number == 1 {
                currentLocation += index == 0 ? verse.text.count - 1 : verse.text.count + 1 // Account for dropped first char and space
                continue
            }
            
            // Find the verse label
            guard let verseLabel = verseNumberLabels.first(where: { $0.tag == verse.number }) else {
                currentLocation += verse.text.count + 1 // Add 1 for space
                continue
            }
            
            // Get the character range for this verse start
            let glyphRange = layoutManager.glyphRange(forCharacterRange: NSRange(location: currentLocation, length: 1), actualCharacterRange: nil)
            let rect = layoutManager.boundingRect(forGlyphRange: glyphRange, in: textContainer)
            
            // Position the label to the left and slightly above the first character
            verseLabel.sizeToFit()
            let xPosition = rect.origin.x - verseLabel.bounds.width - 5
            let yPosition = rect.origin.y + textView.frame.origin.y - 2
            
            verseLabel.frame = CGRect(
                x: max(-15, xPosition), // Don't go too far left
                y: yPosition,
                width: verseLabel.bounds.width,
                height: verseLabel.bounds.height
            )
            
            // Update location for next verse
            currentLocation += verse.text.count + 1 // Add 1 for space
        }
    }
    
    @objc private func handleChapterSelection(_ notification: Notification) {
        guard let book = notification.userInfo?["book"] as? Book,
              let chapter = notification.userInfo?["chapter"] as? Int else { return }
        
        currentBook = book
        currentChapter = chapter
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
        // Save scroll position periodically
        if let book = currentBook {
            UserDataManager.shared.saveReadingPosition(
                book: book.name,
                chapter: currentChapter,
                scrollPosition: scrollView.contentOffset.y
            )
        }
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