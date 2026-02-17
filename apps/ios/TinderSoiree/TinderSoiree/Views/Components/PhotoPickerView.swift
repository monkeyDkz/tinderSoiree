import SwiftUI
import PhotosUI

struct PhotoPickerView: View {
    @Binding var selectedImages: [UIImage]
    let maxPhotos: Int
    let onPhotosChanged: (([UIImage]) -> Void)?

    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var showingActionSheet = false
    @State private var selectedItems: [PhotosPickerItem] = []

    init(
        selectedImages: Binding<[UIImage]>,
        maxPhotos: Int = 6,
        onPhotosChanged: (([UIImage]) -> Void)? = nil
    ) {
        self._selectedImages = selectedImages
        self.maxPhotos = maxPhotos
        self.onPhotosChanged = onPhotosChanged
    }

    var body: some View {
        VStack(spacing: AppTheme.spacingM) {
            // Photo Grid
            PhotoGridView(
                images: selectedImages,
                maxPhotos: maxPhotos,
                onAddTapped: {
                    showingActionSheet = true
                },
                onRemoveTapped: { index in
                    removePhoto(at: index)
                },
                onReorder: { from, to in
                    reorderPhotos(from: from, to: to)
                }
            )

            // Helper text
            if selectedImages.isEmpty {
                Text("Ajoute au moins une photo")
                    .font(.caption)
                    .foregroundColor(AppTheme.textTertiary)
            } else {
                Text("\(selectedImages.count)/\(maxPhotos) photos")
                    .font(.caption)
                    .foregroundColor(AppTheme.textSecondary)
            }
        }
        .confirmationDialog("Ajouter une photo", isPresented: $showingActionSheet) {
            Button("Prendre une photo") {
                showingCamera = true
            }

            Button("Choisir depuis la galerie") {
                showingImagePicker = true
            }

            Button("Annuler", role: .cancel) {}
        }
        .sheet(isPresented: $showingCamera) {
            CameraView(image: Binding(
                get: { nil },
                set: { newImage in
                    if let image = newImage {
                        addPhoto(image)
                    }
                }
            ))
        }
        .photosPicker(
            isPresented: $showingImagePicker,
            selection: $selectedItems,
            maxSelectionCount: maxPhotos - selectedImages.count,
            matching: .images
        )
        .onChange(of: selectedItems) { _, newItems in
            Task {
                for item in newItems {
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        addPhoto(image)
                    }
                }
                selectedItems = []
            }
        }
    }

    private func addPhoto(_ image: UIImage) {
        guard selectedImages.count < maxPhotos else { return }
        selectedImages.append(image)
        onPhotosChanged?(selectedImages)
    }

    private func removePhoto(at index: Int) {
        guard index < selectedImages.count else { return }
        selectedImages.remove(at: index)
        onPhotosChanged?(selectedImages)
    }

    private func reorderPhotos(from source: Int, to destination: Int) {
        guard source != destination else { return }
        let photo = selectedImages.remove(at: source)
        selectedImages.insert(photo, at: destination)
        onPhotosChanged?(selectedImages)
    }
}

// MARK: - Camera View
struct CameraView: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraView

        init(_ parent: CameraView) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// MARK: - Preview
#Preview {
    struct PreviewWrapper: View {
        @State private var images: [UIImage] = []

        var body: some View {
            PhotoPickerView(selectedImages: $images)
                .padding()
                .background(AppTheme.deepBlack)
        }
    }

    return PreviewWrapper()
}
