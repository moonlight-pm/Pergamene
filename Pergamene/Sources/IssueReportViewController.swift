import UIKit
import MessageUI

class IssueReportViewController: UIViewController {
    
    // MARK: - UI Components
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let titleLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let textView = UITextView()
    private let placeholderLabel = UILabel()
    private let sendButton = UIButton()
    private let cancelButton = UIButton()
    private let characterCountLabel = UILabel()
    
    private let maxCharacters = 500
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupKeyboardHandling()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        textView.becomeFirstResponder()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        view.backgroundColor = UIColor.parchmentTexture
        
        // Title
        titleLabel.text = "Report an Issue"
        titleLabel.font = UIFont(name: "Cardo-Bold", size: 24) ?? .systemFont(ofSize: 24, weight: .bold)
        titleLabel.textColor = UIColor(red: 0.15, green: 0.1, blue: 0.05, alpha: 1.0)
        titleLabel.textAlignment = .center
        
        // Description
        descriptionLabel.text = "Shake your device anytime to report an issue or suggestion"
        descriptionLabel.font = UIFont(name: "Cardo-Regular", size: 14) ?? .systemFont(ofSize: 14)
        descriptionLabel.textColor = UIColor(red: 0.35, green: 0.25, blue: 0.15, alpha: 1.0)
        descriptionLabel.textAlignment = .center
        descriptionLabel.numberOfLines = 0
        
        // Text View
        textView.font = UIFont(name: "Cardo-Regular", size: 16) ?? .systemFont(ofSize: 16)
        textView.textColor = UIColor(red: 0.15, green: 0.1, blue: 0.05, alpha: 1.0)
        textView.backgroundColor = UIColor(red: 0.98, green: 0.97, blue: 0.94, alpha: 0.5)
        textView.layer.borderColor = UIColor(red: 0.45, green: 0.35, blue: 0.25, alpha: 0.3).cgColor
        textView.layer.borderWidth = 1
        textView.layer.cornerRadius = 8
        textView.textContainerInset = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        textView.delegate = self
        
        // Placeholder
        placeholderLabel.text = "Describe the issue or suggestion..."
        placeholderLabel.font = UIFont(name: "Cardo-Italic", size: 16) ?? .systemFont(ofSize: 16)
        placeholderLabel.textColor = UIColor(red: 0.45, green: 0.35, blue: 0.25, alpha: 0.6)
        placeholderLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Character count
        characterCountLabel.text = "0/\(maxCharacters)"
        characterCountLabel.font = UIFont(name: "Cardo-Regular", size: 12) ?? .systemFont(ofSize: 12)
        characterCountLabel.textColor = UIColor(red: 0.45, green: 0.35, blue: 0.25, alpha: 0.6)
        characterCountLabel.textAlignment = .right
        
        // Send Button
        var sendConfig = UIButton.Configuration.filled()
        sendConfig.title = "Send Report"
        sendConfig.baseBackgroundColor = UIColor(red: 0.35, green: 0.25, blue: 0.15, alpha: 1.0)
        sendConfig.baseForegroundColor = .white
        sendConfig.cornerStyle = .medium
        sendButton.configuration = sendConfig
        sendButton.addTarget(self, action: #selector(sendTapped), for: .touchUpInside)
        
        // Cancel Button
        var cancelConfig = UIButton.Configuration.plain()
        cancelConfig.title = "Cancel"
        cancelConfig.baseForegroundColor = UIColor(red: 0.45, green: 0.35, blue: 0.25, alpha: 1.0)
        cancelButton.configuration = cancelConfig
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        
        // Layout
        setupLayout()
    }
    
    private func setupLayout() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        contentView.addSubview(titleLabel)
        contentView.addSubview(descriptionLabel)
        contentView.addSubview(textView)
        textView.addSubview(placeholderLabel)
        contentView.addSubview(characterCountLabel)
        contentView.addSubview(sendButton)
        contentView.addSubview(cancelButton)
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        textView.translatesAutoresizingMaskIntoConstraints = false
        characterCountLabel.translatesAutoresizingMaskIntoConstraints = false
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            descriptionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            descriptionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            textView.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 20),
            textView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            textView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            textView.heightAnchor.constraint(equalToConstant: 200),
            
            placeholderLabel.topAnchor.constraint(equalTo: textView.topAnchor, constant: 12),
            placeholderLabel.leadingAnchor.constraint(equalTo: textView.leadingAnchor, constant: 16),
            placeholderLabel.trailingAnchor.constraint(equalTo: textView.trailingAnchor, constant: -16),
            
            characterCountLabel.topAnchor.constraint(equalTo: textView.bottomAnchor, constant: 8),
            characterCountLabel.trailingAnchor.constraint(equalTo: textView.trailingAnchor),
            
            sendButton.topAnchor.constraint(equalTo: characterCountLabel.bottomAnchor, constant: 20),
            sendButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            sendButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            sendButton.heightAnchor.constraint(equalToConstant: 50),
            
            cancelButton.topAnchor.constraint(equalTo: sendButton.bottomAnchor, constant: 12),
            cancelButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            cancelButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])
    }
    
    private func setupKeyboardHandling() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }
    
    // MARK: - Actions
    
    @objc private func sendTapped() {
        guard let text = textView.text, !text.isEmpty else {
            showAlert(title: "Empty Report", message: "Please describe the issue before sending.")
            return
        }
        
        // Store the report locally
        storeIssueReport(text)
        
        // Show success message
        showAlert(title: "Thank You!", message: "Your report has been saved and will be reviewed.") { [weak self] in
            self?.dismiss(animated: true)
        }
    }
    
    @objc private func cancelTapped() {
        dismiss(animated: true)
    }
    
    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        scrollView.contentInset.bottom = keyboardFrame.height
        scrollView.scrollIndicatorInsets.bottom = keyboardFrame.height
    }
    
    @objc private func keyboardWillHide(_ notification: Notification) {
        scrollView.contentInset.bottom = 0
        scrollView.scrollIndicatorInsets.bottom = 0
    }
    
    // MARK: - Helpers
    
    private func storeIssueReport(_ text: String) {
        // Store in UserDefaults for now
        var reports = UserDefaults.standard.array(forKey: "IssueReports") as? [[String: Any]] ?? []
        
        let report: [String: Any] = [
            "text": text,
            "date": Date().timeIntervalSince1970,
            "version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown",
            "device": UIDevice.current.model,
            "ios": UIDevice.current.systemVersion
        ]
        
        reports.append(report)
        UserDefaults.standard.set(reports, forKey: "IssueReports")
        
        // Log for debugging
        print("Issue report saved: \(text)")
        print("Total reports: \(reports.count)")
    }
    
    private func showAlert(title: String, message: String, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            completion?()
        })
        present(alert, animated: true)
    }
}

// MARK: - UITextViewDelegate

extension IssueReportViewController: UITextViewDelegate {
    
    func textViewDidChange(_ textView: UITextView) {
        // Update placeholder visibility
        placeholderLabel.isHidden = !textView.text.isEmpty
        
        // Update character count
        let count = textView.text.count
        characterCountLabel.text = "\(count)/\(maxCharacters)"
        
        // Change color if near limit
        if count > maxCharacters - 50 {
            characterCountLabel.textColor = UIColor(red: 0.8, green: 0.2, blue: 0.1, alpha: 1.0)
        } else {
            characterCountLabel.textColor = UIColor(red: 0.45, green: 0.35, blue: 0.25, alpha: 0.6)
        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let currentText = textView.text ?? ""
        let updatedText = (currentText as NSString).replacingCharacters(in: range, with: text)
        return updatedText.count <= maxCharacters
    }
}