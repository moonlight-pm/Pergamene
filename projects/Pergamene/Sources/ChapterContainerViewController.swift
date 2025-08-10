import UIKit

// MARK: - ChapterContainerViewController
// Manages horizontal scrolling between chapters with three panels (previous, current, next)

class ChapterContainerViewController: UIViewController {
    
    // MARK: - Properties
    
    // Horizontal scroll view for chapter navigation
    private let horizontalScrollView = UIScrollView()
    
    // Three chapter view controllers (reused for memory efficiency)
    private var previousChapterVC: ChapterViewController?
    private var currentChapterVC: ChapterViewController?
    private var nextChapterVC: ChapterViewController?
    
    // Vertical seam views between chapters
    private let leftSeamView = UIView()
    private let rightSeamView = UIView()
    
    // Current book and navigation state
    private var currentBook: Book?
    private var currentChapterNumber: Int = 1
    
    // Elastic parameters for horizontal scrolling
    private let horizontalElasticDamping: CGFloat = 0.6
    private let maxHorizontalElasticDistance: CGFloat = 100.0
    private var isTransitioningChapters = false
    
    // Panel indices
    private enum PanelIndex: Int {
        case previous = 0
        case current = 1
        case next = 2
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        
        setupHorizontalScrollView()
        setupChapterViewControllers()
        setupSeamViews()
        setupNotifications()
        
        // Load initial content
        loadLastReadingPosition()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateChapterFrames()
    }
    
    // MARK: - Setup Methods
    
    private func setupHorizontalScrollView() {
        horizontalScrollView.translatesAutoresizingMaskIntoConstraints = false
        horizontalScrollView.isPagingEnabled = true
        horizontalScrollView.showsHorizontalScrollIndicator = false
        horizontalScrollView.delegate = self
        horizontalScrollView.bounces = true
        horizontalScrollView.alwaysBounceHorizontal = true
        horizontalScrollView.contentInsetAdjustmentBehavior = .never
        
        view.addSubview(horizontalScrollView)
        
        NSLayoutConstraint.activate([
            horizontalScrollView.topAnchor.constraint(equalTo: view.topAnchor),
            horizontalScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            horizontalScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            horizontalScrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setupChapterViewControllers() {
        // Create three reusable chapter view controllers
        previousChapterVC = ChapterViewController()
        currentChapterVC = ChapterViewController()
        nextChapterVC = ChapterViewController()
        
        // Add as child view controllers
        [previousChapterVC, currentChapterVC, nextChapterVC].compactMap { $0 }.forEach { vc in
            addChild(vc)
            horizontalScrollView.addSubview(vc.view)
            vc.didMove(toParent: self)
        }
    }
    
    private func setupSeamViews() {
        // Setup vertical seams between chapters
        leftSeamView.translatesAutoresizingMaskIntoConstraints = false
        leftSeamView.backgroundColor = UIColor(red: 0.6, green: 0.5, blue: 0.4, alpha: 0.3) // Semi-transparent parchment tone
        leftSeamView.layer.shadowColor = UIColor.black.cgColor
        leftSeamView.layer.shadowOffset = CGSize(width: 0, height: 0)
        leftSeamView.layer.shadowOpacity = 0.2
        leftSeamView.layer.shadowRadius = 3
        
        rightSeamView.translatesAutoresizingMaskIntoConstraints = false
        rightSeamView.backgroundColor = UIColor(red: 0.6, green: 0.5, blue: 0.4, alpha: 0.3)
        rightSeamView.layer.shadowColor = UIColor.black.cgColor
        rightSeamView.layer.shadowOffset = CGSize(width: 0, height: 0)
        rightSeamView.layer.shadowOpacity = 0.2
        rightSeamView.layer.shadowRadius = 3
        
        horizontalScrollView.addSubview(leftSeamView)
        horizontalScrollView.addSubview(rightSeamView)
        
        // Ensure seams are above chapter content
        leftSeamView.layer.zPosition = 10
        rightSeamView.layer.zPosition = 10
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleChapterSelection(_:)),
            name: .chapterSelected,
            object: nil
        )
    }
    
    // MARK: - Layout
    
    private func updateChapterFrames() {
        let width = view.bounds.width
        let height = view.bounds.height
        
        // Set content size for 3 panels
        horizontalScrollView.contentSize = CGSize(width: width * 3, height: height)
        
        // Position chapter views
        previousChapterVC?.view.frame = CGRect(x: 0, y: 0, width: width, height: height)
        currentChapterVC?.view.frame = CGRect(x: width, y: 0, width: width, height: height)
        nextChapterVC?.view.frame = CGRect(x: width * 2, y: 0, width: width, height: height)
        
        // Position seam views (3pt wide)
        let seamWidth: CGFloat = 3
        leftSeamView.frame = CGRect(x: width - seamWidth/2, y: 0, width: seamWidth, height: height)
        rightSeamView.frame = CGRect(x: width * 2 - seamWidth/2, y: 0, width: seamWidth, height: height)
        
        // Scroll to current chapter (middle panel)
        if !isTransitioningChapters {
            horizontalScrollView.setContentOffset(CGPoint(x: width, y: 0), animated: false)
        }
    }
    
    // MARK: - Chapter Loading
    
    private func loadChapters() {
        guard let book = currentBook else { return }
        
        // Load current chapter
        currentChapterVC?.loadChapter(book: book, chapter: currentChapterNumber)
        
        // Load previous chapter (or previous book's last chapter)
        if currentChapterNumber > 1 {
            previousChapterVC?.loadChapter(book: book, chapter: currentChapterNumber - 1)
            leftSeamView.isHidden = false
        } else {
            // Try to load previous book's last chapter
            if let previousBook = getPreviousBook() {
                previousChapterVC?.loadChapter(book: previousBook, chapter: previousBook.chapters.count)
                leftSeamView.isHidden = false
            } else {
                // At the very beginning
                previousChapterVC?.view.backgroundColor = UIColor.parchmentTexture
                leftSeamView.isHidden = true
            }
        }
        
        // Load next chapter (or next book's first chapter)
        if currentChapterNumber < book.chapters.count {
            nextChapterVC?.loadChapter(book: book, chapter: currentChapterNumber + 1)
            rightSeamView.isHidden = false
        } else {
            // Try to load next book's first chapter
            if let nextBook = getNextBook() {
                nextChapterVC?.loadChapter(book: nextBook, chapter: 1)
                rightSeamView.isHidden = false
            } else {
                // At the very end
                nextChapterVC?.view.backgroundColor = UIColor.parchmentTexture
                rightSeamView.isHidden = true
            }
        }
    }
    
    private func getPreviousBook() -> Book? {
        guard let book = currentBook,
              let currentIndex = ScriptureManager.shared.books.firstIndex(where: { $0.name == book.name }),
              currentIndex > 0 else { return nil }
        return ScriptureManager.shared.books[currentIndex - 1]
    }
    
    private func getNextBook() -> Book? {
        guard let book = currentBook,
              let currentIndex = ScriptureManager.shared.books.firstIndex(where: { $0.name == book.name }),
              currentIndex < ScriptureManager.shared.books.count - 1 else { return nil }
        return ScriptureManager.shared.books[currentIndex + 1]
    }
    
    // MARK: - Navigation
    
    private func navigateToPreviousChapter() {
        guard let book = currentBook else { return }
        
        if currentChapterNumber > 1 {
            currentChapterNumber -= 1
        } else if let previousBook = getPreviousBook() {
            currentBook = previousBook
            currentChapterNumber = previousBook.chapters.count
        } else {
            // Already at the beginning - show elastic bounce
            return
        }
        
        // Rotate view controllers: next -> current -> previous
        let temp = nextChapterVC
        nextChapterVC = currentChapterVC
        currentChapterVC = previousChapterVC
        previousChapterVC = temp
        
        // Reload chapters with new positions
        loadChapters()
        updateChapterFrames()
        
        // Save reading position
        UserDataManager.shared.saveReadingPosition(
            book: currentBook!.name,
            chapter: currentChapterNumber,
            scrollPosition: 0
        )
    }
    
    private func navigateToNextChapter() {
        guard let book = currentBook else { return }
        
        if currentChapterNumber < book.chapters.count {
            currentChapterNumber += 1
        } else if let nextBook = getNextBook() {
            currentBook = nextBook
            currentChapterNumber = 1
        } else {
            // Already at the end - show elastic bounce
            return
        }
        
        // Rotate view controllers: previous -> current -> next
        let temp = previousChapterVC
        previousChapterVC = currentChapterVC
        currentChapterVC = nextChapterVC
        nextChapterVC = temp
        
        // Reload chapters with new positions
        loadChapters()
        updateChapterFrames()
        
        // Save reading position
        UserDataManager.shared.saveReadingPosition(
            book: currentBook!.name,
            chapter: currentChapterNumber,
            scrollPosition: 0
        )
    }
    
    // MARK: - Initial Loading
    
    private func loadLastReadingPosition() {
        if let position = UserDataManager.shared.readingPosition {
            currentBook = ScriptureManager.shared.book(named: position.bookName)
            currentChapterNumber = position.chapter
        } else {
            // Default to Genesis 1
            currentBook = ScriptureManager.shared.books.first
            currentChapterNumber = 1
        }
        
        loadChapters()
    }
    
    // MARK: - Notifications
    
    @objc private func handleChapterSelection(_ notification: Notification) {
        guard let book = notification.userInfo?["book"] as? Book,
              let chapter = notification.userInfo?["chapter"] as? Int else { return }
        
        currentBook = book
        currentChapterNumber = chapter
        loadChapters()
        
        // Ensure we're showing the current chapter
        let width = view.bounds.width
        horizontalScrollView.setContentOffset(CGPoint(x: width, y: 0), animated: true)
    }
}

// MARK: - UIScrollViewDelegate

extension ChapterContainerViewController: UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // Apply elastic resistance at boundaries
        let xOffset = scrollView.contentOffset.x
        let width = view.bounds.width
        
        // Check if at first chapter of first book
        let atVeryBeginning = currentBook == ScriptureManager.shared.books.first && currentChapterNumber == 1
        
        // Check if at last chapter of last book
        let atVeryEnd: Bool = {
            guard let book = currentBook else { return false }
            return book == ScriptureManager.shared.books.last && currentChapterNumber == book.chapters.count
        }()
        
        // Apply elastic resistance when trying to scroll before first chapter
        if atVeryBeginning && xOffset < width {
            let overscroll = width - xOffset
            let resistance = elasticResistanceCurve(distance: overscroll, maxDistance: maxHorizontalElasticDistance)
            let elasticOffset = width - (overscroll * resistance)
            scrollView.contentOffset.x = elasticOffset
        }
        
        // Apply elastic resistance when trying to scroll after last chapter
        if atVeryEnd && xOffset > width {
            let overscroll = xOffset - width
            let resistance = elasticResistanceCurve(distance: overscroll, maxDistance: maxHorizontalElasticDistance)
            let elasticOffset = width + (overscroll * resistance)
            scrollView.contentOffset.x = elasticOffset
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let width = view.bounds.width
        let currentPage = Int(scrollView.contentOffset.x / width)
        
        // Handle page change
        switch currentPage {
        case 0:
            // Moved to previous chapter
            navigateToPreviousChapter()
        case 2:
            // Moved to next chapter
            navigateToNextChapter()
        default:
            // Stayed on current chapter
            break
        }
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            // Snap to nearest page if not decelerating
            let width = view.bounds.width
            let currentPage = round(scrollView.contentOffset.x / width)
            scrollView.setContentOffset(CGPoint(x: currentPage * width, y: 0), animated: true)
        }
    }
    
    private func elasticResistanceCurve(distance: CGFloat, maxDistance: CGFloat) -> CGFloat {
        let normalizedDistance = min(distance / maxDistance, 1.0)
        let resistance = horizontalElasticDamping * (1.0 - pow(1.0 - normalizedDistance, 3.0))
        return max(0.1, resistance)
    }
}