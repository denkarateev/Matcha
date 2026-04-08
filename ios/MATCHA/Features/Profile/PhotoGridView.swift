import PhotosUI
import SwiftUI

// MARK: - PhotoSlot

struct PhotoSlot: Identifiable {
    let id: UUID
    var image: UIImage?
    var remoteURL: URL?
    var isEmpty: Bool { image == nil && remoteURL == nil }

    init(id: UUID = UUID(), image: UIImage? = nil, remoteURL: URL? = nil) {
        self.id = id
        self.image = image
        self.remoteURL = remoteURL
    }
}

// MARK: - PhotoGridView

/// Reusable 2x3 photo grid (2 columns, 3 rows = 6 slots) for profile photo management.
/// Supports pick, auto-crop to 4:5, reorder via drag, delete, and "Set as Main".
struct PhotoGridView: View {
    @Binding var photos: [PhotoSlot]

    @State private var pickerTargetIndex: Int?
    @State private var selectedPickerItem: PhotosPickerItem?
    @State private var draggingSlotID: UUID?
    @State private var isLoadingPhoto = false

    private let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8),
    ]

    private let slotCount = 6

    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(0..<slotCount, id: \.self) { index in
                let slot = index < photos.count ? photos[index] : nil

                if let slot, !slot.isEmpty {
                    filledCell(slot: slot, index: index)
                } else {
                    emptyCell(index: index)
                }
            }
        }
        .onChange(of: selectedPickerItem) { _, newItem in
            guard let newItem else { return }
            Task { await loadPhoto(from: newItem) }
        }
    }

    // MARK: - Filled Cell

    @ViewBuilder
    private func filledCell(slot: PhotoSlot, index: Int) -> some View {
        GeometryReader { geo in
            ZStack(alignment: .topTrailing) {
                // Photo — auto-cropped to 4:5 center
                if let uiImage = slot.image {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geo.size.width, height: geo.size.width * 5 / 4)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                } else if let url = slot.remoteURL {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: geo.size.width, height: geo.size.width * 5 / 4)
                                .clipped()
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        default:
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color.white.opacity(0.06))
                                .frame(width: geo.size.width, height: geo.size.width * 5 / 4)
                                .overlay {
                                    ProgressView().tint(.white.opacity(0.3))
                                }
                        }
                    }
                }

                // "Main" badge on first photo
                if index == 0 {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Text("Main")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundStyle(.black)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(MatchaTokens.Colors.accent, in: Capsule())
                            Spacer()
                        }
                        .padding(.bottom, 8)
                    }
                }

                // Drag handle (bottom-left)
                VStack {
                    Spacer()
                    HStack {
                        Image(systemName: "line.3.horizontal")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white.opacity(0.8))
                            .padding(6)
                            .background(.black.opacity(0.45), in: Circle())
                            .padding(8)
                        Spacer()
                    }
                }

                // Delete button (top-right)
                Button(action: { deletePhoto(at: index) }) {
                    ZStack {
                        Circle()
                            .fill(Color.black.opacity(0.6))
                            .frame(width: 24, height: 24)
                        Image(systemName: "xmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
                .padding(8)
                .accessibilityLabel("Remove photo \(index + 1)")
            }
            .frame(width: geo.size.width, height: geo.size.width * 5 / 4)
            .shadow(color: .black.opacity(0.15), radius: 6, y: 3)
            .opacity(draggingSlotID == slot.id ? 0.5 : 1)
            .onDrag {
                draggingSlotID = slot.id
                return NSItemProvider(object: slot.id.uuidString as NSString)
            }
            .onDrop(of: [.text], delegate: PhotoDropDelegate(
                targetIndex: index,
                photos: $photos,
                draggingSlotID: $draggingSlotID
            ))
            .contextMenu {
                if index != 0 {
                    Button {
                        setAsMain(index: index)
                    } label: {
                        Label("Set as Main", systemImage: "star.fill")
                    }
                }

                Button(role: .destructive) {
                    deletePhoto(at: index)
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
        .aspectRatio(4 / 5, contentMode: .fit)
    }

    // MARK: - Empty Cell

    @ViewBuilder
    private func emptyCell(index: Int) -> some View {
        PhotosPicker(
            selection: $selectedPickerItem,
            matching: .images,
            photoLibrary: .shared()
        ) {
            GeometryReader { geo in
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(.regularMaterial)
                        .environment(\.colorScheme, .dark)

                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(
                            Color.white.opacity(0.2),
                            style: StrokeStyle(lineWidth: 1.5, dash: [6, 4])
                        )

                    if isLoadingPhoto && pickerTargetIndex == index {
                        ProgressView()
                            .tint(MatchaTokens.Colors.accent)
                    } else {
                        Image(systemName: "plus")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundStyle(Color.white.opacity(0.4))
                    }
                }
                .frame(width: geo.size.width, height: geo.size.width * 5 / 4)
            }
        }
        .aspectRatio(4 / 5, contentMode: .fit)
        .onDrop(of: [.text], delegate: PhotoDropDelegate(
            targetIndex: index,
            photos: $photos,
            draggingSlotID: $draggingSlotID
        ))
        .simultaneousGesture(TapGesture().onEnded {
            pickerTargetIndex = nextEmptyIndex(from: index)
        })
        .accessibilityLabel("Add photo to slot \(index + 1)")
    }

    // MARK: - Actions

    private func loadPhoto(from item: PhotosPickerItem) async {
        isLoadingPhoto = true
        defer {
            isLoadingPhoto = false
            selectedPickerItem = nil
        }

        do {
            guard let data = try await item.loadTransferable(type: Data.self),
                  let uiImage = UIImage(data: data) else { return }

            let cropped = autoCropToAspect(uiImage, ratio: 4.0 / 5.0)
            let targetIndex = pickerTargetIndex ?? nextEmptyIndex(from: 0) ?? photos.count

            await MainActor.run {
                let newSlot = PhotoSlot(image: cropped)
                if targetIndex < photos.count {
                    photos[targetIndex] = newSlot
                } else if photos.count < slotCount {
                    photos.append(newSlot)
                }
            }
        } catch {
            // Silently fail for MVP; could surface an error banner
        }
    }

    private func deletePhoto(at index: Int) {
        guard index < photos.count else { return }
        withAnimation(MatchaTokens.Animations.buttonPress) {
            photos.remove(at: index)
        }
    }

    private func setAsMain(index: Int) {
        guard index > 0, index < photos.count else { return }
        withAnimation(MatchaTokens.Animations.cardAppear) {
            let moved = photos.remove(at: index)
            photos.insert(moved, at: 0)
        }
    }

    private func nextEmptyIndex(from hint: Int) -> Int? {
        if hint >= photos.count { return hint < slotCount ? hint : nil }
        // Find first empty slot
        for i in 0..<slotCount {
            if i >= photos.count { return i }
            if photos[i].isEmpty { return i }
        }
        return photos.count < slotCount ? photos.count : nil
    }

    // MARK: - Auto Crop

    /// Center-crops a UIImage to the given aspect ratio (width / height).
    private func autoCropToAspect(_ image: UIImage, ratio: CGFloat) -> UIImage {
        let imageSize = image.size
        let imageAspect = imageSize.width / imageSize.height

        var cropRect: CGRect
        if imageAspect > ratio {
            // Image is wider than target — crop sides
            let newWidth = imageSize.height * ratio
            let xOffset = (imageSize.width - newWidth) / 2
            cropRect = CGRect(x: xOffset, y: 0, width: newWidth, height: imageSize.height)
        } else {
            // Image is taller than target — crop top/bottom
            let newHeight = imageSize.width / ratio
            let yOffset = (imageSize.height - newHeight) / 2
            cropRect = CGRect(x: 0, y: yOffset, width: imageSize.width, height: newHeight)
        }

        // Adjust for UIImage scale
        let scale = image.scale
        let scaledRect = CGRect(
            x: cropRect.origin.x * scale,
            y: cropRect.origin.y * scale,
            width: cropRect.width * scale,
            height: cropRect.height * scale
        )

        guard let cgImage = image.cgImage?.cropping(to: scaledRect) else { return image }
        return UIImage(cgImage: cgImage, scale: scale, orientation: image.imageOrientation)
    }
}

// MARK: - PhotoDropDelegate

private struct PhotoDropDelegate: DropDelegate {
    let targetIndex: Int
    @Binding var photos: [PhotoSlot]
    @Binding var draggingSlotID: UUID?

    func performDrop(info: DropInfo) -> Bool {
        draggingSlotID = nil
        return true
    }

    func dropEntered(info: DropInfo) {
        guard let draggingID = draggingSlotID,
              let fromIndex = photos.firstIndex(where: { $0.id == draggingID }),
              fromIndex != targetIndex,
              targetIndex < photos.count
        else { return }

        withAnimation(MatchaTokens.Animations.cardAppear) {
            photos.move(fromOffsets: IndexSet(integer: fromIndex), toOffset: targetIndex > fromIndex ? targetIndex + 1 : targetIndex)
        }
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }

    func dropExited(info: DropInfo) {}
}

// MARK: - Preview

#Preview("Photo Grid - Empty") {
    ZStack {
        MatchaTokens.backgroundGradient.ignoresSafeArea()

        ScrollView {
            PhotoGridView(photos: .constant([]))
                .padding(16)
        }
    }
    .preferredColorScheme(.dark)
}

#Preview("Photo Grid - Partial") {
    @Previewable @State var slots: [PhotoSlot] = [
        PhotoSlot(image: UIImage(systemName: "person.crop.circle.fill")),
        PhotoSlot(image: UIImage(systemName: "photo.artframe")),
        PhotoSlot(image: UIImage(systemName: "camera.fill")),
    ]

    ZStack {
        MatchaTokens.backgroundGradient.ignoresSafeArea()

        ScrollView {
            PhotoGridView(photos: $slots)
                .padding(16)
        }
    }
    .preferredColorScheme(.dark)
}
