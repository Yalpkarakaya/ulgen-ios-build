import SwiftUI

public struct DetailView: View {
    public var projectId: String
    @ObservedObject var repo = ProjectRepository.shared
    @Environment(\.dismiss) private var dismiss

    // Modals
    @State private var showingAddTopic = false
    @State private var showingAddSubTopic = false
    @State private var activeTopicIdForSub: String = ""
    @State private var showingAddItem = false
    @State private var activeSubTopicTuple: (mainId: String, subId: String) = ("", "")
    @State private var showingAddNote = false
    @State private var showingMChat = false
    @State private var showingShare = false
    @State private var showingDeleteConfirm = false

    private var project: Project? {
        repo.projects.first(where: { $0.id == projectId })
    }

    public var body: some View {
        Group {
            if let p = project {
                ZStack(alignment: .bottomTrailing) {
                    AppTheme.bg(isDark: repo.isDarkMode)
                        .ignoresSafeArea()

                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            // MARK: - Project Header Card
                            headerCard(p)

                            // MARK: - Action Buttons Bar (MChat, Note, Share)
                            actionButtonsBar(p)

                            // MARK: - Topics Tree
                            VStack(alignment: .leading, spacing: 14) {
                                HStack {
                                    Text("AŞAMALAR VE GÖREVLER")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(AppTheme.textMuted(isDark: repo.isDarkMode))

                                    Spacer()

                                    Button(action: {
                                        Haptics.light()
                                        showingAddTopic = true
                                    }) {
                                        HStack(spacing: 4) {
                                            Image(systemName: "plus")
                                            Text("Ana Aşama Ekle")
                                        }
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(AppTheme.primary)
                                    }
                                }
                                .padding(.horizontal, 4)

                                ForEach(p.mainTopics) { topic in
                                    mainTopicCard(topic, project: p)
                                }
                            }

                            // MARK: - Engineering Notes Section
                            if !p.notes.isEmpty {
                                notesSection(p)
                            }

                            // MARK: - Danger Zone
                            Button(action: {
                                showingDeleteConfirm = true
                            }) {
                                HStack {
                                    Image(systemName: "trash")
                                    Text("Projeyi Çöp Kutusuna Taşı")
                                }
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(Color(hex: "#EF4444"))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color(hex: "#EF4444").opacity(0.1))
                                .cornerRadius(10)
                            }
                            .padding(.top, 16)
                            .padding(.bottom, 64)
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                    }

                    // Floating MChat AI Button
                    Button(action: {
                        Haptics.light()
                        showingMChat = true
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "sparkles")
                            Text("MChat AI")
                        }
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            LinearGradient(
                                colors: [AppTheme.primaryStart, AppTheme.primaryEnd],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(Capsule())
                        .shadow(color: AppTheme.primary.opacity(0.4), radius: 8, x: 0, y: 4)
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 20)
                }
                .navigationTitle(p.title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Menu {
                            Button(action: { repo.toggleArchive(id: p.id) }) {
                                Label(p.archived ? "Arşivden Çıkar" : "Arşive Taşı", systemImage: "archivebox")
                            }
                            Button(action: { repo.togglePin(id: p.id) }) {
                                Label(p.pinned ? "Sabitlemeyi Kaldır" : "Başa Sabitle", systemImage: "pin")
                            }
                            Button(action: { showingShare = true }) {
                                Label("Paylaş & Rapor Al", systemImage: "square.and.arrow.up")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .font(.system(size: 18))
                                .foregroundColor(AppTheme.primary)
                        }
                    }
                }
                .sheet(isPresented: $showingAddTopic) {
                    AddTopicSheet(projectId: p.id)
                }
                .sheet(isPresented: $showingAddSubTopic) {
                    AddSubTopicSheet(projectId: p.id, mainTopicId: activeTopicIdForSub)
                }
                .sheet(isPresented: $showingAddItem) {
                    AddItemSheet(projectId: p.id, mainTopicId: activeSubTopicTuple.mainId, subTopicId: activeSubTopicTuple.subId)
                }
                .sheet(isPresented: $showingAddNote) {
                    AddNoteSheet(projectId: p.id)
                }
                .sheet(isPresented: $showingMChat) {
                    MChatView(projectId: p.id)
                }
                .sheet(isPresented: $showingShare) {
                    ExportShareView(project: p)
                }
                .alert("Projeyi Sil", isPresented: $showingDeleteConfirm) {
                    Button("İptal", role: .cancel) { }
                    Button("Çöp Kutusuna Taşı", role: .destructive) {
                        repo.deleteProject(id: p.id)
                        dismiss()
                    }
                } message: {
                    Text("Bu proje çöp kutusuna taşınacak. Daha sonra kurtarabilir veya kalıcı olarak silebilirsiniz.")
                }
            } else {
                Text("Proje bulunamadı")
                    .foregroundColor(AppTheme.textMuted(isDark: repo.isDarkMode))
            }
        }
    }

    // MARK: - Header Card
    private func headerCard(_ p: Project) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(p.category)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(AppTheme.primary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(AppTheme.primary.opacity(0.12))
                    .cornerRadius(6)

                Spacer()

                Text("%\(p.progress) Tamamlandı")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(AppTheme.primary)
            }

            if !p.description.isEmpty {
                Text(p.description)
                    .font(.system(size: 14))
                    .foregroundColor(AppTheme.textBody(isDark: repo.isDarkMode))
            }

            // Progress meter
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(repo.isDarkMode ? Color.white.opacity(0.1) : Color.black.opacity(0.06))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [AppTheme.primaryStart, AppTheme.primaryEnd],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(0, min(geo.size.width * CGFloat(p.progress) / 100, geo.size.width)), height: 8)
                }
            }
            .frame(height: 8)
        }
        .padding(16)
        .neumorphicCard(isDark: repo.isDarkMode)
    }

    // MARK: - Action Buttons Bar
    private func actionButtonsBar(_ p: Project) -> some View {
        HStack(spacing: 10) {
            actionButton(icon: "sparkles", title: "MChat AI", color: AppTheme.primary) {
                showingMChat = true
            }
            actionButton(icon: "note.text.badge.plus", title: "Not Ekle", color: AppTheme.primary) {
                showingAddNote = true
            }
            actionButton(icon: "square.and.arrow.up", title: "Rapor Al", color: AppTheme.primary) {
                showingShare = true
            }
        }
    }

    private func actionButton(icon: String, title: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: {
            Haptics.light()
            action()
        }) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 13))
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundColor(color)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(color.opacity(0.12))
            .cornerRadius(8)
        }
    }

    // MARK: - Main Topic Card
    private func mainTopicCard(_ topic: MainTopic, project: Project) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(topic.title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(AppTheme.textHeading(isDark: repo.isDarkMode))

                Spacer()

                if topic.completed {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(AppTheme.primary)
                }

                Button(action: {
                    activeTopicIdForSub = topic.id
                    showingAddSubTopic = true
                }) {
                    Image(systemName: "plus.circle")
                        .font(.system(size: 15))
                        .foregroundColor(AppTheme.primary)
                }
            }

            if !topic.description.isEmpty {
                Text(topic.description)
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.textMuted(isDark: repo.isDarkMode))
            }

            Divider().background(AppTheme.border(isDark: repo.isDarkMode))

            // SubTopics
            if topic.subTopics.isEmpty {
                Text("Henüz alt başlık eklenmedi.")
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.textMuted(isDark: repo.isDarkMode))
                    .padding(.vertical, 4)
            } else {
                ForEach(topic.subTopics) { sub in
                    subTopicSection(sub, topic: topic, project: project)
                }
            }
        }
        .padding(14)
        .neumorphicCard(isDark: repo.isDarkMode)
    }

    // MARK: - Sub Topic Section
    private func subTopicSection(_ sub: SubTopic, topic: MainTopic, project: Project) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(sub.title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(AppTheme.primary)

                Spacer()

                Button(action: {
                    activeSubTopicTuple = (mainId: topic.id, subId: sub.id)
                    showingAddItem = true
                }) {
                    HStack(spacing: 3) {
                        Image(systemName: "plus")
                        Text("Görev Ekle")
                    }
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(AppTheme.primary)
                }
            }

            // Items List
            ForEach(sub.items) { item in
                itemRow(item, sub: sub, topic: topic, project: project)
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Item Row with Full Quantity Stepper (-10, -5, -1, +1, +5, +10)
    private func itemRow(_ item: Item, sub: SubTopic, topic: MainTopic, project: Project) -> some View {
        HStack(alignment: .center, spacing: 10) {
            // Checkbox
            Button(action: {
                repo.toggleItem(
                    projectId: project.id,
                    topicId: topic.id,
                    subTopicId: sub.id,
                    itemId: item.id
                )
            }) {
                Image(systemName: item.completed ? "checkmark.square.fill" : "square")
                    .font(.system(size: 18))
                    .foregroundColor(item.completed ? AppTheme.primary : AppTheme.textMuted(isDark: repo.isDarkMode))
            }

            // Title
            VStack(alignment: .leading, spacing: 2) {
                Text(item.displayTitle)
                    .font(.system(size: 14, weight: item.completed ? .regular : .medium))
                    .foregroundColor(item.completed ? AppTheme.textMuted(isDark: repo.isDarkMode) : AppTheme.textHeading(isDark: repo.isDarkMode))
                    .strikethrough(item.completed)
            }

            Spacer()

            // Quantity Counter Stepper
            HStack(spacing: 4) {
                Button("-5") {
                    repo.adjustItemQuantity(projectId: project.id, topicId: topic.id, subTopicId: sub.id, itemId: item.id, delta: -5)
                }
                .buttonStyle(QuantityStepButtonStyle(isDark: repo.isDarkMode))

                Button("-1") {
                    repo.adjustItemQuantity(projectId: project.id, topicId: topic.id, subTopicId: sub.id, itemId: item.id, delta: -1)
                }
                .buttonStyle(QuantityStepButtonStyle(isDark: repo.isDarkMode))

                Text("\(item.quantity)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(AppTheme.textHeading(isDark: repo.isDarkMode))
                    .frame(minWidth: 24)

                Button("+1") {
                    repo.adjustItemQuantity(projectId: project.id, topicId: topic.id, subTopicId: sub.id, itemId: item.id, delta: 1)
                }
                .buttonStyle(QuantityStepButtonStyle(isDark: repo.isDarkMode))

                Button("+5") {
                    repo.adjustItemQuantity(projectId: project.id, topicId: topic.id, subTopicId: sub.id, itemId: item.id, delta: 5)
                }
                .buttonStyle(QuantityStepButtonStyle(isDark: repo.isDarkMode))
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Notes Section
    private func notesSection(_ p: Project) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("MÜHENDİSLİK NOTLARI")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(AppTheme.textMuted(isDark: repo.isDarkMode))
                .padding(.horizontal, 4)

            ForEach(p.notes) { note in
                VStack(alignment: .leading, spacing: 4) {
                    Text(note.content)
                        .font(.system(size: 13))
                        .foregroundColor(AppTheme.textBody(isDark: repo.isDarkMode))
                    Text(Date(timeIntervalSince1970: Double(note.createdAt) / 1000).formatted())
                        .font(.system(size: 10))
                        .foregroundColor(AppTheme.textMuted(isDark: repo.isDarkMode))
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .neumorphicCard(isDark: repo.isDarkMode)
            }
        }
    }
}
