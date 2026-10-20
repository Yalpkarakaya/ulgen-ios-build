import SwiftUI

public struct DetailView: View {
    public var projectId: String
    @ObservedObject var repo = ProjectRepository.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showingDeleteConfirm = false

    private var project: Project? {
        repo.projects.first(where: { $0.id == projectId })
    }

    public var body: some View {
        Group {
            if let p = project {
                ZStack {
                    AppTheme.bg(isDark: repo.isDarkMode)
                        .ignoresSafeArea()

                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            // MARK: - Project Header Card
                            headerCard(p)

                            // MARK: - Topics Tree
                            VStack(alignment: .leading, spacing: 14) {
                                Text("AŞAMALAR VE GÖREVLER")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(AppTheme.textMuted(isDark: repo.isDarkMode))
                                    .padding(.horizontal, 4)

                                ForEach(p.mainTopics) { topic in
                                    mainTopicCard(topic, project: p)
                                }
                            }

                            // MARK: - Danger Zone
                            Button(action: {
                                showingDeleteConfirm = true
                            }) {
                                HStack {
                                    Image(systemName: "trash")
                                    Text("Projeyi Sil")
                                }
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Color(hex: "#EF4444"))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color(hex: "#EF4444").opacity(0.1))
                                .cornerRadius(12)
                            }
                            .padding(.top, 16)
                            .padding(.bottom, 32)
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                    }
                }
                .navigationTitle(p.title)
                .navigationBarTitleDisplayMode(.inline)
                .alert("Projeyi Sil", isPresented: $showingDeleteConfirm) {
                    Button("İptal", role: .cancel) { }
                    Button("Sil", role: .destructive) {
                        repo.deleteProject(id: p.id)
                        dismiss()
                    }
                } message: {
                    Text("Bu projeyi ve tüm görevlerini silmek istediğinize emin misiniz?")
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
            }

            if !topic.description.isEmpty {
                Text(topic.description)
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.textMuted(isDark: repo.isDarkMode))
            }

            Divider()
                .background(AppTheme.border(isDark: repo.isDarkMode))

            // SubTopics
            ForEach(topic.subTopics) { sub in
                subTopicSection(sub, topic: topic, project: project)
            }
        }
        .padding(14)
        .neumorphicCard(isDark: repo.isDarkMode)
    }

    // MARK: - Sub Topic Section
    private func subTopicSection(_ sub: SubTopic, topic: MainTopic, project: Project) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(sub.title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(AppTheme.primary)

            // Items List
            ForEach(sub.items) { item in
                itemRow(item, sub: sub, topic: topic, project: project)
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Item Row with Quantity Counter Stepper
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

            // Quantity Counter Stepper (-5, -1, Qty, +1, +5)
            HStack(spacing: 4) {
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
}

// MARK: - Stepper Button Style
struct QuantityStepButtonStyle: ButtonStyle {
    var isDark: Bool
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(AppTheme.textHeading(isDark: isDark))
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(isDark ? Color.white.opacity(0.08) : Color.black.opacity(0.04))
            .cornerRadius(4)
            .opacity(configuration.isPressed ? 0.7 : 1.0)
    }
}
