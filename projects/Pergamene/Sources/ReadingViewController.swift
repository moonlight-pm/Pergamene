import UIKit

class ReadingViewController: UIViewController {
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let chapterHeaderView = UIView()
    private let bookLabel = UILabel()
    private let chapterLabel = UILabel()
    private let versesStackView = UIStackView()
    
    private var currentBook: Book?
    private var currentChapter: Int = 1
    private var chapterTextCache: [String: String] = [:]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor(red: 0.98, green: 0.97, blue: 0.94, alpha: 1.0)
        
        // Debug: Print available fonts
        for family in UIFont.familyNames.sorted() {
            if family.lowercased().contains("cardo") {
                print("Font family: \(family)")
                for font in UIFont.fontNames(forFamilyName: family) {
                    print("  - \(font)")
                }
            }
        }
        
        setupViews()
        setupGestures()
        setupNotifications()
        loadLastReadingPosition()
    }
    
    private func setupViews() {
        setupScrollView()
        setupChapterHeader()
        setupVersesStackView()
    }
    
    private func setupScrollView() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.backgroundColor = UIColor(red: 0.98, green: 0.97, blue: 0.94, alpha: 1.0)
        scrollView.delegate = self
        
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
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
        
        // Make the header tappable
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(bookTitleTapped))
        chapterHeaderView.addGestureRecognizer(tapGesture)
        chapterHeaderView.isUserInteractionEnabled = true
        
        bookLabel.translatesAutoresizingMaskIntoConstraints = false
        bookLabel.font = UIFont(name: "Cardo-Bold", size: 26) ?? .systemFont(ofSize: 24, weight: .semibold)
        bookLabel.textColor = UIColor(red: 0.4, green: 0.3, blue: 0.2, alpha: 1.0)
        bookLabel.textAlignment = .center
        bookLabel.isUserInteractionEnabled = true
        
        chapterLabel.translatesAutoresizingMaskIntoConstraints = false
        chapterLabel.font = UIFont(name: "Cardo-Regular", size: 20) ?? .systemFont(ofSize: 18, weight: .regular)
        chapterLabel.textColor = UIColor(red: 0.5, green: 0.4, blue: 0.3, alpha: 1.0)
        chapterLabel.textAlignment = .center
        
        contentView.addSubview(chapterHeaderView)
        chapterHeaderView.addSubview(bookLabel)
        chapterHeaderView.addSubview(chapterLabel)
        
        NSLayoutConstraint.activate([
            chapterHeaderView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
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
        
        // Clear existing content
        versesStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
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
        
        // Create single paragraph view with drop cap
        let paragraphView = createChapterParagraphView(text: fullText)
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
    
    private func createChapterParagraphView(text: String) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        
        // Get the first character (but don't remove it from the text yet)
        let firstChar = String(text.prefix(1)).uppercased()
        
        // Create simple boxed drop cap placeholder
        let dropCapContainer = UIView()
        dropCapContainer.translatesAutoresizingMaskIntoConstraints = false
        dropCapContainer.backgroundColor = UIColor(red: 0.98, green: 0.97, blue: 0.94, alpha: 1.0)
        dropCapContainer.layer.borderColor = UIColor(red: 0.5, green: 0.35, blue: 0.2, alpha: 1.0).cgColor
        dropCapContainer.layer.borderWidth = 2
        
        let dropCapLabel = UILabel()
        dropCapLabel.translatesAutoresizingMaskIntoConstraints = false
        dropCapLabel.text = firstChar
        dropCapLabel.font = UIFont(name: "Cardo-Bold", size: 56) ?? .systemFont(ofSize: 56, weight: .bold)
        dropCapLabel.textColor = UIColor(red: 0.4, green: 0.3, blue: 0.2, alpha: 1.0)
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
        
        // Create attributed string with line spacing
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 10
        paragraphStyle.alignment = .justified
        
        // Don't add extra spaces - the exclusion path handles the wrapping
        let spacedText = String(text.dropFirst())
        
        let attributedString = NSAttributedString(
            string: spacedText,
            attributes: [
                .font: UIFont(name: "Cardo-Regular", size: 20) ?? .systemFont(ofSize: 18),
                .foregroundColor: UIColor(red: 0.2, green: 0.15, blue: 0.1, alpha: 1.0),
                .paragraphStyle: paragraphStyle
            ]
        )
        textView.attributedText = attributedString
        
        // Create exclusion path for text to wrap around drop cap
        let exclusionPath = UIBezierPath(rect: CGRect(x: 0, y: 0, width: 80, height: 70))
        textView.textContainer.exclusionPaths = [exclusionPath]
        
        container.addSubview(textView)
        container.addSubview(dropCapContainer) // Add drop cap on top
        
        NSLayoutConstraint.activate([
            // Drop cap container
            dropCapContainer.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            dropCapContainer.topAnchor.constraint(equalTo: container.topAnchor),
            dropCapContainer.widthAnchor.constraint(equalToConstant: 70),
            dropCapContainer.heightAnchor.constraint(equalToConstant: 70),
            
            // Drop cap label centered in container
            dropCapLabel.centerXAnchor.constraint(equalTo: dropCapContainer.centerXAnchor),
            dropCapLabel.centerYAnchor.constraint(equalTo: dropCapContainer.centerYAnchor),
            
            // Text view fills the container (with slight vertical offset)
            textView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            textView.topAnchor.constraint(equalTo: container.topAnchor, constant: 3),
            textView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            textView.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        
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
    }
    
    @objc private func handleSwipeLeft() {
        nextChapter()
    }
    
    @objc private func handleSwipeRight() {
        previousChapter()
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