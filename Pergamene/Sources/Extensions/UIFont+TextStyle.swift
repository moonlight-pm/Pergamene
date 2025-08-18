import UIKit

extension UIFont {
    
    /// Creates the standard text font with enhanced weight for better readability
    /// Uses Cardo-Regular with subtle stroke for weight without blur
    static func pergameneTextFont(size: CGFloat = 22) -> UIFont {
        return UIFont(name: "Cardo-Regular", size: size) ?? .systemFont(ofSize: size - 2, weight: .semibold)
    }
    
    /// Standard text attributes with enhanced weight
    static func pergameneTextAttributes(
        size: CGFloat = 22,
        color: UIColor? = nil,
        paragraphStyle: NSParagraphStyle? = nil
    ) -> [NSAttributedString.Key: Any] {
        var attributes: [NSAttributedString.Key: Any] = [
            .font: pergameneTextFont(size: size),
            .foregroundColor: color ?? UIColor(red: 0.07, green: 0.05, blue: 0.03, alpha: 0.98),
            .strokeWidth: -0.2, // Very subtle stroke for weight without blur
            .strokeColor: color ?? UIColor(red: 0.07, green: 0.05, blue: 0.03, alpha: 0.98)
        ]
        
        if let paragraphStyle = paragraphStyle {
            attributes[.paragraphStyle] = paragraphStyle
        }
        
        return attributes
    }
    
    /// Creates attributes for titles and headers
    static func pergameneTitleAttributes(size: CGFloat = 26) -> [NSAttributedString.Key: Any] {
        return pergameneTextAttributes(
            size: size,
            color: UIColor(red: 0.15, green: 0.1, blue: 0.05, alpha: 1.0)
        )
    }
}