import UIKit

protocol BookSelectionDelegate: AnyObject {
    func didSelectBook(_ book: Book)
}

class BookSelectionViewController: UIViewController {
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let titleLabel = UILabel()
    private let oldTestamentLabel = UILabel()
    private let newTestamentLabel = UILabel()
    private let oldTestamentStack = UIStackView()
    private let newTestamentStack = UIStackView()
    
    private var books: [Book] = []
    private var oldTestamentBooks: [Book] = []
    private var newTestamentBooks: [Book] = []
    
    weak var delegate: BookSelectionDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Parchment background
        view.backgroundColor = UIColor(red: 0.98, green: 0.97, blue: 0.94, alpha: 1.0)
        
        setupViews()
        loadBooks()
    }
    
    private func setupViews() {
        // Title
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "Select Book"
        titleLabel.font = UIFont(name: "Cardo-Bold", size: 28) ?? .systemFont(ofSize: 28, weight: .bold)
        titleLabel.textColor = UIColor(red: 0.4, green: 0.3, blue: 0.2, alpha: 1.0)
        titleLabel.textAlignment = .center
        
        // Scroll view setup
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(titleLabel)
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        // Old Testament section
        oldTestamentLabel.translatesAutoresizingMaskIntoConstraints = false
        oldTestamentLabel.text = "Old Testament"
        oldTestamentLabel.font = UIFont(name: "Cardo-Bold", size: 22) ?? .systemFont(ofSize: 22, weight: .semibold)
        oldTestamentLabel.textColor = UIColor(red: 0.5, green: 0.35, blue: 0.2, alpha: 1.0)
        
        oldTestamentStack.translatesAutoresizingMaskIntoConstraints = false
        oldTestamentStack.axis = .vertical
        oldTestamentStack.spacing = 0
        oldTestamentStack.alignment = .fill
        
        // New Testament section
        newTestamentLabel.translatesAutoresizingMaskIntoConstraints = false
        newTestamentLabel.text = "New Testament"
        newTestamentLabel.font = UIFont(name: "Cardo-Bold", size: 22) ?? .systemFont(ofSize: 22, weight: .semibold)
        newTestamentLabel.textColor = UIColor(red: 0.5, green: 0.35, blue: 0.2, alpha: 1.0)
        
        newTestamentStack.translatesAutoresizingMaskIntoConstraints = false
        newTestamentStack.axis = .vertical
        newTestamentStack.spacing = 0
        newTestamentStack.alignment = .fill
        
        contentView.addSubview(oldTestamentLabel)
        contentView.addSubview(oldTestamentStack)
        contentView.addSubview(newTestamentLabel)
        contentView.addSubview(newTestamentStack)
        
        NSLayoutConstraint.activate([
            // Title
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            // Scroll view
            scrollView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // Old Testament
            oldTestamentLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            oldTestamentLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            oldTestamentLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            oldTestamentStack.topAnchor.constraint(equalTo: oldTestamentLabel.bottomAnchor, constant: 12),
            oldTestamentStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            oldTestamentStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            // New Testament
            newTestamentLabel.topAnchor.constraint(equalTo: oldTestamentStack.bottomAnchor, constant: 30),
            newTestamentLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            newTestamentLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            newTestamentStack.topAnchor.constraint(equalTo: newTestamentLabel.bottomAnchor, constant: 12),
            newTestamentStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            newTestamentStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            newTestamentStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -30)
        ])
    }
    
    private func loadBooks() {
        // Scripture data is already loaded in memory
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
        button.heightAnchor.constraint(equalToConstant: 50).isActive = true
        
        // Create attributed string for book name and chapter count
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .left
        
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont(name: "Cardo-Regular", size: 18) ?? .systemFont(ofSize: 18),
            .foregroundColor: UIColor(red: 0.3, green: 0.25, blue: 0.2, alpha: 1.0),
            .paragraphStyle: paragraphStyle
        ]
        
        let chapterCount = book.chapters.count == 1 ? "1 chapter" : "\(book.chapters.count) chapters"
        let subtitleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont(name: "Cardo-Regular", size: 14) ?? .systemFont(ofSize: 14),
            .foregroundColor: UIColor(red: 0.5, green: 0.4, blue: 0.3, alpha: 0.8),
            .paragraphStyle: paragraphStyle
        ]
        
        let attributedTitle = NSMutableAttributedString()
        attributedTitle.append(NSAttributedString(string: book.name, attributes: titleAttributes))
        attributedTitle.append(NSAttributedString(string: "\n", attributes: titleAttributes))
        attributedTitle.append(NSAttributedString(string: chapterCount, attributes: subtitleAttributes))
        
        button.setAttributedTitle(attributedTitle, for: .normal)
        button.titleLabel?.numberOfLines = 2
        button.contentHorizontalAlignment = .left
        button.contentEdgeInsets = UIEdgeInsets(top: 8, left: 10, bottom: 8, right: 10)
        
        // Add subtle background on hover/press
        button.addTarget(self, action: #selector(bookButtonTouchDown(_:)), for: .touchDown)
        button.addTarget(self, action: #selector(bookButtonTouchUp(_:)), for: [.touchUpInside, .touchUpOutside, .touchCancel])
        
        // Store the actual index in our books array
        if let index = books.firstIndex(where: { $0.name == book.name }) {
            button.tag = index
        }
        button.addTarget(self, action: #selector(bookSelected(_:)), for: .touchUpInside)
        
        return button
    }
    
    @objc private func bookButtonTouchDown(_ sender: UIButton) {
        UIView.animate(withDuration: 0.1) {
            sender.backgroundColor = UIColor(red: 0.93, green: 0.91, blue: 0.86, alpha: 1.0)
        }
    }
    
    @objc private func bookButtonTouchUp(_ sender: UIButton) {
        UIView.animate(withDuration: 0.2) {
            sender.backgroundColor = .clear
        }
    }
    
    @objc private func bookSelected(_ sender: UIButton) {
        let book = books[sender.tag]
        
        // If book has only one chapter, select it directly
        if book.chapters.count == 1 {
            delegate?.didSelectBook(book)
            dismiss(animated: true) {
                NotificationCenter.default.post(
                    name: .chapterSelected,
                    object: nil,
                    userInfo: ["book": book, "chapter": 1]
                )
            }
        } else {
            // Show chapter selection
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
        // Dismiss views immediately with animation
        presentedViewController?.dismiss(animated: true)
        delegate?.didSelectBook(book)
        dismiss(animated: true) {
            // Post notification after dismissal completes
            NotificationCenter.default.post(
                name: .chapterSelected,
                object: nil,
                userInfo: ["book": book, "chapter": chapter]
            )
        }
    }
}

// MARK: - Notification Extension

extension Notification.Name {
    static let chapterSelected = Notification.Name("chapterSelected")
}