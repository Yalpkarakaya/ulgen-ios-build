import SwiftUI

public struct MediaManagerModal: View {
    public var projectId: String
    public var targetTitle: String = "1. Temel Kotlin ve Modern Android Mimarisi"
    public var onDismiss: () -> Void = {}
    
    @ObservedObject var repo = ProjectRepository.shared
    @State private var activeTab: String = "upload" // "existing" or "upload"
    @State private var selectedMediaIds: Set<String> = []

    private var project: Project? {
        repo.projects.first(where: { $0.id == projectId })
    }

    private var mediaList: [MediaItem] {
        project?.media ?? []
    }

    public init(projectId: String, targetTitle: String = "1. Temel Kotlin ve Modern Android Mimarisi", onDismiss: @escaping () -> Void = {}) {
        self.projectId = projectId
        self.targetTitle = targetTitle
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

                        Text("Ana Konu: \(targetTitle)")
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
                        Text("Var Olan Medyalar")
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
                    // Upload Drop Area Card (1:1 Android)
                    VStack(spacing: 10) {
                        Image(systemName: "icloud.and.arrow.up.fill")
                            .font(.system(size: 38))
                            .foregroundColor(Color(hex: "#A16207"))

                        Text("Dosyaları Yükle")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(repo.isDarkMode ? Color(hex: "#F5F5F4") : Color(hex: "#2C1810"))

                        Text("Dosya seçmek için tıklayın")
                            .font(.system(size: 12))
                            .foregroundColor(repo.isDarkMode ? Color(hex: "#A8A29E") : Color(hex: "#78716C"))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 150)
                    .background(repo.isDarkMode ? Color(hex: "#292524") : Color.white)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                repo.isDarkMode ? Color(hex: "#44403C") : Color(hex: "#D6D1C7"),
                                style: StrokeStyle(lineWidth: 1.5, dash: [6, 4])
                            )
                    )
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
                            .frame(height: 150)
                            .background(repo.isDarkMode ? Color(hex: "#292524") : Color.white)
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(repo.isDarkMode ? Color(hex: "#44403C") : Color(hex: "#D6D1C7"), lineWidth: 1))
                        } else {
                            ScrollView {
                                LazyVStack(spacing: 6) {
                                    ForEach(mediaList) { item in
                                        let isSel = selectedMediaIds.contains(item.id)
                                        Button(action: {
                                            if isSel { selectedMediaIds.remove(item.id) }
                                            else { selectedMediaIds.insert(item.id) }
                                        }) {
                                            HStack(spacing: 8) {
                                                Image(systemName: isSel ? "checkmark.circle.fill" : "circle")
                                                    .foregroundColor(isSel ? Color(hex: "#A16207") : Color.gray)
                                                Text(item.name)
                                                    .font(.system(size: 12, weight: .medium))
                                                    .foregroundColor(repo.isDarkMode ? .white : Color(hex: "#2C1810"))
                                                    .lineLimit(1)
                                                Spacer()
                                            }
                                            .padding(10)
                                            .background(isSel ? Color(hex: "#A16207").opacity(0.12) : (repo.isDarkMode ? Color(hex: "#292524") : Color.white))
                                            .cornerRadius(8)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                            .frame(height: 150)
                        }
                    }
                }

                // Action Buttons (1:1 Android)
                VStack(spacing: 8) {
                    Button(action: {
                        Haptics.light()
                        onDismiss()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "paperclip")
                            Text("İliştir")
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
