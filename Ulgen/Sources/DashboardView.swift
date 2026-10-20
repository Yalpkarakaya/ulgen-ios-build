import SwiftUI

public struct DashboardView: View {
    @ObservedObject var repo = ProjectRepository.shared
    @State private var showingAddModal = false
    @State private var showingDrawer = false
    @State private var showingProfile = false

    private let categories = ["Tümü", "Donanım", "Gömülü", "Yazılım", "Tasarım", "Diğer"]

    public var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                AppTheme.bg(isDark: repo.isDarkMode)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // MARK: - Top Header (MainActivity / DashboardScreen paritesi)
                    headerSection

                    // MARK: - Search & Filters
                    searchAndFiltersSection

                    // MARK: - Projects List
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            if repo.filteredProjects.isEmpty {
                                emptyStateCard
                            } else {
                                ForEach(repo.filteredProjects) { project in
                                    NavigationLink(destination: DetailView(projectId: project.id)) {
                                        ProjectCardView(project: project, isDark: repo.isDarkMode)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                        .padding(.bottom, 88) // FAB için alt boşluk
                    }
                }

                // MARK: - Floating Action Button (FAB)
                Button(action: {
                    Haptics.light()
                    showingAddModal = true
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 58, height: 58)
                        .background(
                            LinearGradient(
                                colors: [AppTheme.primaryStart, AppTheme.primaryEnd],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(Circle())
                        .shadow(color: AppTheme.primary.opacity(0.4), radius: 8, x: 0, y: 4)
                }
                .padding(.trailing, 20)
                .padding(.bottom, 24)
            }
            .sheet(isPresented: $showingAddModal) {
                AddNewView()
            }
            .sheet(isPresented: $showingProfile) {
                ProfileView()
            }
        }
    }

    // MARK: - Header
    private var headerSection: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 8) {
                    Text("Ülgen")
                        .font(.system(size: 24, weight: .bold, design: .serif))
                        .foregroundColor(AppTheme.primary)

                    Text("\(repo.filteredProjects.count) proje")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(AppTheme.textMuted(isDark: repo.isDarkMode))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(AppTheme.card(isDark: repo.isDarkMode))
                        .cornerRadius(10)
                }
            }

            Spacer()

            // Dark Mode Toggle
            Button(action: {
                repo.isDarkMode.toggle()
                Haptics.light()
            }) {
                Image(systemName: repo.isDarkMode ? "moon.fill" : "sun.max.fill")
                    .font(.system(size: 17))
                    .foregroundColor(AppTheme.textHeading(isDark: repo.isDarkMode))
                    .frame(width: 38, height: 38)
                    .background(AppTheme.card(isDark: repo.isDarkMode))
                    .clipShape(Circle())
                    .overlay(Circle().stroke(AppTheme.border(isDark: repo.isDarkMode), lineWidth: 1))
            }

            // Profile / Sync Settings
            Button(action: {
                Haptics.light()
                showingProfile = true
            }) {
                Image(systemName: "person.crop.circle")
                    .font(.system(size: 20))
                    .foregroundColor(AppTheme.textHeading(isDark: repo.isDarkMode))
                    .frame(width: 38, height: 38)
                    .background(AppTheme.card(isDark: repo.isDarkMode))
                    .clipShape(Circle())
                    .overlay(Circle().stroke(AppTheme.border(isDark: repo.isDarkMode), lineWidth: 1))
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }

    // MARK: - Search & Filters
    private var searchAndFiltersSection: some View {
        VStack(spacing: 10) {
            // Search Input
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(AppTheme.textMuted(isDark: repo.isDarkMode))

                TextField("Proje veya parça ara...", text: $repo.searchQuery)
                    .font(.system(size: 15))
                    .foregroundColor(AppTheme.textBody(isDark: repo.isDarkMode))

                if !repo.searchQuery.isEmpty {
                    Button(action: { repo.searchQuery = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(AppTheme.textMuted(isDark: repo.isDarkMode))
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(AppTheme.card(isDark: repo.isDarkMode))
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppTheme.border(isDark: repo.isDarkMode), lineWidth: 1))
            .padding(.horizontal, 16)

            // Category Chips Scroll
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(categories, id: \.self) { cat in
                        let isSelected = repo.activeCategory == cat
                        Button(action: {
                            repo.activeCategory = cat
                            Haptics.light()
                        }) {
                            Text(cat)
                                .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                                .foregroundColor(isSelected ? .white : AppTheme.textBody(isDark: repo.isDarkMode))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 6)
                                .background(isSelected ? AppTheme.primary : AppTheme.card(isDark: repo.isDarkMode))
                                .cornerRadius(20)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(isSelected ? AppTheme.primary : AppTheme.border(isDark: repo.isDarkMode), lineWidth: 1)
                                )
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
        }
        .padding(.bottom, 6)
    }

    // MARK: - Empty State
    private var emptyStateCard: some View {
        VStack(spacing: 12) {
            Image(systemName: "folder.badge.plus")
                .font(.system(size: 40))
                .foregroundColor(AppTheme.primary.opacity(0.8))

            Text("Kayıtlı Proje Bulunmuyor")
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(AppTheme.textHeading(isDark: repo.isDarkMode))

            Text("Yeni bir elektronik veya yazılım projesi ekleyerek başlayabilirsiniz.")
                .font(.system(size: 14))
                .foregroundColor(AppTheme.textMuted(isDark: repo.isDarkMode))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            Button(action: {
                showingAddModal = true
            }) {
                Text("+ Proje Oluştur")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(AppTheme.primary)
                    .cornerRadius(10)
            }
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .neumorphicCard(isDark: repo.isDarkMode)
    }
}

// MARK: - Project Card View (DashboardScreen.kt Paritesi)
public struct ProjectCardView: View {
    public var project: Project
    public var isDark: Bool

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Badges Row
            HStack {
                // Category Badge
                Text(project.category)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(AppTheme.primary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(AppTheme.primary.opacity(0.12))
                    .cornerRadius(6)

                // Priority Badge
                priorityBadge(project.priority)

                Spacer()

                // Pin Button
                Button(action: {
                    ProjectRepository.shared.togglePin(id: project.id)
                }) {
                    Image(systemName: project.pinned ? "pin.fill" : "pin")
                        .font(.system(size: 14))
                        .foregroundColor(project.pinned ? Color(hex: "#F59E0B") : AppTheme.textMuted(isDark: isDark))
                }
            }

            // Title
            Text(project.title)
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(AppTheme.textHeading(isDark: isDark))
                .lineLimit(1)

            // Description
            if !project.description.isEmpty {
                Text(project.description)
                    .font(.system(size: 13))
                    .foregroundColor(AppTheme.textBody(isDark: isDark))
                    .lineLimit(2)
            }

            // Progress Bar
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("İlerleme")
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.textMuted(isDark: isDark))
                    Spacer()
                    Text("%\(project.progress)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(AppTheme.primary)
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(isDark ? Color.white.opacity(0.1) : Color.black.opacity(0.06))
                            .frame(height: 6)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: [AppTheme.primaryStart, AppTheme.primaryEnd],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: max(0, min(geo.size.width * CGFloat(project.progress) / 100, geo.size.width)), height: 6)
                    }
                }
                .frame(height: 6)
            }

            // Footer Info
            HStack {
                let itemCount = project.mainTopics.reduce(0) { acc, t in
                    acc + t.subTopics.reduce(0) { subAcc, s in subAcc + s.items.count }
                }
                let completedCount = project.mainTopics.reduce(0) { acc, t in
                    acc + t.subTopics.reduce(0) { subAcc, s in subAcc + s.items.filter { $0.completed }.count }
                }

                Text("\(completedCount)/\(itemCount) görev")
                    .font(.system(size: 11))
                    .foregroundColor(AppTheme.textMuted(isDark: isDark))

                Spacer()

                Text("Detaylar →")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(AppTheme.primary)
            }
            .padding(.top, 2)
        }
        .padding(14)
        .neumorphicCard(isDark: isDark)
    }

    private func priorityBadge(_ p: String) -> some View {
        let (label, color): (String, Color) = {
            switch p.lowercased() {
            case "high": return ("Yüksek", AppTheme.priorityHigh)
            case "medium": return ("Orta", AppTheme.priorityMedium)
            default: return ("Düşük", AppTheme.priorityLow)
            }
        }()

        return Text(label)
            .font(.system(size: 11, weight: .medium))
            .foregroundColor(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.12))
            .cornerRadius(4)
    }
}
