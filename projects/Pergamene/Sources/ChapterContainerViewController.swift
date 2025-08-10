import UIKit

// MARK: - ChapterContainerViewController
// Uses UIPageViewController to manage horizontal scrolling between chapters

class ChapterContainerViewController: UIViewController {
    
    // MARK: - Properties
    
    private var pageViewController: UIPageViewController!
    
    // Current book and navigation state
    private var currentBook: Book?
    private var currentChapterNumber: Int = 1
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        
        setupPageViewController()
        setupNotifications()
        
        // Load initial content
        loadLastReadingPosition()
    }
    
    // MARK: - Setup Methods
    
    private func setupPageViewController() {
        // Create page view controller with horizontal scrolling
        pageViewController = UIPageViewController(
            transitionStyle: .scroll,
            navigationOrientation: .horizontal,
            options: [.interPageSpacing: 3] // Small gap between pages
        )
        
        pageViewController.delegate = self
        pageViewController.dataSource = self
        
        // Add as child view controller
        addChild(pageViewController)
        view.addSubview(pageViewController.view)
        pageViewController.view.frame = view.bounds
        pageViewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        pageViewController.didMove(toParent: self)
        
        // Customize page control appearance (hidden since we don't want dots)
        let pageControl = UIPageControl.appearance(whenContainedInInstancesOf: [ChapterContainerViewController.self])
        pageControl.isHidden = true
        
        // Ensure gesture recognition works properly
        DispatchQueue.main.async { [weak self] in
            // Access the scroll view after layout
            for subview in self?.pageViewController.view.subviews ?? [] {
                if let scrollView = subview as? UIScrollView {
                    scrollView.isScrollEnabled = true
                    scrollView.bounces = true
                    scrollView.delaysContentTouches = false
                    print("Found UIPageViewController's scroll view - enabled: \(scrollView.isScrollEnabled)")
                    
                    // Log gesture recognizers
                    for gesture in scrollView.gestureRecognizers ?? [] {
                        print("Gesture recognizer: \(type(of: gesture))")
                    }
                }
            }
        }
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleChapterSelection(_:)),
            name: .chapterSelected,
            object: nil
        )
    }
    
    // MARK: - Chapter Loading
    
    private func loadLastReadingPosition() {
        if let position = UserDataManager.shared.readingPosition {
            currentBook = ScriptureManager.shared.book(named: position.bookName)
            currentChapterNumber = position.chapter
        } else {
            // Default to Genesis 1
            currentBook = ScriptureManager.shared.books.first
            currentChapterNumber = 1
        }
        
        // Set initial chapter
        if let book = currentBook {
            let chapterVC = createChapterViewController(book: book, chapter: currentChapterNumber)
            pageViewController.setViewControllers(
                [chapterVC],
                direction: .forward,
                animated: false,
                completion: nil
            )
        }
    }
    
    private func createChapterViewController(book: Book, chapter: Int) -> ChapterViewController {
        let chapterVC = ChapterViewController()
        chapterVC.loadChapter(book: book, chapter: chapter)
        return chapterVC
    }
    
    // MARK: - Navigation Helpers
    
    private func getNextChapter(from viewController: ChapterViewController) -> (book: Book, chapter: Int)? {
        guard let book = viewController.getCurrentBook() else { return nil }
        let chapter = viewController.getCurrentChapter()
        
        if chapter < book.chapters.count {
            // Next chapter in same book
            return (book, chapter + 1)
        } else {
            // First chapter of next book
            guard let nextBook = getNextBook(after: book) else { return nil }
            return (nextBook, 1)
        }
    }
    
    private func getPreviousChapter(from viewController: ChapterViewController) -> (book: Book, chapter: Int)? {
        guard let book = viewController.getCurrentBook() else { return nil }
        let chapter = viewController.getCurrentChapter()
        
        if chapter > 1 {
            // Previous chapter in same book
            return (book, chapter - 1)
        } else {
            // Last chapter of previous book
            guard let previousBook = getPreviousBook(before: book) else { return nil }
            return (previousBook, previousBook.chapters.count)
        }
    }
    
    private func getNextBook(after book: Book) -> Book? {
        guard let currentIndex = ScriptureManager.shared.books.firstIndex(where: { $0.name == book.name }),
              currentIndex < ScriptureManager.shared.books.count - 1 else { return nil }
        return ScriptureManager.shared.books[currentIndex + 1]
    }
    
    private func getPreviousBook(before book: Book) -> Book? {
        guard let currentIndex = ScriptureManager.shared.books.firstIndex(where: { $0.name == book.name }),
              currentIndex > 0 else { return nil }
        return ScriptureManager.shared.books[currentIndex - 1]
    }
    
    // MARK: - Notifications
    
    @objc private func handleChapterSelection(_ notification: Notification) {
        guard let book = notification.userInfo?["book"] as? Book,
              let chapter = notification.userInfo?["chapter"] as? Int else { return }
        
        currentBook = book
        currentChapterNumber = chapter
        
        let chapterVC = createChapterViewController(book: book, chapter: chapter)
        
        // Determine direction based on whether we're going forward or backward
        var direction: UIPageViewController.NavigationDirection = .forward
        if let currentVC = pageViewController.viewControllers?.first as? ChapterViewController,
           let currentBook = currentVC.getCurrentBook() {
            if book.orderIndex < currentBook.orderIndex ||
               (book.orderIndex == currentBook.orderIndex && chapter < currentVC.getCurrentChapter()) {
                direction = .reverse
            }
        }
        
        pageViewController.setViewControllers(
            [chapterVC],
            direction: direction,
            animated: true,
            completion: nil
        )
    }
}

// MARK: - UIPageViewControllerDataSource

extension ChapterContainerViewController: UIPageViewControllerDataSource {
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let chapterVC = viewController as? ChapterViewController,
              let previousChapter = getPreviousChapter(from: chapterVC) else { return nil }
        
        return createChapterViewController(book: previousChapter.book, chapter: previousChapter.chapter)
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let chapterVC = viewController as? ChapterViewController,
              let nextChapter = getNextChapter(from: chapterVC) else { return nil }
        
        return createChapterViewController(book: nextChapter.book, chapter: nextChapter.chapter)
    }
}

// MARK: - UIPageViewControllerDelegate

extension ChapterContainerViewController: UIPageViewControllerDelegate {
    
    func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController]) {
        print("Starting page transition")
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        print("Page transition finished - completed: \(completed)")
        
        guard completed,
              let currentVC = pageViewController.viewControllers?.first as? ChapterViewController,
              let book = currentVC.getCurrentBook() else { return }
        
        currentBook = book
        currentChapterNumber = currentVC.getCurrentChapter()
        
        // Save reading position
        UserDataManager.shared.saveReadingPosition(
            book: book.name,
            chapter: currentChapterNumber,
            scrollPosition: 0
        )
    }
}