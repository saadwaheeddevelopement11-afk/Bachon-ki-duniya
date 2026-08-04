import UIKit

enum ProfileAvatarStore {

    private static let fileName = "profile_avatar.jpg"

    private static var fileURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(fileName)
    }

    static func load() -> UIImage? {
        let url = fileURL
        guard FileManager.default.fileExists(atPath: url.path),
              let data = try? Data(contentsOf: url),
              let image = UIImage(data: data) else {
            return nil
        }
        return image
    }

    @discardableResult
    static func save(_ image: UIImage) -> Bool {
        let resized = image.resizedForAvatar(maxDimension: 720)
        guard let data = resized.jpegData(compressionQuality: 0.85) else { return false }
        do {
            try data.write(to: fileURL, options: .atomic)
            return true
        } catch {
            print("ProfileAvatarStore save failed: \(error)")
            return false
        }
    }

    static func clear() {
        try? FileManager.default.removeItem(at: fileURL)
    }
}

private extension UIImage {
    func resizedForAvatar(maxDimension: CGFloat) -> UIImage {
        let longest = max(size.width, size.height)
        guard longest > maxDimension else { return self }
        let scale = maxDimension / longest
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
