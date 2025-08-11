import UIKit

// MARK: - VerseSelectionViewControllerDelegate

protocol VerseSelectionViewControllerDelegate: AnyObject {
    func verseSelectionViewController(_ controller: VerseSelectionViewController, didSelectVerses verses: [(Int, String)], book: Book, chapter: Int)
}

// MARK: - VerseSelectionViewController

/// A sheet that allows users to select a range of verses to share
class VerseSelectionViewController: UIViewController {
    
    // MARK: - Properties
    
    weak var delegate: VerseSelectionViewControllerDelegate?
    var currentBook: Book?
    var currentChapter: Int = 1
    var verses: [Verse] = []
    var startVerse: Int = 1
    var endVerse: Int = 1
    
    // MARK: - UI Components
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let titleLabel = UILabel()
    private let fromVerseLabel = UILabel()
    private let toVerseLabel = UILabel()
    private let fromVersePicker = UIPickerView()
    private let toVersePicker = UIPickerView()
    private let previewTextView = UITextView()
    private let shareButton = UIButton(type: .system)
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.parchmentTexture
        setupViews()
        updatePreview()
    }
    
    // MARK: - Setup Methods
    
    private func setupViews() {
        setupScrollView()
        setupTitle()
        setupVerseSelectors()
        setupPreview()
        setupShareButton()
        setupConstraints()
    }
    
    private func setupScrollView() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
    }
    
    private func setupTitle() {
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "Select Verses to Share"
        titleLabel.font = UIFont(name: "Cardo-Bold", size: 20) ?? .systemFont(ofSize: 20, weight: .bold)
        titleLabel.textColor = UIColor(red: 0.15, green: 0.1, blue: 0.05, alpha: 1.0)
        titleLabel.textAlignment = .center
        
        contentView.addSubview(titleLabel)
    }
    
    private func setupVerseSelectors() {
        // From verse label
        fromVerseLabel.translatesAutoresizingMaskIntoConstraints = false
        fromVerseLabel.text = "From:"
        fromVerseLabel.font = UIFont(name: "Cardo-Bold", size: 16) ?? .systemFont(ofSize: 16, weight: .semibold)
        fromVerseLabel.textColor = UIColor(red: 0.1, green: 0.07, blue: 0.04, alpha: 1.0)
        
        // To verse label
        toVerseLabel.translatesAutoresizingMaskIntoConstraints = false
        toVerseLabel.text = "To:"
        toVerseLabel.font = UIFont(name: "Cardo-Bold", size: 16) ?? .systemFont(ofSize: 16, weight: .semibold)
        toVerseLabel.textColor = UIColor(red: 0.1, green: 0.07, blue: 0.04, alpha: 1.0)
        
        // From verse picker
        fromVersePicker.translatesAutoresizingMaskIntoConstraints = false
        fromVersePicker.delegate = self
        fromVersePicker.dataSource = self
        fromVersePicker.tag = 0
        
        // To verse picker
        toVersePicker.translatesAutoresizingMaskIntoConstraints = false
        toVersePicker.delegate = self
        toVersePicker.dataSource = self
        toVersePicker.tag = 1
        
        // Set initial selections
        if !verses.isEmpty {
            let startIndex = max(0, startVerse - 1)
            let endIndex = max(0, min(endVerse - 1, verses.count - 1))
            fromVersePicker.selectRow(startIndex, inComponent: 0, animated: false)
            toVersePicker.selectRow(endIndex, inComponent: 0, animated: false)
        }
        
        contentView.addSubview(fromVerseLabel)
        contentView.addSubview(toVerseLabel)
        contentView.addSubview(fromVersePicker)
        contentView.addSubview(toVersePicker)
    }
    
    private func setupPreview() {
        previewTextView.translatesAutoresizingMaskIntoConstraints = false
        previewTextView.isEditable = false
        previewTextView.isScrollEnabled = true
        // Inverse style with 90% opacity
        previewTextView.backgroundColor = UIColor(red: 0.15, green: 0.1, blue: 0.05, alpha: 0.9)
        previewTextView.layer.cornerRadius = 8
        previewTextView.layer.borderWidth = 1
        previewTextView.layer.borderColor = UIColor(red: 0.35, green: 0.25, blue: 0.15, alpha: 0.5).cgColor
        previewTextView.contentInset = UIEdgeInsets(top: 15, left: 15, bottom: 15, right: 15)
        previewTextView.font = UIFont(name: "Cardo-Regular", size: 15) ?? .systemFont(ofSize: 15)
        previewTextView.textColor = UIColor(red: 0.98, green: 0.96, blue: 0.92, alpha: 1.0)
        
        contentView.addSubview(previewTextView)
    }
    
    private func setupShareButton() {
        shareButton.translatesAutoresizingMaskIntoConstraints = false
        shareButton.setTitle("Share", for: .normal)
        shareButton.titleLabel?.font = UIFont(name: "Cardo-Bold", size: 18) ?? .systemFont(ofSize: 18, weight: .bold)
        shareButton.tintColor = .white
        shareButton.backgroundColor = UIColor(red: 0.45, green: 0.35, blue: 0.25, alpha: 1.0)
        shareButton.layer.cornerRadius = 8
        shareButton.contentEdgeInsets = UIEdgeInsets(top: 12, left: 24, bottom: 12, right: 24)
        shareButton.addTarget(self, action: #selector(shareTapped), for: .touchUpInside)
        
        contentView.addSubview(shareButton)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Scroll view
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Content view
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // Title
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 30),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            // From verse label and picker (stacked layout)
            fromVerseLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 30),
            fromVerseLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            fromVerseLabel.widthAnchor.constraint(equalToConstant: 60),
            
            fromVersePicker.centerYAnchor.constraint(equalTo: fromVerseLabel.centerYAnchor),
            fromVersePicker.leadingAnchor.constraint(equalTo: fromVerseLabel.trailingAnchor, constant: 10),
            fromVersePicker.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            fromVersePicker.heightAnchor.constraint(equalToConstant: 100),
            
            // To verse label and picker (stacked layout)
            toVerseLabel.topAnchor.constraint(equalTo: fromVersePicker.bottomAnchor, constant: 20),
            toVerseLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            toVerseLabel.widthAnchor.constraint(equalToConstant: 60),
            
            toVersePicker.centerYAnchor.constraint(equalTo: toVerseLabel.centerYAnchor),
            toVersePicker.leadingAnchor.constraint(equalTo: toVerseLabel.trailingAnchor, constant: 10),
            toVersePicker.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            toVersePicker.heightAnchor.constraint(equalToConstant: 100),
            
            // Preview text
            previewTextView.topAnchor.constraint(equalTo: toVersePicker.bottomAnchor, constant: 30),
            previewTextView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            previewTextView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            previewTextView.heightAnchor.constraint(equalToConstant: 150),
            
            // Share button
            shareButton.topAnchor.constraint(equalTo: previewTextView.bottomAnchor, constant: 20),
            shareButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            shareButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -30)
        ])
    }
    
    // MARK: - Helper Methods
    
    private func updatePreview() {
        guard !verses.isEmpty else { return }
        
        let fromIndex = fromVersePicker.selectedRow(inComponent: 0)
        let toIndex = toVersePicker.selectedRow(inComponent: 0)
        
        // Ensure valid range
        let actualFromIndex = min(fromIndex, toIndex)
        let actualToIndex = max(fromIndex, toIndex)
        
        var previewText = ""
        for i in actualFromIndex...actualToIndex {
            if i < verses.count {
                let verse = verses[i]
                previewText += verse.text + " "
            }
        }
        
        // Add reference
        if let book = currentBook {
            let fromVerse = actualFromIndex + 1
            let toVerse = actualToIndex + 1
            
            if fromVerse == toVerse {
                previewText += "\n\n- \(book.name) \(currentChapter):\(fromVerse)"
            } else {
                previewText += "\n\n- \(book.name) \(currentChapter):\(fromVerse)-\(toVerse)"
            }
        }
        
        previewTextView.text = previewText.trimmingCharacters(in: .whitespaces)
        
        // Update stored selection
        startVerse = actualFromIndex + 1
        endVerse = actualToIndex + 1
    }
    
    // MARK: - Actions
    
    @objc private func shareTapped() {
        guard let book = currentBook, !verses.isEmpty else { return }
        
        let fromIndex = min(fromVersePicker.selectedRow(inComponent: 0), toVersePicker.selectedRow(inComponent: 0))
        let toIndex = max(fromVersePicker.selectedRow(inComponent: 0), toVersePicker.selectedRow(inComponent: 0))
        
        var selectedVerses: [(Int, String)] = []
        for i in fromIndex...toIndex {
            if i < verses.count {
                selectedVerses.append((i + 1, verses[i].text))
            }
        }
        
        // Share the verses
        var shareText = ""
        for (_, text) in selectedVerses {
            shareText += text + " "
        }
        
        // Add reference
        let fromVerse = fromIndex + 1
        let toVerse = toIndex + 1
        
        if fromVerse == toVerse {
            shareText += "\n\n- \(book.name) \(currentChapter):\(fromVerse)"
        } else {
            shareText += "\n\n- \(book.name) \(currentChapter):\(fromVerse)-\(toVerse)"
        }
        
        let shareVC = UIActivityViewController(
            activityItems: [shareText.trimmingCharacters(in: .whitespaces)],
            applicationActivities: nil
        )
        
        // Dismiss this sheet first, then present share sheet
        dismiss(animated: true) { [weak self] in
            if let presenter = self?.presentingViewController {
                presenter.present(shareVC, animated: true)
            }
        }
        
        // Notify delegate
        delegate?.verseSelectionViewController(self, didSelectVerses: selectedVerses, book: book, chapter: currentChapter)
    }
}

// MARK: - UIPickerViewDataSource

extension VerseSelectionViewController: UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return verses.count
    }
}

// MARK: - UIPickerViewDelegate

extension VerseSelectionViewController: UIPickerViewDelegate {
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        guard row < verses.count else { return nil }
        let verse = verses[row]
        let truncatedText = String(verse.text.prefix(50))
        return "\(row + 1). \(truncatedText)..."
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        // Ensure from verse is not after to verse
        if pickerView.tag == 0 { // From picker
            let toRow = toVersePicker.selectedRow(inComponent: 0)
            if row > toRow {
                toVersePicker.selectRow(row, inComponent: 0, animated: true)
            }
        } else { // To picker
            let fromRow = fromVersePicker.selectedRow(inComponent: 0)
            if row < fromRow {
                fromVersePicker.selectRow(row, inComponent: 0, animated: true)
            }
        }
        
        updatePreview()
    }
}