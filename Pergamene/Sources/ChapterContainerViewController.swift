import UIKit

// MARK: - ChapterContainerViewController

/// Manages horizontal chapter navigation using UIPageViewController
/// Provides three-panel architecture: previous chapter, current chapter, next chapter
class ChapterContainerViewController: UIViewController {
    
    // MARK: - Properties
    
    private var pageViewController: UIPageViewController!
    private var currentBook: Book?
    private var currentChapterNumber: Int = 1
    
    // Splash screen
    private let splashView = UIView()
    private let splashLabel = UILabel()
    private let splashSubtitleLabel = UILabel()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        
        setupSplashScreen()
        setupPageViewController()
        setupNotifications()
        loadLastReadingPosition()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Setup Methods
    
    private func setupSplashScreen() {
        splashView.translatesAutoresizingMaskIntoConstraints = false
        splashView.backgroundColor = UIColor.parchmentTexture
        
        // App name label with Gothic font
        splashLabel.translatesAutoresizingMaskIntoConstraints = false
        splashLabel.text = "Pergamene"
        let gothicFont = UIFont(name: "UnifrakturMaguntia-Book", size: 48) ??
                        UIFont(name: "UnifrakturMaguntia", size: 48) ??
                        UIFont(name: "Unifraktur Maguntia", size: 48)
        splashLabel.font = gothicFont ?? UIFont(name: "Cardo-Bold", size: 48) ?? .systemFont(ofSize: 48, weight: .bold)
        splashLabel.textColor = UIColor(red: 0.15, green: 0.1, blue: 0.05, alpha: 1.0)
        splashLabel.textAlignment = .center
        
        // Subtitle
        splashSubtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        splashSubtitleLabel.text = "Loading Scripture..."
        splashSubtitleLabel.font = UIFont(name: "Cardo-Regular", size: 16) ?? .systemFont(ofSize: 16)
        splashSubtitleLabel.textColor = UIColor(red: 0.25, green: 0.18, blue: 0.12, alpha: 1.0)
        splashSubtitleLabel.textAlignment = .center
        
        view.addSubview(splashView)
        splashView.addSubview(splashLabel)
        splashView.addSubview(splashSubtitleLabel)
        
        NSLayoutConstraint.activate([
            splashView.topAnchor.constraint(equalTo: view.topAnchor),
            splashView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            splashView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            splashView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            splashLabel.centerXAnchor.constraint(equalTo: splashView.centerXAnchor),
            splashLabel.centerYAnchor.constraint(equalTo: splashView.centerYAnchor, constant: -20),
            
            splashSubtitleLabel.topAnchor.constraint(equalTo: splashLabel.bottomAnchor, constant: 10),
            splashSubtitleLabel.centerXAnchor.constraint(equalTo: splashView.centerXAnchor)
        ])
    }
    
    private func removeSplashScreen() {
        UIView.animate(withDuration: 0.3, animations: {
            self.splashView.alpha = 0
        }) { _ in
            self.splashView.removeFromSuperview()
        }
    }
    
    private func setupPageViewController() {
        pageViewController = UIPageViewController(
            transitionStyle: .scroll,
            navigationOrientation: .horizontal,
            options: [.interPageSpacing: 3]
        )
        
        pageViewController.delegate = self
        pageViewController.dataSource = self
        
        addChild(pageViewController)
        view.addSubview(pageViewController.view)
        pageViewController.view.frame = view.bounds
        pageViewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        pageViewController.didMove(toParent: self)
        
        // Hide page control dots - we don't want them for chapter navigation
        let pageControl = UIPageControl.appearance(whenContainedInInstancesOf: [ChapterContainerViewController.self])
        pageControl.isHidden = true
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
        }
        
        // If no saved position or saved book not found, use first available book
        if currentBook == nil {
            currentBook = ScriptureManager.shared.books.first
            currentChapterNumber = 1
        }
        
        guard let book = currentBook else {
            print("ERROR: No books available in ScriptureManager")
            print("Available books count: \(ScriptureManager.shared.books.count)")
            // Still remove splash screen even if we have no content
            removeSplashScreen()
            return
        }
        
        let chapterVC = createChapterViewController(book: book, chapter: currentChapterNumber)
        pageViewController.setViewControllers(
            [chapterVC],
            direction: .forward,
            animated: false,
            completion: { [weak self] _ in
                // Remove splash screen after content is loaded
                self?.removeSplashScreen()
            }
        )
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
            return (book, chapter + 1)
        } else {
            guard let nextBook = getNextBook(after: book) else { return nil }
            return (nextBook, 1)
        }
    }
    
    private func getPreviousChapter(from viewController: ChapterViewController) -> (book: Book, chapter: Int)? {
        guard let book = viewController.getCurrentBook() else { return nil }
        let chapter = viewController.getCurrentChapter()
        
        if chapter > 1 {
            return (book, chapter - 1)
        } else {
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
    
    // MARK: - Public Methods
    
    func updateForBookChange(book: Book, chapter: Int) {
        // Update current state
        currentBook = book
        currentChapterNumber = chapter
        
        // Remove the old page view controller
        pageViewController.willMove(toParent: nil)
        pageViewController.view.removeFromSuperview()
        pageViewController.removeFromParent()
        
        // Create a fresh page view controller to ensure no cached state
        pageViewController = UIPageViewController(
            transitionStyle: .scroll,
            navigationOrientation: .horizontal,
            options: [.interPageSpacing: 3]
        )
        
        pageViewController.delegate = self
        pageViewController.dataSource = self
        
        // Add the new page view controller
        addChild(pageViewController)
        view.addSubview(pageViewController.view)
        pageViewController.view.frame = view.bounds
        pageViewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        pageViewController.didMove(toParent: self)
        
        // Create and set the chapter view controller
        let chapterVC = createChapterViewController(book: book, chapter: chapter)
        pageViewController.setViewControllers([chapterVC], direction: .forward, animated: false, completion: nil)
    }
    
    /// Navigate to a specific bookmark location
    /// This method properly invalidates the UIPageViewController cache to ensure correct swipe navigation
    func navigateToBookmark(book: Book, chapter: Int, scrollPosition: CGFloat) {
        // Update current state
        currentBook = book
        currentChapterNumber = chapter
        
        // Create a completely fresh UIPageViewController to clear all cache
        let newPageViewController = UIPageViewController(
            transitionStyle: .scroll,
            navigationOrientation: .horizontal,
            options: [.interPageSpacing: 3]
        )
        
        newPageViewController.delegate = self
        newPageViewController.dataSource = self
        
        // Remove old page view controller
        pageViewController.willMove(toParent: nil)
        pageViewController.view.removeFromSuperview()
        pageViewController.removeFromParent()
        
        // Add new page view controller
        pageViewController = newPageViewController
        addChild(pageViewController)
        view.addSubview(pageViewController.view)
        pageViewController.view.frame = view.bounds
        pageViewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        pageViewController.didMove(toParent: self)
        
        // Create new chapter view controller and set it
        let chapterVC = createChapterViewController(book: book, chapter: chapter)
        pageViewController.setViewControllers([chapterVC], direction: .forward, animated: true) { _ in
            // Restore scroll position after the view has loaded
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                if let scrollView = chapterVC.view.subviews.first(where: { $0 is UIScrollView }) as? UIScrollView {
                    scrollView.setContentOffset(CGPoint(x: 0, y: scrollPosition), animated: true)
                }
            }
        }
    }
    
    // MARK: - Notification Handlers
    
    @objc private func handleChapterSelection(_ notification: Notification) {
        guard let book = notification.userInfo?["book"] as? Book,
              let chapter = notification.userInfo?["chapter"] as? Int else { 
            print("ERROR: Failed to extract book/chapter from notification")
            return 
        }
        
        print("handleChapterSelection: \(book.name) chapter \(chapter)")
        
        // Use the same approach as navigateToBookmark to ensure proper navigation
        navigateToBookmark(book: book, chapter: chapter, scrollPosition: 0)
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
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        
        guard completed,
              let currentVC = pageViewController.viewControllers?.first as? ChapterViewController,
              let book = currentVC.getCurrentBook() else { return }
        
        currentBook = book
        currentChapterNumber = currentVC.getCurrentChapter()
        
        // Update current bookmark if we have one (from swiping)
        BookmarkManager.shared.updateCurrentBookmarkIfNeeded(
            bookName: book.name,
            chapter: currentChapterNumber
        )
        
        // Save reading position when chapter changes
        UserDataManager.shared.saveReadingPosition(
            book: book.name,
            chapter: currentChapterNumber,
            scrollPosition: 0
        )
    }
}