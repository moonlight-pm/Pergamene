import UIKit

// MARK: - Chapter Selection Notifications

extension Notification.Name {
    static let chapterSelected = Notification.Name("chapterSelected")
}

// MARK: - BookSelectionDelegate

protocol BookSelectionDelegate: AnyObject {
    func didSelectBook(_ book: Book)
}

// MARK: - BookSelectionViewController

/// Displays a list of all available books organized by testament
/// Allows navigation to individual books and chapters
class BookSelectionViewController: UIViewController {
    
    // MARK: - UI Components
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let oldTestamentLabel = UILabel()
    private let newTestamentLabel = UILabel()
    private let oldTestamentStack = UIStackView()
    private let newTestamentStack = UIStackView()
    private let dividerView = UIView()
    
    // MARK: - Properties
    
    private var books: [Book] = []
    private var oldTestamentBooks: [Book] = []
    private var newTestamentBooks: [Book] = []
    
    weak var delegate: BookSelectionDelegate?
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.parchmentTexture
        setupViews()
        loadBooks()
    }
    
    // MARK: - Setup Methods
    
    private func setupViews() {
        setupScrollView()
        setupTestamentSections()
        setupConstraints()
    }
    
    private func setupScrollView() {
        // Set the main view background to black for elastic scroll
        view.backgroundColor = .black
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.backgroundColor = UIColor.parchmentTexture  // Set scroll view background to parchment
        scrollView.showsVerticalScrollIndicator = true
        
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.backgroundColor = UIColor.parchmentTexture
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
    }
    
    
    private func setupTestamentSections() {
        // Old Testament section - "After Creation"
        oldTestamentLabel.translatesAutoresizingMaskIntoConstraints = false
        oldTestamentLabel.text = "After Creation"
        oldTestamentLabel.font = UIFont(name: "Cardo-Bold", size: 20) ?? .systemFont(ofSize: 20, weight: .semibold)
        oldTestamentLabel.textColor = UIColor(red: 0.2, green: 0.12, blue: 0.05, alpha: 1.0)
        oldTestamentLabel.textAlignment = .center
        
        oldTestamentStack.translatesAutoresizingMaskIntoConstraints = false
        oldTestamentStack.axis = .vertical
        oldTestamentStack.spacing = 8  // Add consistent spacing between items
        oldTestamentStack.alignment = .fill
        
        // New Testament section - "After Christ"
        newTestamentLabel.translatesAutoresizingMaskIntoConstraints = false
        newTestamentLabel.text = "After Christ"
        newTestamentLabel.font = UIFont(name: "Cardo-Bold", size: 20) ?? .systemFont(ofSize: 20, weight: .semibold)
        newTestamentLabel.textColor = UIColor(red: 0.2, green: 0.12, blue: 0.05, alpha: 1.0)
        newTestamentLabel.textAlignment = .center
        
        newTestamentStack.translatesAutoresizingMaskIntoConstraints = false
        newTestamentStack.axis = .vertical
        newTestamentStack.spacing = 8  // Add consistent spacing between items
        newTestamentStack.alignment = .fill
        
        // Divider line
        dividerView.translatesAutoresizingMaskIntoConstraints = false
        dividerView.backgroundColor = UIColor(red: 0.35, green: 0.25, blue: 0.15, alpha: 0.2)
        
        contentView.addSubview(oldTestamentLabel)
        contentView.addSubview(oldTestamentStack)
        contentView.addSubview(newTestamentLabel)
        contentView.addSubview(newTestamentStack)
        contentView.addSubview(dividerView)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Scroll view - now starts at top
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // Two-column layout
            // Old Testament (After Creation) - Left column  
            oldTestamentLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 60),  // Extra padding from top
            oldTestamentLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            oldTestamentLabel.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.5, constant: -30),
            
            oldTestamentStack.topAnchor.constraint(equalTo: oldTestamentLabel.bottomAnchor, constant: 12),
            oldTestamentStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            oldTestamentStack.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.5, constant: -30),
            
            // New Testament (After Christ) - Right column
            newTestamentLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 60),  // Match OT padding
            newTestamentLabel.leadingAnchor.constraint(equalTo: contentView.centerXAnchor, constant: 10),
            newTestamentLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            newTestamentStack.topAnchor.constraint(equalTo: newTestamentLabel.bottomAnchor, constant: 12),
            newTestamentStack.leadingAnchor.constraint(equalTo: contentView.centerXAnchor, constant: 10),
            newTestamentStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            // Content view bottom - use the longer of the two stacks
            contentView.bottomAnchor.constraint(greaterThanOrEqualTo: oldTestamentStack.bottomAnchor, constant: 30),
            contentView.bottomAnchor.constraint(greaterThanOrEqualTo: newTestamentStack.bottomAnchor, constant: 30),
            
            // Divider
            dividerView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            dividerView.topAnchor.constraint(equalTo: oldTestamentLabel.topAnchor),
            dividerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -30),
            dividerView.widthAnchor.constraint(equalToConstant: 1)
        ])
    }
    
    // MARK: - Data Loading
    
    private func loadBooks() {
        books = ScriptureManager.shared.books
        oldTestamentBooks = books.filter { $0.testament == "Old" }
        newTestamentBooks = books.filter { $0.testament == "New" }
        
        // Create book buttons for Old Testament
        for book in oldTestamentBooks {
            let button = createBookButton(book: book)
            oldTestamentStack.addArrangedSubview(button)
        }
        
        // Create book buttons for New Testament
        for book in newTestamentBooks {
            let button = createBookButton(book: book)
            newTestamentStack.addArrangedSubview(button)
        }
    }
    
    private func createBookButton(book: Book) -> UIButton {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.heightAnchor.constraint(greaterThanOrEqualToConstant: 50).isActive = true  // Minimum height, can grow
        
        // Create attributed string for book name and chapter count
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont(name: "Cardo-Regular", size: 18) ?? .systemFont(ofSize: 18),
            .foregroundColor: UIColor(red: 0.1, green: 0.07, blue: 0.04, alpha: 1.0),
            .paragraphStyle: paragraphStyle
        ]
        
        let chapterCount = book.chapters.count == 1 ? "1 chapter" : "\(book.chapters.count) chapters"
        let subtitleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont(name: "Cardo-Regular", size: 14) ?? .systemFont(ofSize: 14),
            .foregroundColor: UIColor(red: 0.25, green: 0.18, blue: 0.12, alpha: 0.9),
            .paragraphStyle: paragraphStyle
        ]
        
        let attributedTitle = NSMutableAttributedString()
        attributedTitle.append(NSAttributedString(string: book.name, attributes: titleAttributes))
        attributedTitle.append(NSAttributedString(string: "\n", attributes: titleAttributes))
        attributedTitle.append(NSAttributedString(string: chapterCount, attributes: subtitleAttributes))
        
        button.setAttributedTitle(attributedTitle, for: .normal)
        button.titleLabel?.numberOfLines = 0  // Allow unlimited lines for wrapping
        button.titleLabel?.lineBreakMode = .byWordWrapping
        button.contentHorizontalAlignment = .center
        
        // Use newer UIButton configuration for iOS 15+ instead of deprecated contentEdgeInsets
        if #available(iOS 15.0, *) {
            var config = UIButton.Configuration.plain()
            config.attributedTitle = AttributedString(attributedTitle)
            config.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 8, bottom: 10, trailing: 8)
            config.titleLineBreakMode = .byWordWrapping
            button.configuration = config
        } else {
            // Fallback for older iOS versions
            button.contentEdgeInsets = UIEdgeInsets(top: 10, left: 8, bottom: 10, right: 8)
        }
        
        // Add touch feedback
        button.addTarget(self, action: #selector(bookButtonTouchDown(_:)), for: .touchDown)
        button.addTarget(self, action: #selector(bookButtonTouchUp(_:)), for: [.touchUpInside, .touchUpOutside, .touchCancel])
        
        // Store the book index for selection
        if let index = books.firstIndex(where: { $0.name == book.name }) {
            button.tag = index
        }
        button.addTarget(self, action: #selector(bookSelected(_:)), for: .touchUpInside)
        
        return button
    }
    
    // MARK: - Button Actions
    
    @objc private func bookButtonTouchDown(_ sender: UIButton) {
        UIView.animate(withDuration: 0.1) {
            sender.backgroundColor = UIColor(red: 0.82, green: 0.72, blue: 0.58, alpha: 0.3)
        }
    }
    
    @objc private func bookButtonTouchUp(_ sender: UIButton) {
        UIView.animate(withDuration: 0.2) {
            sender.backgroundColor = .clear
        }
    }
    
    @objc private func bookSelected(_ sender: UIButton) {
        let book = books[sender.tag]
        
        if book.chapters.count == 1 {
            // Single chapter book - navigate directly
            NotificationCenter.default.post(
                name: .chapterSelected,
                object: nil,
                userInfo: ["book": book, "chapter": 1]
            )
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                self?.dismiss(animated: true)
            }
        } else {
            // Multi-chapter book - show chapter selection
            let chapterVC = ChapterSelectionViewController(book: book)
            chapterVC.delegate = self
            chapterVC.modalPresentationStyle = .pageSheet
            if let sheet = chapterVC.sheetPresentationController {
                sheet.detents = [.medium()]
                sheet.prefersGrabberVisible = true
            }
            present(chapterVC, animated: true)
        }
    }
}

// MARK: - ChapterSelectionDelegate

extension BookSelectionViewController: ChapterSelectionDelegate {
    func didSelectChapter(_ chapter: Int, in book: Book) {
        // Post notification to load the selected chapter
        NotificationCenter.default.post(
            name: .chapterSelected,
            object: nil,
            userInfo: ["book": book, "chapter": chapter]
        )
        
        // Dismiss both the chapter selection and book selection views
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.presentedViewController?.dismiss(animated: true)
            self?.dismiss(animated: true)
        }
    }
}