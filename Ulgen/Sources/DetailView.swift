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
    @State private var showingMChat = false
    @State private var showingShare = false
    @State private var showingMediaManager = false
    @State private var activeMediaTargetTitle: String = "Proje Geneli"
    @State private var activeMediaTopicId: String? = nil
    @State private var activeMediaSubTopicId: String? = nil
    @State private var showingDeleteConfirm = false
    @State private var newNoteText: String = ""

    // Topic Accordions State
    @State private var expandedTopics: [String: Bool] = [:]

    private var project: Project? {
        repo.projects.first(where: { $0.id == projectId })
    }

    public init(projectId: String, initialModal: String = "") {
        self.projectId = projectId
        if initialModal == "media" {
            _showingMediaManager = State(initialValue: true)
        } else if initialModal == "mchat" {
            _showingMChat = State(initialValue: true)
        }
    }

    public var body: some View {
        Group {
            if let p = project {
                ZStack(alignment: .bottomLeading) {
                    AppTheme.bg(isDark: repo.isDarkMode)
                        .ignoresSafeArea()

                    ScrollView {
                        VStack(alignment: .leading, spacing: 14) {
                            // MARK: - 1. Progress Header Capsule Card (1:1 Android)
                            progressHeaderCard(p)

                            // MARK: - 2. Topics Hierarchy Cards (1:1 Android)
                            ForEach(Array(p.mainTopics.enumerated()), id: \.element.id) { index, topic in
                                mainTopicCard(topic, index: index + 1, project: p)
                            }

                            // MARK: - 3. Solid Navy "+ Başlık Ekle" Button (1:1 Android)
                            Button(action: {
                                Haptics.light()
                                showingAddTopic = true
                            }) {
                                HStack {
                                    Spacer()
                                    Text("+ Başlık Ekle")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.white)
                                    Spacer()
                                }
                                .frame(height: 48)
                                .background(repo.isDarkMode ? Color(hex: "#26272B") : Color(hex: "#1E293B"))
                                .cornerRadius(12)
                            }
                            .buttonStyle(.scaleSpring(scale: 0.96))

                            // MARK: - 4. Engineering Notes ("Notlarım") Card (1:1 Android)
                            notesCard(p)

                            Spacer().frame(height: 90)
                        }
                        .padding(.horizontal, 14)
                        .padding(.top, 12)
                    }

                    // MARK: - 5. Bottom-Left Floating "Yol Haritası" FAB (1:1 Android)
                    Button(action: {
                        Haptics.light()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "book.fill")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(AppTheme.textHeading(isDark: repo.isDarkMode))
                            Text("Yol Haritası")
                                .font(.system(size: 13.5, weight: .bold))
                                .foregroundColor(AppTheme.textHeading(isDark: repo.isDarkMode))
                        }
                        .padding(.horizontal, 16)
                        .frame(height: 46)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(repo.isDarkMode ? Color(hex: "#26272B").opacity(0.92) : Color(hex: "#FAF8F5").opacity(0.92))
                                .shadow(color: Color.black.opacity(0.14), radius: 8, x: 0, y: 4)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(repo.isDarkMode ? Color(hex: "#44403C") : Color(hex: "#E2DDD5"), lineWidth: 1.2)
                        )
                    }
                    .buttonStyle(.scaleSpring(scale: 0.94))
                    .padding(.leading, 14)
                    .padding(.bottom, 24)

                    // Overlay Modals
                    if showingMediaManager {
                        MediaManagerModal(
                            projectId: p.id,
                            targetTitle: activeMediaTargetTitle,
                            targetTopicId: activeMediaTopicId,
                            targetSubTopicId: activeMediaSubTopicId,
                            onDismiss: {
                                showingMediaManager = false
                            }
                        )
                    }

                    if showingMChat {
                        MChatView(projectId: p.id, onDismiss: {
                            showingMChat = false
                        })
                    }
                }
                .navigationTitle(p.title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Menu {
                            Button(action: {
                                activeMediaTargetTitle = "Proje Geneli"
                                activeMediaTopicId = nil
                                activeMediaSubTopicId = nil
                                showingMediaManager = true
                            }) {
                                Label("Medya İliştir", systemImage: "paperclip")
                            }
                            Button(action: { showingMChat = true }) {
                                Label("AI Medya Sohbetleri", systemImage: "bubble.left.and.bubble.right")
                            }
                            Button(action: { showingShare = true }) {
                                Label("Paylaş", systemImage: "square.and.arrow.up")
                            }
                            Divider()
                            Button(role: .destructive, action: { showingDeleteConfirm = true }) {
                                Label("Projeyi Sil", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(AppTheme.textHeading(isDark: repo.isDarkMode))
                                .frame(width: 32, height: 32)
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
                .sheet(isPresented: $showingShare) {
                    ExportShareView(project: p)
                }
                .alert("Projeyi Sil", isPresented: $showingDeleteConfirm) {
                    Button("Sil", role: .destructive) {
                        Haptics.heavy()
                        repo.deleteProject(id: p.id)
                        dismiss()
                    }
                    Button("İptal", role: .cancel) {}
                } message: {
                    Text("Bu projeyi çöp kutusuna taşımak istediğinizden emin misiniz?")
                }
            } else {
                Text("Proje bulunamadı")
                    .foregroundColor(AppTheme.textMuted(isDark: repo.isDarkMode))
            }
        }
    }

    // MARK: - Progress Header Card (1:1 Android)
    private func progressHeaderCard(_ p: Project) -> some View {
        let (completedTasks, totalTasks) = countTasks(p)

        return HStack(spacing: 12) {
            Text("\(completedTasks) / \(totalTasks) Görevler")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(AppTheme.textHeading(isDark: repo.isDarkMode))
                .frame(width: 120, alignment: .leading)

            // Progress capsule
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(repo.isDarkMode ? Color.white.opacity(0.12) : Color(hex: "#E5E1D8"))
                    Capsule()
                        .fill(Color(hex: "#0D9488")) // Turkuaz primary
                        .frame(width: max(0, min(geo.size.width * CGFloat(p.progress) / 100.0, geo.size.width)))
                }
            }
            .frame(height: 7)

            Text("%\(p.progress)")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(AppTheme.textHeading(isDark: repo.isDarkMode))
                .frame(width: 42, alignment: .trailing)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .background(repo.isDarkMode ? Color(hex: "#22201D") : Color(hex: "#FAF8F5"))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(repo.isDarkMode ? Color(hex: "#38332E") : Color(hex: "#E6E1D8"), lineWidth: 1)
        )
    }

    // MARK: - Main Topic Card (1:1 Android TopicCard)
    private func mainTopicCard(_ topic: MainTopic, index: Int, project: Project) -> some View {
        let isExpanded = expandedTopics[topic.id] ?? (index > 1) // default open topic 2 for subtopic preview
        let (topicDone, topicTotal) = countTopicTasks(topic)
        let isDone = (topicTotal > 0 && topicDone == topicTotal)
        let percent = topicTotal > 0 ? Int(Double(topicDone) / Double(topicTotal) * 100) : 0

        return VStack(alignment: .leading, spacing: 10) {
            // Header Row
            HStack(alignment: .top, spacing: 10) {
                // Topic Index / Status Badge
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isDone ? Color(hex: "#10B981") : Color(hex: "#8A4B1A"))
                        .frame(width: 36, height: 36)

                    if isDone {
                        Image(systemName: "checkmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                    } else {
                        Text("\(index)")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                    }
                }

                // Title & Description
                VStack(alignment: .leading, spacing: 2) {
                    Text(topic.title)
                        .font(.system(size: 14.5, weight: .bold))
                        .foregroundColor(AppTheme.textHeading(isDark: repo.isDarkMode))

                    if !topic.description.isEmpty {
                        Text(topic.description)
                            .font(.system(size: 12))
                            .foregroundColor(AppTheme.textMuted(isDark: repo.isDarkMode))
                            .lineLimit(2)
                    }
                }
                .onTapGesture {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        expandedTopics[topic.id] = !isExpanded
                    }
                }

                Spacer()

                // Percentage Badge & Actions
                HStack(spacing: 6) {
                    // Percent Pill
                    Text("\(percent)%")
                        .font(.system(size: 10.5, weight: .bold))
                        .foregroundColor(isDone ? Color(hex: "#10B981") : Color(hex: "#8A4B1A"))
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .stroke(isDone ? Color(hex: "#10B981") : Color(hex: "#8A4B1A"), lineWidth: 1.5)
                        )

                    // Paperclip
                    Button(action: {
                        Haptics.light()
                        activeMediaTargetTitle = "Ana Konu: \(topic.title)"
                        activeMediaTopicId = topic.id
                        activeMediaSubTopicId = nil
                        showingMediaManager = true
                    }) {
                        Image(systemName: "paperclip")
                            .font(.system(size: 14))
                            .foregroundColor(topic.attachedMedia.isEmpty ? (repo.isDarkMode ? Color(hex: "#A8A29E") : Color(hex: "#78716C")) : Color(hex: "#A16207"))
                            .frame(width: 24, height: 24)
                    }

                    // Pen Edit
                    Button(action: {
                        Haptics.light()
                    }) {
                        Image(systemName: "pencil")
                            .font(.system(size: 14))
                            .foregroundColor(repo.isDarkMode ? Color(hex: "#A8A29E") : Color(hex: "#78716C"))
                            .frame(width: 24, height: 24)
                    }

                    // Drag Dots
                    Image(systemName: "circle.grid.2x2.fill")
                        .font(.system(size: 12))
                        .foregroundColor(repo.isDarkMode ? Color(hex: "#6B7280") : Color(hex: "#9CA3AF"))
                        .frame(width: 20, height: 24)
                }
            }

            // Attached Media Thumbnails Row
            if !topic.attachedMedia.isEmpty {
                let attachedItems = project.media.filter { topic.attachedMedia.contains($0.id) }
                if !attachedItems.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(attachedItems) { m in
                                HStack(spacing: 4) {
                                    if let b64 = m.base64Data, let imgData = Data(base64Encoded: b64), let uiImg = UIImage(data: imgData) {
                                        Image(uiImage: uiImg)
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 22, height: 22)
                                            .cornerRadius(4)
                                    } else {
                                        Image(systemName: "paperclip")
                                            .font(.system(size: 10))
                                            .foregroundColor(Color(hex: "#A16207"))
                                    }
                                    Text(m.name)
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(AppTheme.textHeading(isDark: repo.isDarkMode))
                                        .lineLimit(1)
                                }
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(repo.isDarkMode ? Color(hex: "#2E2A26") : Color(hex: "#F5EFE6"))
                                .cornerRadius(6)
                            }
                        }
                    }
                    .padding(.top, 2)
                }
            }

            // SubTopics List (when expanded)
            if isExpanded && !topic.subTopics.isEmpty {
                VStack(spacing: 8) {
                    ForEach(topic.subTopics) { sub in
                        subTopicItemView(sub, topic: topic, project: project)
                    }

                    // Dashed "+ Alt Başlık Ekle" Button (1:1 Android)
                    Button(action: {
                        Haptics.light()
                        activeTopicIdForSub = topic.id
                        showingAddSubTopic = true
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "plus")
                                .font(.system(size: 12, weight: .bold))
                            Text("Alt Başlık Ekle")
                                .font(.system(size: 12.5, weight: .bold))
                        }
                        .foregroundColor(Color(hex: "#B45309"))
                        .frame(maxWidth: .infinity)
                        .frame(height: 38)
                        .background(repo.isDarkMode ? Color(hex: "#26221D") : Color(hex: "#FFFBEB"))
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color(hex: "#F59E0B").opacity(0.4), style: StrokeStyle(lineWidth: 1.2, dash: [4, 3]))
                        )
                    }
                    .buttonStyle(.scaleSpring(scale: 0.96))
                }
                .padding(.top, 4)
            }
        }
        .padding(14)
        .background(repo.isDarkMode ? Color(hex: "#22201D") : Color(hex: "#FAF8F5"))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(repo.isDarkMode ? Color(hex: "#38332E") : Color(hex: "#E6E1D8"), lineWidth: 1)
        )
    }

    // MARK: - SubTopic Item View (1:1 Android SubTopicItem)
    private func subTopicItemView(_ sub: SubTopic, topic: MainTopic, project: Project) -> some View {
        let subDone = sub.items.filter { $0.completed }.count
        let subTotal = sub.items.count
        let allCompleted = (subTotal > 0 && subDone == subTotal)
        let percent = subTotal > 0 ? Int(Double(subDone) / Double(subTotal) * 100) : 0

        return VStack(alignment: .leading, spacing: 8) {
            // SubTopic Header
            HStack(spacing: 8) {
                // Checkbox Circle
                Button(action: {
                    Haptics.light()
                    repo.toggleSubTopic(projectId: project.id, mainTopicId: topic.id, subTopicId: sub.id)
                }) {
                    ZStack {
                        Circle()
                            .stroke(allCompleted ? Color(hex: "#10B981") : (repo.isDarkMode ? Color(hex: "#6B7280") : Color(hex: "#9CA3AF")), lineWidth: 1.5)
                            .frame(width: 20, height: 20)

                        if allCompleted {
                            Circle()
                                .fill(Color(hex: "#10B981"))
                                .frame(width: 20, height: 20)
                            Image(systemName: "checkmark")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                }
                .buttonStyle(.scaleSpring(scale: 0.88))

                // Title with chevron
                HStack(spacing: 4) {
                    Text(sub.title)
                        .font(.system(size: 13.5, weight: .bold))
                        .strikethrough(allCompleted, color: Color.gray)
                        .foregroundColor(allCompleted ? AppTheme.textMuted(isDark: repo.isDarkMode) : AppTheme.textHeading(isDark: repo.isDarkMode))
                        .lineLimit(1)

                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(repo.isDarkMode ? Color(hex: "#A8A29E") : Color(hex: "#78716C"))
                }

                Spacer()

                // Badge %
                Text("\(percent)%")
                    .font(.system(size: 9.5, weight: .bold))
                    .foregroundColor(allCompleted ? Color(hex: "#10B981") : Color(hex: "#8A4B1A"))
                    .frame(width: 26, height: 26)
                    .background(
                        Circle().stroke(allCompleted ? Color(hex: "#10B981") : Color(hex: "#8A4B1A").opacity(0.4), lineWidth: 1)
                    )

                // Paperclip
                Button(action: {
                    Haptics.light()
                    activeMediaTargetTitle = "Alt Konu: \(sub.title)"
                    activeMediaTopicId = topic.id
                    activeMediaSubTopicId = sub.id
                    showingMediaManager = true
                }) {
                    Image(systemName: "paperclip")
                        .font(.system(size: 12))
                        .foregroundColor(sub.attachedMedia.isEmpty ? (repo.isDarkMode ? Color(hex: "#A8A29E") : Color(hex: "#78716C")) : Color(hex: "#A16207"))
                }

                // Pen
                Image(systemName: "pencil")
                    .font(.system(size: 12))
                    .foregroundColor(repo.isDarkMode ? Color(hex: "#A8A29E") : Color(hex: "#78716C"))

                // Dots
                Image(systemName: "circle.grid.2x2.fill")
                    .font(.system(size: 10))
                    .foregroundColor(repo.isDarkMode ? Color(hex: "#6B7280") : Color(hex: "#9CA3AF"))
            }

            // SubTopic Attached Media Thumbnails
            if !sub.attachedMedia.isEmpty {
                let attachedItems = project.media.filter { sub.attachedMedia.contains($0.id) }
                if !attachedItems.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 5) {
                            ForEach(attachedItems) { m in
                                HStack(spacing: 4) {
                                    if let b64 = m.base64Data, let imgData = Data(base64Encoded: b64), let uiImg = UIImage(data: imgData) {
                                        Image(uiImage: uiImg)
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 18, height: 18)
                                            .cornerRadius(3)
                                    } else {
                                        Image(systemName: "paperclip")
                                            .font(.system(size: 9))
                                            .foregroundColor(Color(hex: "#A16207"))
                                    }
                                    Text(m.name)
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundColor(AppTheme.textHeading(isDark: repo.isDarkMode))
                                        .lineLimit(1)
                                }
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(repo.isDarkMode ? Color(hex: "#332F2A") : Color(hex: "#EFECE6"))
                                .cornerRadius(5)
                            }
                        }
                    }
                }
            }

            // Items List (Clean Task Checkboxes - NO Quantity Steppers!)
            if !sub.items.isEmpty {
                VStack(spacing: 6) {
                    ForEach(sub.items) { item in
                        itemRow(item, sub: sub, topic: topic, project: project)
                    }
                }
                .padding(.top, 2)
            }
        }
        .padding(10)
        .background(repo.isDarkMode ? Color(hex: "#282522") : Color.white)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(repo.isDarkMode ? Color(hex: "#3D3832") : Color(hex: "#E8E3DA"), lineWidth: 1)
        )
    }

    // MARK: - Task Item Row (Zero +1 -1 Steppers! 1:1 Android)
    private func itemRow(_ item: Item, sub: SubTopic, topic: MainTopic, project: Project) -> some View {
        HStack(spacing: 8) {
            Button(action: {
                Haptics.light()
                repo.toggleItem(
                    projectId: project.id,
                    topicId: topic.id,
                    subTopicId: sub.id,
                    itemId: item.id
                )
            }) {
                ZStack {
                    Circle()
                        .stroke(item.completed ? Color(hex: "#10B981") : (repo.isDarkMode ? Color(hex: "#6B7280") : Color(hex: "#9CA3AF")), lineWidth: 1.5)
                        .frame(width: 17, height: 17)

                    if item.completed {
                        Circle()
                            .fill(Color(hex: "#10B981"))
                            .frame(width: 17, height: 17)
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            .buttonStyle(.scaleSpring(scale: 0.88))

            Text(item.title)
                .font(.system(size: 12.5, weight: item.completed ? .regular : .medium))
                .strikethrough(item.completed, color: AppTheme.textMuted(isDark: repo.isDarkMode))
                .foregroundColor(item.completed ? AppTheme.textMuted(isDark: repo.isDarkMode) : AppTheme.textHeading(isDark: repo.isDarkMode))
                .lineLimit(2)

            Spacer()

            Button(action: {
                repo.deleteItem(projectId: project.id, topicId: topic.id, subTopicId: sub.id, itemId: item.id)
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 10))
                    .foregroundColor(AppTheme.textMuted(isDark: repo.isDarkMode).opacity(0.6))
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
    }

    // MARK: - Engineering Notes Card (1:1 Android)
    private func notesCard(_ p: Project) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "pencil")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(AppTheme.textHeading(isDark: repo.isDarkMode))
                Text("Notlarım")
                    .font(.system(size: 14.5, weight: .bold))
                    .foregroundColor(AppTheme.textHeading(isDark: repo.isDarkMode))
            }

            // Input Row
            HStack(spacing: 8) {
                TextField("Yeni bir not ekle...", text: $newNoteText)
                    .font(.system(size: 13))
                    .padding(10)
                    .background(repo.isDarkMode ? Color(hex: "#262320") : Color.white)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(repo.isDarkMode ? Color(hex: "#3D3832") : Color(hex: "#E0DCD4"), lineWidth: 1)
                    )

                Button(action: {
                    guard !newNoteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                    Haptics.light()
                    repo.addNote(projectId: p.id, content: newNoteText)
                    newNoteText = ""
                }) {
                    Text("Not Ekle")
                        .font(.system(size: 12.5, weight: .bold))
                        .foregroundColor(repo.isDarkMode ? Color(hex: "#FAF8F5") : Color(hex: "#2C1810"))
                        .padding(.horizontal, 14)
                        .frame(height: 38)
                        .background(Color(hex: "#D6C7B2"))
                        .cornerRadius(8)
                }
                .buttonStyle(.scaleSpring(scale: 0.94))
            }

            // Existing Notes
            if !p.notes.isEmpty {
                VStack(spacing: 6) {
                    ForEach(p.notes) { note in
                        HStack {
                            Text(note.content)
                                .font(.system(size: 12.5))
                                .foregroundColor(AppTheme.textBody(isDark: repo.isDarkMode))
                            Spacer()
                            Button(action: {
                                repo.deleteNote(projectId: p.id, noteId: note.id)
                            }) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 10))
                                    .foregroundColor(AppTheme.textMuted(isDark: repo.isDarkMode))
                            }
                        }
                        .padding(8)
                        .background(repo.isDarkMode ? Color(hex: "#262320") : Color.white)
                        .cornerRadius(6)
                    }
                }
            }
        }
        .padding(14)
        .background(repo.isDarkMode ? Color(hex: "#22201D") : Color(hex: "#FAF8F5"))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(repo.isDarkMode ? Color(hex: "#38332E") : Color(hex: "#E6E1D8"), lineWidth: 1)
        )
    }

    // MARK: - Helpers & Modals
    private func countTasks(_ p: Project) -> (completed: Int, total: Int) {
        var completed = 0
        var total = 0
        for topic in p.mainTopics {
            for sub in topic.subTopics {
                total += sub.items.count
                completed += sub.items.filter { $0.completed }.count
            }
        }
        return (completed, total)
    }

    private func countTopicTasks(_ topic: MainTopic) -> (completed: Int, total: Int) {
        var completed = 0
        var total = 0
        for sub in topic.subTopics {
            total += sub.items.count
            completed += sub.items.filter { $0.completed }.count
        }
        return (completed, total)
    }
}
