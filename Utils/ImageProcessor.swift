import UIKit

enum ImageProcessor {
    static func processForUpload(_ image: UIImage, maxSize: CGFloat = 500, quality: CGFloat = 0.7) -> Data? {
        // Resize image
        let size = image.size
        let scale: CGFloat
        if size.width > size.height {
            scale = maxSize / size.width
        } else {
            scale = maxSize / size.height
        }
        
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        // Compress to JPEG
        return resizedImage?.jpegData(compressionQuality: quality)
    }
} 