import SwiftUI
import UIKit

// Custom image loader that adds ngrok-skip-browser-warning header
@MainActor
class ImageLoader: ObservableObject {
    @Published var image: UIImage?
    @Published var isLoading = false

    func load(from urlString: String) {
        guard let url = URL(string: urlString) else { return }

        isLoading = true

        var request = URLRequest(url: url)
        request.setValue("true", forHTTPHeaderField: "ngrok-skip-browser-warning")

        URLSession.shared.dataTask(with: request) { [weak self] data, _, _ in
            DispatchQueue.main.async {
                self?.isLoading = false
                if let data = data {
                    self?.image = UIImage(data: data)
                }
            }
        }.resume()
    }
}

struct RemoteImage: View {
    let url: String?

    @StateObject private var loader = ImageLoader()

    var body: some View {
        Group {
            if let loadedImage = loader.image {
                Image(uiImage: loadedImage)
                    .resizable()
            } else if loader.isLoading {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .overlay {
                        ProgressView()
                            .tint(.white)
                    }
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .overlay {
                        Image(systemName: "person.fill")
                            .foregroundColor(.gray)
                    }
            }
        }
        .onAppear {
            if let url = url, loader.image == nil {
                loader.load(from: url)
            }
        }
    }
}
