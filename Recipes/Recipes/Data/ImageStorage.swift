import UIKit

protocol ImageStorage {
    func saveImage(_ image: UIImage) throws -> String
    func loadImage(named filename: String?) -> UIImage?
}

class FileSystemImageStorage: ImageStorage {
    private let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    private let imagesDirectory = "RecipeImages"
    
    init() {
        // Create images directory if it doesn't exist
        let imagesPath = documentsDirectory.appendingPathComponent(imagesDirectory)
        if !FileManager.default.fileExists(atPath: imagesPath.path) {
            try? FileManager.default.createDirectory(at: imagesPath, withIntermediateDirectories: true)
        }
    }
    
    func saveImage(_ image: UIImage) throws -> String {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw ImageStorageError.couldNotConvertToData
        }
        
        let filename = "\(UUID().uuidString).jpg"
        let imagePath = documentsDirectory.appendingPathComponent(imagesDirectory).appendingPathComponent(filename)
        
        do {
            try imageData.write(to: imagePath)
            return filename
        } catch {
            throw ImageStorageError.couldNotSaveImage
        }
    }
    
    func loadImage(named filename: String?) -> UIImage? {
        guard let filename = filename else { return nil }
        
        // First try to load from filesystem (for user-added images)
        let imagePath = documentsDirectory.appendingPathComponent(imagesDirectory).appendingPathComponent(filename)
        if FileManager.default.fileExists(atPath: imagePath.path),
           let imageData = try? Data(contentsOf: imagePath),
           let image = UIImage(data: imageData) {
            return image
        }
        
        // If not found in filesystem, try to load from asset catalog (for sample images)
        return UIImage(named: filename)
    }
}

enum ImageStorageError: Error {
    case couldNotConvertToData
    case couldNotSaveImage
}
