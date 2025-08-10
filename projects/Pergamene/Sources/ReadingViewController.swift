import UIKit

class ReadingViewController: UIViewController {
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let chapterHeaderView = UIView()
    private let bookLabel = UILabel()
    private let chapterLabel = UILabel()
    private let versesStackView = UIStackView()
    private let navigationToolbar = UIToolbar()
    
    private var currentBook: Book?
    private var currentChapter: Int = 1
    private var verseLabels: [Int: UILabel] = [:]
    private var selectedVerses: Set<Int> = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Pergamene"
        view.backgroundColor = UIColor(red: 0.98, green: 0.97, blue: 0.94, alpha: 1.0)
        
        setupViews()
        setupNavigationBar()
        setupNotifications()
        loadLastReadingPosition()
    }
    
    private func setupViews() {
        setupScrollView()
        setupChapterHeader()
        setupVersesStackView()
        setupNavigationToolbar()
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
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -44),
            
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
        bookLabel.font = .systemFont(ofSize: 24, weight: .semibold)
        bookLabel.textColor = UIColor(red: 0.4, green: 0.3, blue: 0.2, alpha: 1.0)
        bookLabel.textAlignment = .center
        
        chapterLabel.translatesAutoresizingMaskIntoConstraints = false
        chapterLabel.font = .systemFont(ofSize: 18, weight: .regular)
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
    
    private func setupNavigationToolbar() {
        navigationToolbar.translatesAutoresizingMaskIntoConstraints = false
        navigationToolbar.barTintColor = UIColor(red: 0.95, green: 0.93, blue: 0.88, alpha: 1.0)
        
        let previousButton = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(previousChapter)
        )
        
        let nextButton = UIBarButtonItem(
            image: UIImage(systemName: "chevron.right"),
            style: .plain,
            target: self,
            action: #selector(nextChapter)
        )
        
        let bookmarkButton = UIBarButtonItem(
            image: UIImage(systemName: "bookmark"),
            style: .plain,
            target: self,
            action: #selector(toggleBookmark)
        )
        
        let shareButton = UIBarButtonItem(
            image: UIImage(systemName: "square.and.arrow.up"),
            style: .plain,
            target: self,
            action: #selector(shareVerse)
        )
        
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        
        navigationToolbar.items = [previousButton, flexSpace, bookmarkButton, flexSpace, shareButton, flexSpace, nextButton]
        
        view.addSubview(navigationToolbar)
        
        NSLayoutConstraint.activate([
            navigationToolbar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            navigationToolbar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            navigationToolbar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            navigationToolbar.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    private func setupNavigationBar() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "Books",
            style: .plain,
            target: self,
            action: #selector(showBookSelector)
        )
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "textformat"),
            style: .plain,
            target: self,
            action: #selector(showTextSettings)
        )
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
        
        bookLabel.text = book.name
        chapterLabel.text = "Chapter \(currentChapter)"
        
        // Clear existing verses
        versesStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        verseLabels.removeAll()
        selectedVerses.removeAll()
        
        // Add verses
        for verse in chapter.verses {
            let verseView = createVerseView(verse: verse)
            versesStackView.addArrangedSubview(verseView)
        }
        
        // Scroll to top
        scrollView.setContentOffset(.zero, animated: false)
        
        // Save reading position
        UserDataManager.shared.saveReadingPosition(
            book: book.name,
            chapter: currentChapter,
            scrollPosition: 0
        )
        
        // Update bookmark button
        updateBookmarkButton()
    }
    
    private func createVerseView(verse: Verse) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(verseTapped(_:)))
        container.addGestureRecognizer(tapGesture)
        container.tag = verse.number
        
        let numberLabel = UILabel()
        numberLabel.translatesAutoresizingMaskIntoConstraints = false
        numberLabel.text = "\(verse.number)"
        numberLabel.font = .systemFont(ofSize: 12, weight: .bold)
        numberLabel.textColor = UIColor(red: 0.6, green: 0.4, blue: 0.2, alpha: 0.8)
        numberLabel.setContentHuggingPriority(.required, for: .horizontal)
        
        let textLabel = UILabel()
        textLabel.translatesAutoresizingMaskIntoConstraints = false
        textLabel.text = verse.text
        textLabel.font = .systemFont(ofSize: 18)
        textLabel.textColor = UIColor(red: 0.2, green: 0.15, blue: 0.1, alpha: 1.0)
        textLabel.numberOfLines = 0
        textLabel.lineBreakMode = .byWordWrapping
        
        container.addSubview(numberLabel)
        container.addSubview(textLabel)
        
        NSLayoutConstraint.activate([
            numberLabel.topAnchor.constraint(equalTo: container.topAnchor),
            numberLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            numberLabel.widthAnchor.constraint(equalToConstant: 30),
            
            textLabel.topAnchor.constraint(equalTo: container.topAnchor),
            textLabel.leadingAnchor.constraint(equalTo: numberLabel.trailingAnchor, constant: 8),
            textLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            textLabel.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        
        verseLabels[verse.number] = textLabel
        
        // Check for highlights
        let highlights = UserDataManager.shared.highlightsForChapter(
            book: currentBook?.name ?? "",
            chapter: currentChapter
        )
        if highlights.contains(where: { $0.verseStart <= verse.number && $0.verseEnd >= verse.number }) {
            textLabel.backgroundColor = UIColor(red: 1.0, green: 0.95, blue: 0.5, alpha: 0.3)
        }
        
        return container
    }
    
    // MARK: - Actions
    
    @objc private func showBookSelector() {
        let bookVC = BookSelectionViewController()
        bookVC.delegate = self
        let navVC = UINavigationController(rootViewController: bookVC)
        present(navVC, animated: true)
    }
    
    @objc private func showTextSettings() {
        // TODO: Implement text settings
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
    
    @objc private func toggleBookmark() {
        guard let book = currentBook else { return }
        
        let bookmarks = UserDataManager.shared.bookmarks
        if let existingBookmark = bookmarks.first(where: { $0.bookName == book.name && $0.chapter == currentChapter }) {
            UserDataManager.shared.removeBookmark(existingBookmark)
        } else {
            let bookmark = Bookmark(bookName: book.name, chapter: currentChapter)
            UserDataManager.shared.addBookmark(bookmark)
        }
        
        updateBookmarkButton()
    }
    
    @objc private func shareVerse() {
        guard !selectedVerses.isEmpty,
              let book = currentBook else { return }
        
        var shareText = ""
        let sortedVerses = selectedVerses.sorted()
        
        for verseNum in sortedVerses {
            if let verseLabel = verseLabels[verseNum] {
                shareText += "\(verseNum). \(verseLabel.text ?? "")\n"
            }
        }
        
        shareText += "\n— \(book.name) \(currentChapter):\(sortedVerses.first!)"
        if sortedVerses.count > 1 {
            shareText += "-\(sortedVerses.last!)"
        }
        
        let activityVC = UIActivityViewController(activityItems: [shareText], applicationActivities: nil)
        present(activityVC, animated: true)
    }
    
    @objc private func verseTapped(_ gesture: UITapGestureRecognizer) {
        guard let verseView = gesture.view,
              let verseLabel = verseLabels[verseView.tag] else { return }
        
        let verseNumber = verseView.tag
        
        if selectedVerses.contains(verseNumber) {
            selectedVerses.remove(verseNumber)
            verseLabel.backgroundColor = .clear
        } else {
            selectedVerses.insert(verseNumber)
            verseLabel.backgroundColor = UIColor(red: 0.8, green: 0.9, blue: 1.0, alpha: 0.3)
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
    
    private func updateBookmarkButton() {
        guard let book = currentBook else { return }
        
        let hasBookmark = UserDataManager.shared.bookmarks.contains { 
            $0.bookName == book.name && $0.chapter == currentChapter 
        }
        
        if let bookmarkButton = navigationToolbar.items?[2] {
            bookmarkButton.image = UIImage(systemName: hasBookmark ? "bookmark.fill" : "bookmark")
        }
    }
    
    private func loadLastReadingPosition() {
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