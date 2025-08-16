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
    var verses: [Verse] = [] {
        didSet {
            if isViewLoaded {
                fromVersePicker.reloadAllComponents()
                toVersePicker.reloadAllComponents()
                updateInitialSelection()
            }
        }
    }
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Style the presentation to match our app
        overrideUserInterfaceStyle = .light
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
        titleLabel.text = "Share Verses"
        titleLabel.font = UIFont(name: "Cardo-Bold", size: 24) ?? .systemFont(ofSize: 24, weight: .bold)
        titleLabel.textColor = UIColor(red: 0.15, green: 0.1, blue: 0.05, alpha: 1.0)
        titleLabel.textAlignment = .center
        
        contentView.addSubview(titleLabel)
    }
    
    private func setupVerseSelectors() {
        // From verse label
        fromVerseLabel.translatesAutoresizingMaskIntoConstraints = false
        fromVerseLabel.text = "From:"
        fromVerseLabel.font = UIFont(name: "Cardo-Bold", size: 17) ?? .systemFont(ofSize: 17, weight: .semibold)
        fromVerseLabel.textColor = UIColor(red: 0.25, green: 0.18, blue: 0.12, alpha: 1.0)
        
        // To verse label
        toVerseLabel.translatesAutoresizingMaskIntoConstraints = false
        toVerseLabel.text = "To:"
        toVerseLabel.font = UIFont(name: "Cardo-Bold", size: 17) ?? .systemFont(ofSize: 17, weight: .semibold)
        toVerseLabel.textColor = UIColor(red: 0.25, green: 0.18, blue: 0.12, alpha: 1.0)
        
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
        updateInitialSelection()
        
        contentView.addSubview(fromVerseLabel)
        contentView.addSubview(toVerseLabel)
        contentView.addSubview(fromVersePicker)
        contentView.addSubview(toVersePicker)
    }
    
    private func setupPreview() {
        previewTextView.translatesAutoresizingMaskIntoConstraints = false
        previewTextView.isEditable = false
        previewTextView.isSelectable = false  // Disable text selection
        previewTextView.isScrollEnabled = true  // Enable scrolling for overflow
        // Light parchment style with border
        previewTextView.backgroundColor = UIColor(red: 0.98, green: 0.96, blue: 0.92, alpha: 0.5)
        previewTextView.layer.cornerRadius = 8
        previewTextView.layer.borderWidth = 1
        previewTextView.layer.borderColor = UIColor(red: 0.35, green: 0.25, blue: 0.15, alpha: 0.3).cgColor
        previewTextView.textContainerInset = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        previewTextView.font = UIFont(name: "Cardo-Regular", size: 16) ?? .systemFont(ofSize: 16)
        previewTextView.textColor = UIColor(red: 0.1, green: 0.07, blue: 0.04, alpha: 1.0)
        previewTextView.showsVerticalScrollIndicator = true
        previewTextView.indicatorStyle = .default
        
        contentView.addSubview(previewTextView)
    }
    
    private func setupShareButton() {
        shareButton.translatesAutoresizingMaskIntoConstraints = false
        shareButton.backgroundColor = UIColor(red: 0.35, green: 0.25, blue: 0.15, alpha: 1.0)
        shareButton.layer.cornerRadius = 8
        
        // Use configuration for all button styling
        var shareConfig = UIButton.Configuration.plain()
        shareConfig.title = "Share"
        shareConfig.baseForegroundColor = UIColor(red: 0.98, green: 0.96, blue: 0.92, alpha: 1.0)
        shareConfig.contentInsets = NSDirectionalEdgeInsets(top: 14, leading: 32, bottom: 14, trailing: 32)
        
        // Set the font through attributed string
        var titleContainer = AttributeContainer()
        titleContainer.font = UIFont(name: "Cardo-Bold", size: 18) ?? .systemFont(ofSize: 18, weight: .bold)
        shareConfig.attributedTitle = AttributedString("Share", attributes: titleContainer)
        
        shareButton.configuration = shareConfig
        shareButton.addTarget(self, action: #selector(shareTapped), for: .touchUpInside)
        
        // Add subtle shadow
        shareButton.layer.shadowColor = UIColor.black.cgColor
        shareButton.layer.shadowOffset = CGSize(width: 0, height: 2)
        shareButton.layer.shadowOpacity = 0.15
        shareButton.layer.shadowRadius = 4
        
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
            fromVerseLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 50),
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
            
            // Preview text - fixed height with scrolling
            previewTextView.topAnchor.constraint(equalTo: toVersePicker.bottomAnchor, constant: 30),
            previewTextView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            previewTextView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            previewTextView.heightAnchor.constraint(equalToConstant: 180),
            
            // Share button
            shareButton.topAnchor.constraint(equalTo: previewTextView.bottomAnchor, constant: 20),
            shareButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            shareButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -30)
        ])
    }
    
    // MARK: - Helper Methods
    
    private func updateInitialSelection() {
        if !verses.isEmpty {
            let startIndex = max(0, min(startVerse - 1, verses.count - 1))
            let endIndex = max(0, min(endVerse - 1, verses.count - 1))
            fromVersePicker.selectRow(startIndex, inComponent: 0, animated: false)
            toVersePicker.selectRow(endIndex, inComponent: 0, animated: false)
            updatePreview()
        }
    }
    
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
        
        // Format with quotes and reference
        var formattedText = "\""
        formattedText += previewText.trimmingCharacters(in: .whitespaces)
        formattedText += "\""
        
        // Add reference with long dash
        if let book = currentBook {
            let fromVerse = actualFromIndex + 1
            let toVerse = actualToIndex + 1
            
            if fromVerse == toVerse {
                formattedText += "\n— \(book.name) \(currentChapter):\(fromVerse)"
            } else {
                formattedText += "\n— \(book.name) \(currentChapter):\(fromVerse)-\(toVerse)"
            }
        }
        
        previewTextView.text = formattedText
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
        
        // Build the share text with quotes
        var shareText = "\""
        for (_, text) in selectedVerses {
            shareText += text + " "
        }
        shareText = shareText.trimmingCharacters(in: .whitespaces) + "\""
        
        // Add reference with long dash
        let fromVerse = fromIndex + 1
        let toVerse = toIndex + 1
        
        if fromVerse == toVerse {
            shareText += "\n— \(book.name) \(currentChapter):\(fromVerse)"
        } else {
            shareText += "\n— \(book.name) \(currentChapter):\(fromVerse)-\(toVerse)"
        }
        
        let finalShareText = shareText
        
        // Present share sheet directly from this controller
        let shareVC = UIActivityViewController(
            activityItems: [finalShareText],
            applicationActivities: nil
        )
        
        // For iPad compatibility
        if let popover = shareVC.popoverPresentationController {
            popover.sourceView = shareButton
            popover.sourceRect = shareButton.bounds
        }
        
        present(shareVC, animated: true)
        
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
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        let label = (view as? UILabel) ?? UILabel()
        label.font = UIFont(name: "Cardo-Regular", size: 16) ?? .systemFont(ofSize: 16)
        label.textColor = UIColor(red: 0.1, green: 0.07, blue: 0.04, alpha: 1.0)
        label.textAlignment = .left
        label.numberOfLines = 2
        label.lineBreakMode = .byTruncatingTail
        
        if row < verses.count {
            let verse = verses[row]
            let truncatedText = String(verse.text.prefix(80))
            label.text = "\(row + 1). \(truncatedText)..."
        }
        
        return label
    }
    
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return 44  // Slightly taller rows for better readability
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