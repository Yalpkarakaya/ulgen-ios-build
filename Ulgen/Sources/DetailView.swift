import SwiftUI

public struct DetailView: View {
    public var projectId: String
    @ObservedObject var repo = ProjectRepository.shared
    @Environment(\.dismiss) private var dismiss

    // Modals & Sheets
    @State private var showingEditProject = false
    @State private var showingAddTopic = false
    @State private var showingAddSubTopic = false
    @State private var activeTopicIdForSub: String = ""
    @State private var showingAddItem = false
    @State private var activeSubTopicTuple: (mainId: String, subId: String) = ("", "")
    @State private var showingAddNote = false
    @State private var showingMChat = false
    @State private var showingShare = false
    @State private var showingMediaManager = false
    @State private var showingDeleteConfirm = false
    @State private var newNoteText: String = ""

    // Topic Accordions State
    @State private var expandedTopics: [String: Bool] = [:]

    private var project: Project? {
        repo.projects.first(where: { $0.id == projectId })
    }

    public var body: some View {
        Group {
            if let p = project {
                ZStack(alignment: .bottom) {
                    AppTheme.bg(isDark: repo.isDarkMode)
                        .ignoresSafeArea()

                    ScrollView {
                        VStack(alignment: .leading, spacing: 14) {
                            // MARK: - 1. Project Summary Header Card
                            projectSummaryCard(p)

                            // MARK: - 2. Topics Header & Add Button
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
                                        Image(systemName: "plus.circle.fill")
                                        Text("Ana Aşama Ekle")
                                    }
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(AppTheme.primary)
                                }
                                .buttonStyle(.scaleSpring(scale: 0.94))
                            }
                            .padding(.horizontal, 4)
                            .padding(.top, 4)

                            // MARK: - 3. 3-Level Topics Hierarchy (MainTopic -> SubTopic -> Item)
                            if p.mainTopics.isEmpty {
                                emptyTopicsCard
                            } else {
                                ForEach(p.mainTopics) { topic in
                                    mainTopicAccordionCard(topic, project: p)
                                }
                            }

                            // MARK: - 4. Engineering Notes ("Notlarım") Card
                            notesCard(p)

                            Spacer().frame(height: 80)
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                    }

                    // MARK: - Fixed Bottom AI Roadmap & MChat Bar
                    bottomActionBar(p)
                }
                .navigationTitle(p.title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Menu {
                            Button(action: { showingMChat = true }) {
                                Label("MChat AI Asistanı", systemImage: "sparkles")
                            }
                            Button(action: { showingMediaManager = true }) {
                                Label("Medyalar & Çizimler", systemImage: "paperclip")
                            }
                            Button(action: { showingShare = true }) {
                                Label("Rapor Al & Paylaş", systemImage: "square.and.arrow.up")
                            }
                            Button(action: { repo.togglePin(id: p.id) }) {
                                Label(p.pinned ? "Sabitlemeyi Kaldır" : "Başa Sabitle", systemImage: "pin")
                            }
                            Button(action: { repo.toggleArchive(id: p.id) }) {
                                Label(p.archived ? "Arşivden Çıkar" : "Arşive Taşı", systemImage: "archivebox")
                            }
                            Divider()
                            Button(role: .destructive, action: { showingDeleteConfirm = true }) {
                                Label("Projeyi Çöp Kutusuna Taşı", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .font(.system(size: 18, weight: .semibold))
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
                .sheet(isPresented: $showingMChat) {
                    MChatView(projectId: p.id)
                }
                .sheet(isPresented: $showingShare) {
                    ExportShareView(project: p)
                }
                .sheet(isPresented: $showingMediaManager) {
                    MediaManagerModal(projectId: p.id)
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

    // MARK: - Project Summary Header Card
    private func projectSummaryCard(_ p: Project) -> some View {
        let (completedTasks, totalTasks) = countTasks(p)
        let isCompleted = (p.progress == 100) && (totalTasks == 0 || completedTasks == totalTasks)

        return VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center) {
                CategoryVectorIconView(categoryId: p.category, isDarkMode: repo.isDarkMode)

                VStack(alignment: .leading, spacing: 2) {
                    Text(p.category.capitalized)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(AppTheme.primary)

                    Text(p.title)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(AppTheme.textHeading(isDark: repo.isDarkMode))
                }

                Spacer()

                PrioritySignalBarsView(priority: p.priority, isDarkMode: repo.isDarkMode)
            }

            if !p.description.isEmpty {
                Text(p.description)
                    .font(.system(size: 13))
                    .foregroundColor(AppTheme.textBody(isDark: repo.isDarkMode))
            }

            // Progress Bar
            VStack(spacing: 4) {
                HStack {
                    Text("Tamamlanma Oranı")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(AppTheme.textMuted(isDark: repo.isDarkMode))
                    Spacer()
                    Text("%\(p.progress)")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(AppTheme.textHeading(isDark: repo.isDarkMode))
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(repo.isDarkMode ? Color.black.opacity(0.4) : Color(hex: "#EAEBE6"))
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: isCompleted ? [Color(hex: "#10B981"), Color(hex: "#059669")] : [AppTheme.primaryStart, AppTheme.primaryEnd],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: max(0, min(geo.size.width * CGFloat(p.progress) / 100.0, geo.size.width)))
                    }
                }
                .frame(height: 8)
            }

            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.system(size: 11))
                    Text(p.deadline ?? "Bitiş Tarihi Yok")
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundColor(AppTheme.textMuted(isDark: repo.isDarkMode))

                Spacer()

                Text("\(completedTasks)/\(totalTasks) görev tamamlandı")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(isCompleted ? Color(hex: "#10B981") : AppTheme.textMuted(isDark: repo.isDarkMode))
            }
        }
        .padding(16)
        .neumorphicCard(isDark: repo.isDarkMode)
    }

    // MARK: - Main Topic Accordion Card (Level 1)
    private func mainTopicAccordionCard(_ topic: MainTopic, project: Project) -> some View {
        let isExpanded = expandedTopics[topic.id] ?? true
        let (topicDone, topicTotal) = countTopicTasks(topic)
        let topicPercent = topicTotal > 0 ? Int(Double(topicDone) / Double(topicTotal) * 100) : 0

        return VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack(spacing: 10) {
                // Expand / Collapse Chevron
                Button(action: {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        expandedTopics[topic.id] = !isExpanded
                    }
                }) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(AppTheme.primary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .buttonStyle(.scaleSpring(scale: 0.88))

                // Title
                VStack(alignment: .leading, spacing: 2) {
                    Text(topic.title)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(AppTheme.textHeading(isDark: repo.isDarkMode))

                    if !topic.description.isEmpty {
                        Text(topic.description)
                            .font(.system(size: 12))
                            .foregroundColor(AppTheme.textMuted(isDark: repo.isDarkMode))
                            .lineLimit(1)
                    }
                }

                Spacer()

                // Percentage Badge Circle (%22)
                Text("%\(topicPercent)")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(topicPercent == 100 ? Color(hex: "#10B981") : AppTheme.primary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background((topicPercent == 100 ? Color(hex: "#10B981") : AppTheme.primary).opacity(0.12))
                    .cornerRadius(8)

                // Add SubTopic Button
                Button(action: {
                    activeTopicIdForSub = topic.id
                    showingAddSubTopic = true
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(AppTheme.primary)
                        .frame(width: 28, height: 28)
                        .background(AppTheme.primary.opacity(0.1))
                        .clipShape(Circle())
                }
                .buttonStyle(.scaleSpring(scale: 0.88))

                // Delete Topic Button
                Button(action: {
                    repo.deleteMainTopic(projectId: project.id, topicId: topic.id)
                }) {
                    Image(systemName: "trash")
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.textMuted(isDark: repo.isDarkMode))
                }
                .buttonStyle(.scaleSpring(scale: 0.88))
            }
            .padding(14)

            // SubTopics List (Level 2)
            if isExpanded {
                VStack(spacing: 10) {
                    if topic.subTopics.isEmpty {
                        Text("Henüz alt başlık eklenmedi. '+' butonuna basarak ekleyin.")
                            .font(.system(size: 12))
                            .foregroundColor(AppTheme.textMuted(isDark: repo.isDarkMode))
                            .padding(.horizontal, 14)
                            .padding(.bottom, 12)
                    } else {
                        ForEach(topic.subTopics) { sub in
                            subTopicCard(sub, topic: topic, project: project)
                        }
                    }
                }
                .padding(.horizontal, 10)
                .padding(.bottom, 12)
            }
        }
        .neumorphicCard(isDark: repo.isDarkMode)
    }

    // MARK: - SubTopic Card (Level 2)
    private func subTopicCard(_ sub: SubTopic, topic: MainTopic, project: Project) -> some View {
        let subDone = sub.items.filter { $0.completed }.count
        let subTotal = sub.items.count

        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(sub.title)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(AppTheme.primary)

                Spacer()

                Text("\(subDone)/\(subTotal)")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(AppTheme.textMuted(isDark: repo.isDarkMode))

                // Add Item Button
                Button(action: {
                    activeSubTopicTuple = (mainId: topic.id, subId: sub.id)
                    showingAddItem = true
                }) {
                    HStack(spacing: 3) {
                        Image(systemName: "plus")
                        Text("Madde")
                    }
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(AppTheme.primary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(AppTheme.primary.opacity(0.12))
                    .cornerRadius(6)
                }
                .buttonStyle(.scaleSpring(scale: 0.92))

                // Delete SubTopic
                Button(action: {
                    repo.deleteSubTopic(projectId: project.id, mainTopicId: topic.id, subTopicId: sub.id)
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 11))
                        .foregroundColor(AppTheme.textMuted(isDark: repo.isDarkMode))
                }
                .buttonStyle(.scaleSpring(scale: 0.88))
            }

            // Items List (Level 3)
            ForEach(sub.items) { item in
                itemRow(item, sub: sub, topic: topic, project: project)
            }
        }
        .padding(10)
        .background(repo.isDarkMode ? Color(hex: "#1E2024") : Color(hex: "#F8F6F2"))
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppTheme.borderSubtle(isDark: repo.isDarkMode), lineWidth: 1))
    }

    // MARK: - Item Row (Level 3: Green strikethrough when completed 1:1)
    private func itemRow(_ item: Item, sub: SubTopic, topic: MainTopic, project: Project) -> some View {
        HStack(spacing: 10) {
            // Checkbox Circle
            Button(action: {
                Haptics.light()
                repo.toggleItem(
                    projectId: project.id,
                    topicId: topic.id,
                    subTopicId: sub.id,
                    itemId: item.id
                )
            }) {
                Image(systemName: item.completed ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 18))
                    .foregroundColor(item.completed ? Color(hex: "#10B981") : AppTheme.textMuted(isDark: repo.isDarkMode))
            }
            .buttonStyle(.scaleSpring(scale: 0.88))

            // Title with Strikethrough
            Text(item.title)
                .font(.system(size: 13, weight: item.completed ? .regular : .medium))
                .strikethrough(item.completed, color: AppTheme.textMuted(isDark: repo.isDarkMode))
                .foregroundColor(item.completed ? AppTheme.textMuted(isDark: repo.isDarkMode) : AppTheme.textHeading(isDark: repo.isDarkMode))
                .lineLimit(2)

            Spacer()

            // Quantity Stepper
            HStack(spacing: 4) {
                Button(action: {
                    repo.updateItemQuantity(projectId: project.id, topicId: topic.id, subTopicId: sub.id, itemId: item.id, delta: -1)
                }) {
                    Text("-")
                        .font(.system(size: 11, weight: .bold))
                        .frame(width: 20, height: 20)
                        .background(repo.isDarkMode ? Color.white.opacity(0.08) : Color.black.opacity(0.05))
                        .cornerRadius(4)
                }
                .buttonStyle(.scaleSpring(scale: 0.88))

                Text("\(item.quantity)")
                    .font(.system(size: 12, weight: .semibold))
                    .frame(minWidth: 16)

                Button(action: {
                    repo.updateItemQuantity(projectId: project.id, topicId: topic.id, subTopicId: sub.id, itemId: item.id, delta: 1)
                }) {
                    Text("+")
                        .font(.system(size: 11, weight: .bold))
                        .frame(width: 20, height: 20)
                        .background(repo.isDarkMode ? Color.white.opacity(0.08) : Color.black.opacity(0.05))
                        .cornerRadius(4)
                }
                .buttonStyle(.scaleSpring(scale: 0.88))
            }
            .foregroundColor(AppTheme.textHeading(isDark: repo.isDarkMode))

            // Delete Item
            Button(action: {
                repo.deleteItem(projectId: project.id, topicId: topic.id, subTopicId: sub.id, itemId: item.id)
            }) {
                Image(systemName: "trash")
                    .font(.system(size: 11))
                    .foregroundColor(AppTheme.textMuted(isDark: repo.isDarkMode).opacity(0.6))
            }
            .buttonStyle(.scaleSpring(scale: 0.88))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(item.completed ? (repo.isDarkMode ? Color(hex: "#14241C") : Color(hex: "#F0FDF4")) : Color.clear)
        .cornerRadius(8)
    }

    // MARK: - Engineering Notes Card
    private func notesCard(_ p: Project) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("NOTLARIM")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(AppTheme.textMuted(isDark: repo.isDarkMode))

            // Note Input
            HStack(spacing: 8) {
                TextField("Yeni bir mühendislik notu ekle...", text: $newNoteText)
                    .font(.system(size: 13))
                    .foregroundColor(AppTheme.textBody(isDark: repo.isDarkMode))
                    .padding(10)
                    .background(repo.isDarkMode ? Color(hex: "#1E1B18") : Color.white)
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppTheme.borderSubtle(isDark: repo.isDarkMode), lineWidth: 1))

                Button("Not Ekle") {
                    guard !newNoteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                    Haptics.light()
                    repo.addNote(projectId: p.id, content: newNoteText)
                    newNoteText = ""
                }
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(newNoteText.isEmpty ? Color.gray.opacity(0.4) : AppTheme.primary)
                .cornerRadius(8)
                .disabled(newNoteText.isEmpty)
                .buttonStyle(.scaleSpring(scale: 0.94))
            }

            // Notes List
            ForEach(p.notes) { note in
                HStack(alignment: .top) {
                    Text(note.content)
                        .font(.system(size: 13))
                        .foregroundColor(AppTheme.textBody(isDark: repo.isDarkMode))

                    Spacer()

                    Button(action: {
                        repo.deleteNote(projectId: p.id, noteId: note.id)
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 11))
                            .foregroundColor(AppTheme.textMuted(isDark: repo.isDarkMode))
                    }
                    .buttonStyle(.scaleSpring(scale: 0.88))
                }
                .padding(10)
                .background(repo.isDarkMode ? Color(hex: "#1E1B18") : Color(hex: "#FAF8F5"))
                .cornerRadius(8)
            }
        }
        .padding(14)
        .neumorphicCard(isDark: repo.isDarkMode)
    }

    // MARK: - Bottom Action Bar
    private func bottomActionBar(_ p: Project) -> some View {
        HStack(spacing: 12) {
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
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: [AppTheme.primaryStart, AppTheme.primaryEnd],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(14)
                .shadow(color: AppTheme.primary.opacity(0.35), radius: 6, x: 0, y: 3)
            }
            .buttonStyle(.scaleSpring(scale: 0.96))

            Button(action: {
                Haptics.light()
                showingMediaManager = true
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "paperclip")
                    Text("Medyalar (\(p.media.count))")
                }
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(AppTheme.textHeading(isDark: repo.isDarkMode))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(AppTheme.card(isDark: repo.isDarkMode))
                .cornerRadius(14)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(AppTheme.borderSubtle(isDark: repo.isDarkMode), lineWidth: 1))
                .shadow(color: repo.isDarkMode ? Color.black.opacity(0.3) : Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
            }
            .buttonStyle(.scaleSpring(scale: 0.96))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background((repo.isDarkMode ? Color(hex: "#1E1B18") : Color(hex: "#FAF8F5")).opacity(0.95))
        .overlay(Rectangle().frame(height: 1).foregroundColor(AppTheme.borderSubtle(isDark: repo.isDarkMode)), alignment: .top)
    }

    private var emptyTopicsCard: some View {
        VStack(spacing: 8) {
            Image(systemName: "list.bullet.indent")
                .font(.system(size: 32))
                .foregroundColor(AppTheme.textMuted(isDark: repo.isDarkMode))
            Text("Henüz aşama eklenmemiş")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(AppTheme.textHeading(isDark: repo.isDarkMode))
            Text("Projenizi aşamalara ve görevlere bölmek için yukarıdaki '+' butonunu kullanın.")
                .font(.system(size: 12))
                .foregroundColor(AppTheme.textMuted(isDark: repo.isDarkMode))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .neumorphicCard(isDark: repo.isDarkMode)
    }

    private func countTasks(_ p: Project) -> (completed: Int, total: Int) {
        var completed = 0
        var total = 0
        for t in p.mainTopics {
            for s in t.subTopics {
                for i in s.items {
                    total += 1
                    if i.completed { completed += 1 }
                }
            }
        }
        return (completed, total)
    }

    private func countTopicTasks(_ t: MainTopic) -> (completed: Int, total: Int) {
        var completed = 0
        var total = 0
        for s in t.subTopics {
            for i in s.items {
                total += 1
                if i.completed { completed += 1 }
            }
        }
        return (completed, total)
    }
}
