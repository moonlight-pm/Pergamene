import UIKit

protocol ChapterSelectionDelegate: AnyObject {
    func didSelectChapter(_ chapter: Int, in book: Book)
}

class ChapterSelectionViewController: UIViewController {
    
    private let book: Book
    private let collectionView: UICollectionView
    
    weak var delegate: ChapterSelectionDelegate?
    
    init(book: Book) {
        self.book = book
        
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 12
        layout.minimumLineSpacing = 12
        layout.sectionInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        
        self.collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = book.name
        view.backgroundColor = .systemBackground
        
        setupCollectionView()
    }
    
    private func setupCollectionView() {
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .systemBackground
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(ChapterCell.self, forCellWithReuseIdentifier: "ChapterCell")
        
        view.addSubview(collectionView)
        
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
}

// MARK: - UICollectionViewDataSource

extension ChapterSelectionViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return book.chapters.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ChapterCell", for: indexPath) as! ChapterCell
        let chapter = book.chapters[indexPath.item]
        cell.configure(with: chapter.number)
        
        // Check if this chapter has a bookmark
        let hasBookmark = UserDataManager.shared.bookmarks.contains { 
            $0.bookName == book.name && $0.chapter == chapter.number 
        }
        cell.showBookmarkIndicator(hasBookmark)
        
        return cell
    }
}

// MARK: - UICollectionViewDelegate

extension ChapterSelectionViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let chapter = book.chapters[indexPath.item]
        delegate?.didSelectChapter(chapter.number, in: book)
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension ChapterSelectionViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let padding: CGFloat = 16 * 2 + 12 * 4
        let availableWidth = collectionView.frame.width - padding
        let itemWidth = availableWidth / 5
        return CGSize(width: itemWidth, height: itemWidth)
    }
}

// MARK: - Chapter Cell

class ChapterCell: UICollectionViewCell {
    
    private let label = UILabel()
    private let bookmarkIndicator = UIView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        contentView.backgroundColor = UIColor(red: 0.95, green: 0.93, blue: 0.88, alpha: 1.0)
        contentView.layer.cornerRadius = 8
        contentView.layer.borderWidth = 1
        contentView.layer.borderColor = UIColor(red: 0.6, green: 0.4, blue: 0.2, alpha: 0.3).cgColor
        
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 18, weight: .medium)
        label.textColor = UIColor(red: 0.4, green: 0.3, blue: 0.2, alpha: 1.0)
        
        bookmarkIndicator.translatesAutoresizingMaskIntoConstraints = false
        bookmarkIndicator.backgroundColor = UIColor(red: 0.8, green: 0.2, blue: 0.2, alpha: 1.0)
        bookmarkIndicator.layer.cornerRadius = 3
        bookmarkIndicator.isHidden = true
        
        contentView.addSubview(label)
        contentView.addSubview(bookmarkIndicator)
        
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            
            bookmarkIndicator.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            bookmarkIndicator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -4),
            bookmarkIndicator.widthAnchor.constraint(equalToConstant: 6),
            bookmarkIndicator.heightAnchor.constraint(equalToConstant: 6)
        ])
    }
    
    func configure(with chapterNumber: Int) {
        label.text = "\(chapterNumber)"
    }
    
    func showBookmarkIndicator(_ show: Bool) {
        bookmarkIndicator.isHidden = !show
    }
    
    override var isHighlighted: Bool {
        didSet {
            UIView.animate(withDuration: 0.1) {
                self.contentView.transform = self.isHighlighted ? CGAffineTransform(scaleX: 0.95, y: 0.95) : .identity
                self.contentView.backgroundColor = self.isHighlighted ? 
                    UIColor(red: 0.9, green: 0.85, blue: 0.75, alpha: 1.0) : 
                    UIColor(red: 0.95, green: 0.93, blue: 0.88, alpha: 1.0)
            }
        }
    }
}