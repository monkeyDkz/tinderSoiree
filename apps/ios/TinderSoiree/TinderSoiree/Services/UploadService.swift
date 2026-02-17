import Foundation
import UIKit

// MARK: - Models

struct DirectUploadRequest: Encodable {
    let imageBase64: String
    let contentType: String
    let purpose: String
}

struct DirectUploadResponse: Decodable {
    let fileUrl: String
}

struct UpdatePhotosRequest: Encodable {
    let photos: [PhotoUpdate]
}

struct PhotoUpdate: Encodable {
    let url: String
    let position: Int
    let isMain: Bool
}

// MARK: - Upload Service

class UploadService {
    static let shared = UploadService()

    private let apiClient = APIClient.shared

    private init() {}

    /// Upload a UIImage directly via the backend and return the final URL
    /// - Parameters:
    ///   - image: The UIImage to upload
    ///   - quality: JPEG compression quality (0.0 to 1.0)
    ///   - purpose: "profile_photo" or "event_cover"
    /// - Returns: The public URL of the uploaded image
    func uploadImage(_ image: UIImage, quality: CGFloat = 0.7, purpose: String = "profile_photo") async throws -> String {
        // Compress image to JPEG
        guard let imageData = image.jpegData(compressionQuality: quality) else {
            throw APIError.serverError("Failed to compress image")
        }

        // Convert to base64
        let base64String = imageData.base64EncodedString()

        let request = DirectUploadRequest(
            imageBase64: base64String,
            contentType: "image/jpeg",
            purpose: purpose
        )

        let response: DirectUploadResponse = try await apiClient.post("/upload/direct", body: request)
        return response.fileUrl
    }

    /// Upload multiple images and return their URLs
    /// - Parameters:
    ///   - images: Array of UIImages to upload
    ///   - quality: JPEG compression quality
    /// - Returns: Array of uploaded image URLs
    func uploadImages(_ images: [UIImage], quality: CGFloat = 0.7) async throws -> [String] {
        var urls: [String] = []

        for image in images {
            let url = try await uploadImage(image, quality: quality)
            urls.append(url)
        }

        return urls
    }

    /// Update user profile with new photos
    /// - Parameter photoUrls: Array of photo URLs in order
    func updateProfilePhotos(_ photoUrls: [String]) async throws {
        let photos = photoUrls.enumerated().map { index, url in
            PhotoUpdate(url: url, position: index, isMain: index == 0)
        }

        let request = UpdatePhotosRequest(photos: photos)
        let _: User = try await apiClient.patch("/me", body: request)
    }
}
