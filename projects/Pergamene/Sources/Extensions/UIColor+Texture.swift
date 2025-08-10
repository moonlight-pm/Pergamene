import UIKit

extension UIColor {
    static var parchmentTexture: UIColor {
        guard let image = UIImage(named: "parchment_texture") else {
            // Fallback to solid color if texture not found
            return UIColor(red: 0.98, green: 0.97, blue: 0.94, alpha: 1.0)
        }
        
        return UIColor(patternImage: image)
    }
    
    static var parchmentSolid: UIColor {
        return UIColor(red: 0.98, green: 0.97, blue: 0.94, alpha: 1.0)
    }
}