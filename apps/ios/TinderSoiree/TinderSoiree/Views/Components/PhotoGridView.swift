import SwiftUI

struct PhotoGridView: View {
    let images: [UIImage]
    let maxPhotos: Int
    let onAddTapped: () -> Void
    let onRemoveTapped: (Int) -> Void
    let onReorder: ((Int, Int) -> Void)?

    private let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]

    init(
        images: [UIImage],
        maxPhotos: Int = 6,
        onAddTapped: @escaping () -> Void,
        onRemoveTapped: @escaping (Int) -> Void,
        onReorder: ((Int, Int) -> Void)? = nil
    ) {
        self.images = images
        self.maxPhotos = maxPhotos
        self.onAddTapped = onAddTapped
        self.onRemoveTapped = onRemoveTapped
        self.onReorder = onReorder
    }

    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            // Existing photos
            ForEach(images.indices, id: \.self) { index in
                PhotoCell(
                    image: images[index],
                    isMain: index == 0,
                    onRemove: {
                        onRemoveTapped(index)
                    }
                )
            }

            // Add button (if space available)
            if images.count < maxPhotos {
                AddPhotoCell(onTap: onAddTapped)
            }
        }
    }
}

// MARK: - Photo Cell
struct PhotoCell: View {
    let image: UIImage
    let isMain: Bool
    let onRemove: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(height: 120)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium))
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium)
                        .stroke(
                            isMain ? AppTheme.primaryGradient : LinearGradient(colors: [.clear], startPoint: .top, endPoint: .bottom),
                            lineWidth: isMain ? 3 : 0
                        )
                )

            // Main badge
            if isMain {
                Text("Principal")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(AppTheme.primaryGradient)
                    .cornerRadius(4)
                    .padding(6)
            }

            // Remove button
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.white, AppTheme.error)
                    .shadow(radius: 2)
            }
            .padding(4)
        }
    }
}

// MARK: - Add Photo Cell
struct AddPhotoCell: View {
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium)
                .fill(AppTheme.inputBackground)
                .frame(height: 120)
                .overlay(
                    VStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title)
                            .foregroundStyle(AppTheme.primaryGradient)

                        Text("Ajouter")
                            .font(.caption)
                            .foregroundColor(AppTheme.textSecondary)
                    }
                )
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium)
                        .strokeBorder(
                            style: StrokeStyle(lineWidth: 2, dash: [8])
                        )
                        .foregroundColor(AppTheme.primaryPurple.opacity(0.5))
                )
        }
    }
}

// MARK: - Photo Grid with URLs (for displaying existing photos)
struct PhotoGridURLView: View {
    let photoUrls: [String]
    let maxPhotos: Int
    let onAddTapped: () -> Void
    let onRemoveTapped: (Int) -> Void

    private let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            // Existing photos from URLs
            ForEach(photoUrls.indices, id: \.self) { index in
                PhotoURLCell(
                    url: photoUrls[index],
                    isMain: index == 0,
                    onRemove: {
                        onRemoveTapped(index)
                    }
                )
            }

            // Add button (if space available)
            if photoUrls.count < maxPhotos {
                AddPhotoCell(onTap: onAddTapped)
            }
        }
    }
}

// MARK: - Photo URL Cell
struct PhotoURLCell: View {
    let url: String
    let isMain: Bool
    let onRemove: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            AsyncImage(url: URL(string: url)) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure:
                    Rectangle()
                        .fill(AppTheme.cardBackground)
                        .overlay {
                            Image(systemName: "photo")
                                .foregroundColor(AppTheme.textTertiary)
                        }
                default:
                    Rectangle()
                        .fill(AppTheme.cardBackground)
                        .overlay {
                            ProgressView()
                                .tint(AppTheme.primaryPink)
                        }
                }
            }
            .frame(height: 120)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium)
                    .stroke(
                        isMain ? AppTheme.primaryGradient : LinearGradient(colors: [.clear], startPoint: .top, endPoint: .bottom),
                        lineWidth: isMain ? 3 : 0
                    )
            )

            // Main badge
            if isMain {
                Text("Principal")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(AppTheme.primaryGradient)
                    .cornerRadius(4)
                    .padding(6)
            }

            // Remove button
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.white, AppTheme.error)
                    .shadow(radius: 2)
            }
            .padding(4)
        }
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 20) {
        Text("Photo Grid (Empty)")
            .foregroundColor(.white)

        PhotoGridView(
            images: [],
            onAddTapped: {},
            onRemoveTapped: { _ in }
        )

        Text("Photo Grid with URLs")
            .foregroundColor(.white)

        PhotoGridURLView(
            photoUrls: [
                "https://example.com/photo1.jpg",
                "https://example.com/photo2.jpg"
            ],
            maxPhotos: 6,
            onAddTapped: {},
            onRemoveTapped: { _ in }
        )
    }
    .padding()
    .background(AppTheme.deepBlack)
}
