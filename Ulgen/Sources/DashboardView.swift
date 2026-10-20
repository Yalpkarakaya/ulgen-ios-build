import SwiftUI

public struct DashboardView: View {
    @ObservedObject var repo = ProjectRepository.shared
    @State private var isDrawerOpen = false
    @State private var showingAddModal = false
    @State private var showingNotifPanel = false
    @State private var selectedDrawerDestination: String? = nil

    // Sheets
    @State private var showingProfile = false
    @State private var showingArchive = false
    @State private var showingTrash = false
    @State private var showingAdmin = false
    @State private var sharingProject: Project? = nil

    private let categories = ["Tümü", "Donanım", "Gömülü", "Yazılım", "RF & Mikrodalga", "Güç Elektroniği", "Tasarım", "Diğer"]

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
                                        ProjectCardView(project: project, isDark: repo.isDarkMode) {
                                            self.sharingProject = project
                                        }
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                        .padding(.bottom, 88)
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

                // MARK: - Side Navigation Drawer
                SideDrawer(isOpen: $isDrawerOpen) { dest in
                    switch dest {
                    case "archive": showingArchive = true
                    case "trash": showingTrash = true
                    case "profile": showingProfile = true
                    case "admin": showingAdmin = true
                    default: break
                    }
                }
            }
            .sheet(isPresented: $showingAddModal) {
                AddNewView()
            }
            .sheet(isPresented: $showingNotifPanel) {
                NotificationPanel()
            }
            .sheet(isPresented: $showingProfile) {
                ProfileView()
            }
            .sheet(isPresented: $showingArchive) {
                ArchiveView()
            }
            .sheet(isPresented: $showingTrash) {
                TrashView()
            }
            .sheet(isPresented: $showingAdmin) {
                AdminView()
            }
            .sheet(item: $sharingProject) { p in
                ExportShareView(project: p)
            }
        }
    }

    // MARK: - Header
    private var headerSection: some View {
        HStack(alignment: .center, spacing: 10) {
            // Menu Button
            Button(action: {
                Haptics.light()
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    isDrawerOpen.toggle()
                }
            }) {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(AppTheme.textHeading(isDark: repo.isDarkMode))
                    .frame(width: 38, height: 38)
                    .background(AppTheme.card(isDark: repo.isDarkMode))
                    .clipShape(Circle())
                    .overlay(Circle().stroke(AppTheme.border(isDark: repo.isDarkMode), lineWidth: 1))
            }

            // Title & Count Badge
            HStack(spacing: 8) {
                Text("Ülgen")
                    .font(.system(size: 24, weight: .bold, design: .serif))
                    .foregroundColor(AppTheme.primary)

                Text("\(repo.filteredProjects.count) proje")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(AppTheme.textMuted(isDark: repo.isDarkMode))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(AppTheme.card(isDark: repo.isDarkMode))
                    .cornerRadius(8)
            }

            Spacer()

            // Dark Mode Toggle
            Button(action: {
                repo.isDarkMode.toggle()
                Haptics.light()
            }) {
                Image(systemName: repo.isDarkMode ? "moon.fill" : "sun.max.fill")
                    .font(.system(size: 16))
                    .foregroundColor(AppTheme.textHeading(isDark: repo.isDarkMode))
                    .frame(width: 38, height: 38)
                    .background(AppTheme.card(isDark: repo.isDarkMode))
                    .clipShape(Circle())
                    .overlay(Circle().stroke(AppTheme.border(isDark: repo.isDarkMode), lineWidth: 1))
            }

            // Notifications Bell
            Button(action: {
                Haptics.light()
                showingNotifPanel = true
            }) {
                Image(systemName: "bell.fill")
                    .font(.system(size: 16))
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
            // Search Input & Sort Menu
            HStack(spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(AppTheme.textMuted(isDark: repo.isDarkMode))

                    TextField("Proje veya parça ara...", text: $repo.searchQuery)
                        .font(.system(size: 14))
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
                .cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(AppTheme.border(isDark: repo.isDarkMode), lineWidth: 1))

                // Sort Menu
                Menu {
                    Button("İsim (A-Z)") { repo.sortBy = "name_asc" }
                    Button("İlerleme (% Yüksek)") { repo.sortBy = "progress_desc" }
                    Button("Öncelik") { repo.sortBy = "priority_desc" }
                    Button("Son Değiştirilenler") { repo.sortBy = "lastUpdated_desc" }
                } label: {
                    Image(systemName: "arrow.up.arrow.down")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(AppTheme.textHeading(isDark: repo.isDarkMode))
                        .frame(width: 38, height: 38)
                        .background(AppTheme.card(isDark: repo.isDarkMode))
                        .cornerRadius(10)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(AppTheme.border(isDark: repo.isDarkMode), lineWidth: 1))
                }
            }
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
                                .font(.system(size: 12, weight: isSelected ? .bold : .medium))
                                .foregroundColor(isSelected ? .white : AppTheme.textBody(isDark: repo.isDarkMode))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 6)
                                .background(isSelected ? AppTheme.primary : AppTheme.card(isDark: repo.isDarkMode))
                                .cornerRadius(18)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 18)
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

            Text("Proje Bulunmuyor")
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(AppTheme.textHeading(isDark: repo.isDarkMode))

            Text("Seçili filtreye uygun proje bulunamadı veya henüz eklenmedi.")
                .font(.system(size: 13))
                .foregroundColor(AppTheme.textMuted(isDark: repo.isDarkMode))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            Button(action: {
                showingAddModal = true
            }) {
                Text("+ Yeni Proje Oluştur")
                    .font(.system(size: 14, weight: .semibold))
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
    public var onShare: () -> Void

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Badges & Action Row
            HStack {
                Text(project.category)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(AppTheme.primary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(AppTheme.primary.opacity(0.12))
                    .cornerRadius(6)

                priorityBadge(project.priority)

                Spacer()

                // Share Button
                Button(action: onShare) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 13))
                        .foregroundColor(AppTheme.textMuted(isDark: isDark))
                }

                // Pin Button
                Button(action: {
                    ProjectRepository.shared.togglePin(id: project.id)
                }) {
                    Image(systemName: project.pinned ? "pin.fill" : "pin")
                        .font(.system(size: 14))
                        .foregroundColor(project.pinned ? Color(hex: "#F59E0B") : AppTheme.textMuted(isDark: isDark))
                }
                .padding(.leading, 6)
            }

            // Title
            Text(project.title)
                .font(.system(size: 16, weight: .bold))
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
                        .font(.system(size: 11))
                        .foregroundColor(AppTheme.textMuted(isDark: isDark))
                    Spacer()
                    Text("%\(project.progress)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(AppTheme.primary)
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(isDark ? Color.white.opacity(0.1) : Color.black.opacity(0.06))
                            .frame(height: 6)

                        RoundedRectangle(cornerRadius: 3)
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

            // Footer
            HStack {
                let itemCount = project.mainTopics.reduce(0) { acc, t in
                    acc + t.subTopics.reduce(0) { subAcc, s in subAcc + s.items.count }
                }
                let completedCount = project.mainTopics.reduce(0) { acc, t in
                    acc + t.subTopics.reduce(0) { subAcc, s in subAcc + s.items.filter { $0.completed }.count }
                }

                Text("\(completedCount)/\(itemCount) görev tamamlandı")
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
