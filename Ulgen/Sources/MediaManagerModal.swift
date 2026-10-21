import SwiftUI
import PhotosUI

public struct MediaManagerModal: View {
    public var projectId: String
    public var targetTitle: String = "Proje Geneli"
    public var targetTopicId: String? = nil
    public var targetSubTopicId: String? = nil
    public var onDismiss: () -> Void = {}

    @ObservedObject var repo = ProjectRepository.shared
    @State private var activeTab: String = "existing" // default to existing if media exists
    @State private var selectedMediaIds: Set<String> = []
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var isUploadingToDrive: Bool = false
    @State private var mediaToDelete: MediaItem? = nil

    private var project: Project? {
        repo.projects.first(where: { $0.id == projectId })
    }

    private var mediaList: [MediaItem] {
        project?.media ?? []
    }

    public init(
        projectId: String,
        targetTitle: String = "Proje Geneli",
        targetTopicId: String? = nil,
        targetSubTopicId: String? = nil,
        onDismiss: @escaping () -> Void = {}
    ) {
        self.projectId = projectId
        self.targetTitle = targetTitle
        self.targetTopicId = targetTopicId
        self.targetSubTopicId = targetSubTopicId
        self.onDismiss = onDismiss
    }

    public var body: some View {
        ZStack {
            // Dark Scrim Backdrop
            Color.black.opacity(0.65)
                .ignoresSafeArea()
                .onTapGesture {
                    onDismiss()
                }

            // Centered Modal Dialog Card (1:1 Android AttachMediaModal)
            VStack(alignment: .leading, spacing: 14) {
                // Header Row
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "paperclip")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(Color(hex: "#A16207"))
                        .padding(.top, 2)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Medya İliştir")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(repo.isDarkMode ? Color(hex: "#F5F5F4") : Color(hex: "#2C1810"))

                        Text(targetTitle)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(repo.isDarkMode ? Color(hex: "#A8A29E") : Color(hex: "#78716C"))
                            .lineLimit(1)
                    }

                    Spacer()

                    Button(action: onDismiss) {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(repo.isDarkMode ? Color(hex: "#A8A29E") : Color(hex: "#78716C"))
                            .frame(width: 28, height: 28)
                            .background(repo.isDarkMode ? Color.white.opacity(0.08) : Color.black.opacity(0.05))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.scaleSpring(scale: 0.90))
                }

                // 2-Segment Tab Bar (Var Olan Medyalar / Yeni Yükle)
                HStack(spacing: 0) {
                    Button(action: {
                        Haptics.light()
                        activeTab = "existing"
                    }) {
                        Text("Var Olan Medyalar (\(mediaList.count))")
                            .font(.system(size: 13, weight: activeTab == "existing" ? .bold : .medium))
                            .foregroundColor(activeTab == "existing" ? .white : (repo.isDarkMode ? Color(hex: "#A8A29E") : Color(hex: "#57534E")))
                            .frame(maxWidth: .infinity)
                            .frame(height: 36)
                            .background(activeTab == "existing" ? Color(hex: "#A16207") : Color.clear)
                            .cornerRadius(8)
                    }
                    .buttonStyle(.scaleSpring(scale: 0.96))

                    Button(action: {
                        Haptics.light()
                        activeTab = "upload"
                    }) {
                        Text("Yeni Yükle")
                            .font(.system(size: 13, weight: activeTab == "upload" ? .bold : .medium))
                            .foregroundColor(activeTab == "upload" ? .white : (repo.isDarkMode ? Color(hex: "#A8A29E") : Color(hex: "#57534E")))
                            .frame(maxWidth: .infinity)
                            .frame(height: 36)
                            .background(activeTab == "upload" ? Color(hex: "#A16207") : Color.clear)
                            .cornerRadius(8)
                    }
                    .buttonStyle(.scaleSpring(scale: 0.96))
                }
                .padding(3)
                .background(repo.isDarkMode ? Color(hex: "#262320") : Color(hex: "#EFECE6"))
                .cornerRadius(10)

                // Tab Content
                if activeTab == "upload" {
                    // Upload Drop Area Card with PhotosPicker
                    PhotosPicker(selection: $selectedPhotos, maxSelectionCount: 5, matching: .any(of: [.images, .videos])) {
                        VStack(spacing: 10) {
                            if isUploadingToDrive {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "#A16207")))
                                    .scaleEffect(1.2)
                                Text("Drive ve Projeye Yükleniyor...")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(repo.isDarkMode ? Color(hex: "#F5F5F4") : Color(hex: "#2C1810"))
                            } else {
                                Image(systemName: "icloud.and.arrow.up.fill")
                                    .font(.system(size: 38))
                                    .foregroundColor(Color(hex: "#A16207"))

                                Text("Fotoğraf / Video Seç")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(repo.isDarkMode ? Color(hex: "#F5F5F4") : Color(hex: "#2C1810"))

                                Text("Galeri veya dosyalardan seçmek için dokunun")
                                    .font(.system(size: 12))
                                    .foregroundColor(repo.isDarkMode ? Color(hex: "#A8A29E") : Color(hex: "#78716C"))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 160)
                        .background(repo.isDarkMode ? Color(hex: "#292524") : Color.white)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    repo.isDarkMode ? Color(hex: "#44403C") : Color(hex: "#D6D1C7"),
                                    style: StrokeStyle(lineWidth: 1.5, dash: [6, 4])
                                )
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(isUploadingToDrive)
                    .onChange(of: selectedPhotos) { newItems in
                        Task {
                            await MainActor.run { isUploadingToDrive = true }
                            for item in newItems {
                                if let data = try? await item.loadTransferable(type: Data.self) {
                                    let base64 = data.base64EncodedString()
                                    let fileName = "Medya_\(Int(Date().timeIntervalSince1970)).jpg"
                                    var newMedia = MediaItem(
                                        name: fileName,
                                        base64Data: base64,
                                        size: Int64(data.count)
                                    )

                                    // Upload binary directly to Drive visible Medyalar folder if Google Drive is authorized
                                    if GoogleDriveSyncEngine.shared.isAuthorized, let p = project {
                                        if let driveId = try? await GoogleDriveSyncEngine.shared.uploadMediaBinaryToDrive(
                                            mediaId: newMedia.id,
                                            fileData: data,
                                            mimeType: "image/jpeg",
                                            originalFileName: fileName,
                                            projectId: p.id,
                                            projectTitle: p.title
                                        ), !driveId.isEmpty {
                                            newMedia.driveFileId = driveId
                                        }
                                    }

                                    await MainActor.run {
                                        repo.attachMedia(projectId: projectId, media: newMedia)
                                        selectedMediaIds.insert(newMedia.id)

                                        // Attach directly if targetTopicId / targetSubTopicId is set
                                        if let subId = targetSubTopicId, let tId = targetTopicId {
                                            repo.toggleMediaAttachmentToSubTopic(projectId: projectId, topicId: tId, subTopicId: subId, mediaId: newMedia.id)
                                        } else if let tId = targetTopicId {
                                            repo.toggleMediaAttachmentToTopic(projectId: projectId, topicId: tId, mediaId: newMedia.id)
                                        }

                                        Haptics.success()
                                    }
                                }
                            }
                            await MainActor.run {
                                selectedPhotos.removeAll()
                                isUploadingToDrive = false
                                activeTab = "existing"
                            }
                        }
                    }
                } else {
                    // Var Olan Medyalar Listesi
                    VStack(spacing: 8) {
                        if mediaList.isEmpty {
                            VStack(spacing: 6) {
                                Image(systemName: "photo.on.rectangle")
                                    .font(.system(size: 32))
                                    .foregroundColor(repo.isDarkMode ? Color(hex: "#A8A29E") : Color(hex: "#78716C"))
                                Text("Projede henüz kayıtlı medya bulunmuyor.")
                                    .font(.system(size: 12))
                                    .foregroundColor(repo.isDarkMode ? Color(hex: "#A8A29E") : Color(hex: "#78716C"))
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 160)
                            .background(repo.isDarkMode ? Color(hex: "#292524") : Color.white)
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(repo.isDarkMode ? Color(hex: "#44403C") : Color(hex: "#D6D1C7"), lineWidth: 1))
                        } else {
                            ScrollView {
                                LazyVStack(spacing: 8) {
                                    ForEach(mediaList) { item in
                                        let isSel = selectedMediaIds.contains(item.id)
                                        HStack(spacing: 10) {
                                            // Selection Toggle Button
                                            Button(action: {
                                                Haptics.light()
                                                if isSel { selectedMediaIds.remove(item.id) }
                                                else { selectedMediaIds.insert(item.id) }
                                            }) {
                                                Image(systemName: isSel ? "checkmark.circle.fill" : "circle")
                                                    .font(.system(size: 18))
                                                    .foregroundColor(isSel ? Color(hex: "#A16207") : Color.gray)
                                            }
                                            .buttonStyle(.plain)

                                            // Thumbnail Preview
                                            if let b64 = item.base64Data, let imgData = Data(base64Encoded: b64), let uiImg = UIImage(data: imgData) {
                                                Image(uiImage: uiImg)
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fill)
                                                    .frame(width: 38, height: 38)
                                                    .clipped()
                                                    .cornerRadius(6)
                                            } else {
                                                ZStack {
                                                    RoundedRectangle(cornerRadius: 6)
                                                        .fill(repo.isDarkMode ? Color(hex: "#38332E") : Color(hex: "#E5E1D8"))
                                                        .frame(width: 38, height: 38)
                                                    Image(systemName: "photo")
                                                        .font(.system(size: 16))
                                                        .foregroundColor(Color.gray)
                                                }
                                            }

                                            // Name & Drive Sync Status
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(item.name)
                                                    .font(.system(size: 12.5, weight: .medium))
                                                    .foregroundColor(repo.isDarkMode ? .white : Color(hex: "#2C1810"))
                                                    .lineLimit(1)

                                                HStack(spacing: 4) {
                                                    if item.driveFileId != nil {
                                                        Image(systemName: "icloud.fill")
                                                            .font(.system(size: 10))
                                                            .foregroundColor(Color(hex: "#10B981"))
                                                        Text("Drive Yedekli")
                                                            .font(.system(size: 10, weight: .semibold))
                                                            .foregroundColor(Color(hex: "#10B981"))
                                                    } else {
                                                        Image(systemName: "icloud.slash")
                                                            .font(.system(size: 10))
                                                            .foregroundColor(Color(hex: "#78716C"))
                                                        Text("Yerel")
                                                            .font(.system(size: 10))
                                                            .foregroundColor(Color(hex: "#78716C"))
                                                    }
                                                }
                                            }

                                            Spacer()

                                            // Delete Button (Permanent deletion from Project & Google Drive)
                                            Button(action: {
                                                Haptics.heavy()
                                                repo.removeMedia(projectId: projectId, mediaId: item.id)
                                                selectedMediaIds.remove(item.id)
                                            }) {
                                                Image(systemName: "trash")
                                                    .font(.system(size: 13))
                                                    .foregroundColor(Color(hex: "#EF4444"))
                                                    .frame(width: 28, height: 28)
                                                    .background(Color(hex: "#EF4444").opacity(0.12))
                                                    .clipShape(Circle())
                                            }
                                            .buttonStyle(.scaleSpring(scale: 0.88))
                                        }
                                        .padding(8)
                                        .background(isSel ? Color(hex: "#A16207").opacity(0.10) : (repo.isDarkMode ? Color(hex: "#292524") : Color.white))
                                        .cornerRadius(10)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(isSel ? Color(hex: "#A16207").opacity(0.5) : (repo.isDarkMode ? Color(hex: "#3D3832") : Color(hex: "#E5E1D8")), lineWidth: 1)
                                        )
                                    }
                                }
                            }
                            .frame(height: 160)
                        }
                    }
                }

                // Action Buttons (1:1 Android)
                VStack(spacing: 8) {
                    Button(action: {
                        Haptics.light()
                        // Attach selected items to target topic or subtopic if specified
                        for mediaId in selectedMediaIds {
                            if let subId = targetSubTopicId, let tId = targetTopicId {
                                repo.toggleMediaAttachmentToSubTopic(projectId: projectId, topicId: tId, subTopicId: subId, mediaId: mediaId)
                            } else if let tId = targetTopicId {
                                repo.toggleMediaAttachmentToTopic(projectId: projectId, topicId: tId, mediaId: mediaId)
                            }
                        }
                        onDismiss()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "paperclip")
                            Text(selectedMediaIds.isEmpty ? "Tamamla" : "\(selectedMediaIds.count) Medya İliştir")
                        }
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Color(hex: "#A16207"))
                        .cornerRadius(10)
                    }
                    .buttonStyle(.scaleSpring(scale: 0.96))

                    Button(action: onDismiss) {
                        Text("Kapat")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(repo.isDarkMode ? Color(hex: "#F5F5F4") : Color(hex: "#2C1810"))
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(repo.isDarkMode ? Color(hex: "#292524") : Color.white)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(repo.isDarkMode ? Color(hex: "#44403C") : Color(hex: "#D6D1C7"), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.scaleSpring(scale: 0.96))
                }
            }
            .padding(18)
            .background(repo.isDarkMode ? Color(hex: "#1E1B18") : Color(hex: "#FAF8F5"))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(repo.isDarkMode ? Color(hex: "#44403C") : Color(hex: "#E2DDD5"), lineWidth: 1.5)
            )
            .shadow(color: Color.black.opacity(0.25), radius: 18, x: 0, y: 8)
            .padding(.horizontal, 16)
        }
    }
}
