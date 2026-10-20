import SwiftUI

public struct MediaManagerModal: View {
    public var projectId: String
    @ObservedObject var repo = ProjectRepository.shared
    @Environment(\.dismiss) private var dismiss

    @State private var showingAddLink = false
    @State private var linkTitle: String = ""
    @State private var linkUrl: String = ""
    @State private var selectedMedia: MediaItem? = nil

    private var project: Project? {
        repo.projects.first(where: { $0.id == projectId })
    }

    private var mediaList: [MediaItem] {
        project?.media ?? []
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.bg(isDark: repo.isDarkMode).ignoresSafeArea()

                if mediaList.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "paperclip")
                            .font(.system(size: 40))
                            .foregroundColor(AppTheme.textMuted(isDark: repo.isDarkMode))
                        Text("Medya veya Dosya Yok")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(AppTheme.textHeading(isDark: repo.isDarkMode))
                        Text("Devre şeması, PDF dokümanları veya bağlantılar ekleyebilirsiniz.")
                            .font(.system(size: 13))
                            .foregroundColor(AppTheme.textMuted(isDark: repo.isDarkMode))

                        Button(action: { showingAddLink = true }) {
                            HStack(spacing: 6) {
                                Image(systemName: "link.badge.plus")
                                Text("Bağlantı / Doküman Ekle")
                            }
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(AppTheme.primary)
                            .cornerRadius(10)
                        }
                        .padding(.top, 8)
                    }
                    .padding(24)
                } else {
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                            ForEach(mediaList) { item in
                                mediaCard(item)
                            }
                        }
                        .padding(16)
                    }
                }
            }
            .navigationTitle("Medyalar ve Çizimler")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Kapat") { dismiss() }
                        .foregroundColor(AppTheme.primary)
                        .buttonStyle(.scaleSpring(scale: 0.92))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: { showingAddLink = true }) {
                        Image(systemName: "plus")
                    }
                    .foregroundColor(AppTheme.primary)
                    .buttonStyle(.scaleSpring(scale: 0.88))
                }
            }
            .sheet(isPresented: $showingAddLink) {
                NavigationStack {
                    ZStack {
                        AppTheme.bg(isDark: repo.isDarkMode).ignoresSafeArea()
                        VStack(spacing: 16) {
                            TextField("Başlık (Örn: Altium Şematik PDF)", text: $linkTitle)
                                .font(.system(size: 15))
                                .padding(12)
                                .background(AppTheme.card(isDark: repo.isDarkMode))
                                .cornerRadius(10)
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(AppTheme.borderSubtle(isDark: repo.isDarkMode), lineWidth: 1))

                            TextField("URL veya Dosya Yolu", text: $linkUrl)
                                .font(.system(size: 15))
                                .padding(12)
                                .background(AppTheme.card(isDark: repo.isDarkMode))
                                .cornerRadius(10)
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(AppTheme.borderSubtle(isDark: repo.isDarkMode), lineWidth: 1))

                            Spacer()
                        }
                        .padding(20)
                    }
                    .navigationTitle("Yeni Medya / Bağlantı")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("İptal") { showingAddLink = false }
                                .buttonStyle(.scaleSpring(scale: 0.92))
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Ekle") {
                                guard let pIdx = repo.projects.firstIndex(where: { $0.id == projectId }),
                                      !linkTitle.isEmpty else { return }
                                let newMedia = MediaItem(
                                    uri: linkUrl,
                                    mimeType: "application/pdf",
                                    name: linkTitle
                                )
                                repo.projects[pIdx].media.append(newMedia)
                                repo.saveLocalData()
                                showingAddLink = false
                            }
                            .disabled(linkTitle.isEmpty)
                            .buttonStyle(.scaleSpring(scale: 0.92))
                        }
                    }
                }
            }
        }
    }

    private func mediaCard(_ item: MediaItem) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(repo.isDarkMode ? Color.white.opacity(0.06) : Color.black.opacity(0.04))
                    .frame(height: 100)

                Image(systemName: item.mimeType.contains("image") ? "photo" : (item.mimeType.contains("video") ? "video" : "doc.text"))
                    .font(.system(size: 32))
                    .foregroundColor(AppTheme.primary)
            }

            Text(item.name.isEmpty ? "Ek Dosya" : item.name)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(AppTheme.textHeading(isDark: repo.isDarkMode))
                .lineLimit(1)

            Text(item.mimeType.uppercased())
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(AppTheme.textMuted(isDark: repo.isDarkMode))
        }
        .padding(12)
        .neumorphicCard(isDark: repo.isDarkMode)
    }
}
