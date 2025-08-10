import UIKit

class MainTabBarController: UITabBarController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupViewControllers()
        setupAppearance()
    }
    
    private func setupViewControllers() {
        let readingVC = ReadingViewController()
        readingVC.tabBarItem = UITabBarItem(title: "Read", image: UIImage(systemName: "book"), tag: 0)
        let readingNav = UINavigationController(rootViewController: readingVC)
        
        let bookmarksVC = BookmarksViewController()
        bookmarksVC.tabBarItem = UITabBarItem(title: "Bookmarks", image: UIImage(systemName: "bookmark"), tag: 1)
        let bookmarksNav = UINavigationController(rootViewController: bookmarksVC)
        
        let highlightsVC = HighlightsViewController()
        highlightsVC.tabBarItem = UITabBarItem(title: "Highlights", image: UIImage(systemName: "highlighter"), tag: 2)
        let highlightsNav = UINavigationController(rootViewController: highlightsVC)
        
        viewControllers = [readingNav, bookmarksNav, highlightsNav]
    }
    
    private func setupAppearance() {
        tabBar.tintColor = UIColor(red: 0.6, green: 0.4, blue: 0.2, alpha: 1.0)
    }
}