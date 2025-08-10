import UIKit

protocol BookSelectionDelegate: AnyObject {
    func didSelectBook(_ book: Book)
}

class BookSelectionViewController: UIViewController {
    
    private let tableView = UITableView()
    private var books: [Book] = []
    private var oldTestamentBooks: [Book] = []
    private var newTestamentBooks: [Book] = []
    
    weak var delegate: BookSelectionDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Books"
        view.backgroundColor = .systemBackground
        
        setupNavigationBar()
        setupTableView()
        loadBooks()
    }
    
    private func setupNavigationBar() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: self,
            action: #selector(dismissView)
        )
        
        navigationController?.navigationBar.prefersLargeTitles = true
    }
    
    private func setupTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(BookTableViewCell.self, forCellReuseIdentifier: "BookCell")
        tableView.sectionIndexColor = UIColor(red: 0.6, green: 0.4, blue: 0.2, alpha: 1.0)
        
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func loadBooks() {
        books = ScriptureManager.shared.books
        oldTestamentBooks = books.filter { $0.testament == "Old" }
        newTestamentBooks = books.filter { $0.testament == "New" }
        tableView.reloadData()
    }
    
    @objc private func dismissView() {
        dismiss(animated: true)
    }
}

// MARK: - UITableViewDataSource

extension BookSelectionViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? oldTestamentBooks.count : newTestamentBooks.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "BookCell", for: indexPath) as! BookTableViewCell
        let book = indexPath.section == 0 ? oldTestamentBooks[indexPath.row] : newTestamentBooks[indexPath.row]
        cell.configure(with: book)
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return section == 0 ? "Old Testament" : "New Testament"
    }
    
    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return ["OT", "NT"]
    }
}

// MARK: - UITableViewDelegate

extension BookSelectionViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let book = indexPath.section == 0 ? oldTestamentBooks[indexPath.row] : newTestamentBooks[indexPath.row]
        
        let chapterVC = ChapterSelectionViewController(book: book)
        chapterVC.delegate = self
        navigationController?.pushViewController(chapterVC, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
}

// MARK: - ChapterSelectionDelegate

extension BookSelectionViewController: ChapterSelectionDelegate {
    func didSelectChapter(_ chapter: Int, in book: Book) {
        delegate?.didSelectBook(book)
        dismiss(animated: true) {
            NotificationCenter.default.post(
                name: .chapterSelected,
                object: nil,
                userInfo: ["book": book, "chapter": chapter]
            )
        }
    }
}

// MARK: - Custom Cell

class BookTableViewCell: UITableViewCell {
    
    private let bookNameLabel = UILabel()
    private let chapterCountLabel = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        bookNameLabel.translatesAutoresizingMaskIntoConstraints = false
        bookNameLabel.font = .systemFont(ofSize: 17)
        
        chapterCountLabel.translatesAutoresizingMaskIntoConstraints = false
        chapterCountLabel.font = .systemFont(ofSize: 14)
        chapterCountLabel.textColor = .secondaryLabel
        
        contentView.addSubview(bookNameLabel)
        contentView.addSubview(chapterCountLabel)
        
        NSLayoutConstraint.activate([
            bookNameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            bookNameLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            
            chapterCountLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            chapterCountLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
        
        accessoryType = .disclosureIndicator
    }
    
    func configure(with book: Book) {
        bookNameLabel.text = book.name
        let chapterText = book.chapters.count == 1 ? "1 chapter" : "\(book.chapters.count) chapters"
        chapterCountLabel.text = chapterText
    }
}

// MARK: - Notification Extension

extension Notification.Name {
    static let chapterSelected = Notification.Name("chapterSelected")
}