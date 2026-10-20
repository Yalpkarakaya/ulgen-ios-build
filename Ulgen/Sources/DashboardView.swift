import SwiftUI

public struct DashboardView: View {
    @ObservedObject var repo = ProjectRepository.shared
    @State private var isDrawerOpen = false
    @State private var showingAddModal = false
    @State private var showingNotifPanel = false
    @State private var showingQrModal = false

    // Sheets
    @State private var showingProfile = false
    @State private var showingArchive = false
    @State private var showingTrash = false
    @State private var showingAdmin = false
    @State private var sharingProject: Project? = nil

    // Accordions
    @State private var showSortPanel: Bool = false
    @State private var showFilterPanel: Bool = false

    private let sortOptions: [(id: String, label: String)] = [
        ("custom", "Özel Sıralama (Sürükle & Bırak)"),
        ("alpha_asc", "Alfabetik (A → Z)"),
        ("alpha_desc", "Alfabetik (Z → A)"),
        ("update_desc", "Güncelleme (Yeni → Eski)"),
        ("update_asc", "Güncelleme (Eski → Yeni)"),
        ("priority_asc", "Öncelik (Düşük → Yüksek)"),
        ("priority_desc", "Öncelik (Yüksek → Düşük)"),
        ("deadline_asc", "Bitiş Tarihi (Yakın → Uzak)"),
        ("deadline_asc_rev", "Bitiş Tarihi (Uzak → Yakın)")
    ]

    private let categories: [(id: String, label: String)] = [
        ("all", "Tümü"),
        ("ders", "Ders"),
        ("proje", "Proje"),
        ("mesleki", "Mesleki"),
        ("hobi", "Hobi"),
        ("diger", "Diğer")
    ]

    private let priorities: [(id: String, label: String)] = [
        ("all", "Tümü"),
        ("low", "Düşük"),
        ("normal", "Orta"),
        ("high", "Yüksek"),
        ("urgent", "Acil")
    ]

    public var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                // Background
                AppTheme.bg(isDark: repo.isDarkMode)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // MARK: - 1. DashboardHeader (1:1 with DashboardScreen.kt lines 1444-1520)
                    headerSection

                    // MARK: - 2. Main Scroll Content
                    ScrollView {
                        VStack(spacing: 12) {
                            // Arama Çubuğu (#search-input)
                            searchBarField

                            // Kontrol Satırı (.dashboard-controls): Sıralama Ölçütü ve Filtreler Akordeon Butonları
                            controlsRow

                            // Connected Dual Accordion (1:1 with DashboardScreen.kt lines 750-1070)
                            if showSortPanel || showFilterPanel {
                                accordionContainer
                                    .transition(.opacity.combined(with: .move(edge: .top)))
                            }

                            // Proje Kartları Listesi (Sabitlenenler ve Tüm Projeler 1:1 Parite)
                            if repo.filteredProjects.isEmpty {
                                emptyStateCard
                            } else {
                                let pinnedProjects = repo.filteredProjects.filter { $0.pinned }
                                let unpinnedProjects = repo.filteredProjects.filter { !$0.pinned }

                                LazyVStack(spacing: 12) {
                                    if !pinnedProjects.isEmpty {
                                        sectionHeader(title: "Sabitlenenler", count: pinnedProjects.count, icon: "pin.fill")

                                        ForEach(pinnedProjects) { project in
                                            NavigationLink(destination: DetailView(projectId: project.id)) {
                                                ProjectCardView(project: project, isDark: repo.isDarkMode) {
                                                    self.sharingProject = project
                                                }
                                            }
                                            .buttonStyle(.scaleSpring(scale: 0.985))
                                        }
                                    }

                                    if !unpinnedProjects.isEmpty {
                                        sectionHeader(title: "Tüm Projeler", count: unpinnedProjects.count, icon: nil)

                                        ForEach(unpinnedProjects) { project in
                                            NavigationLink(destination: DetailView(projectId: project.id)) {
                                                ProjectCardView(project: project, isDark: repo.isDarkMode) {
                                                    self.sharingProject = project
                                                }
                                            }
                                            .buttonStyle(.scaleSpring(scale: 0.985))
                                        }
                                    }
                                }

                                // 1:1 Android Alt Arşiv Çekme Droplet (ArchivePullDroplet.kt paritesi)
                                Button(action: {
                                    Haptics.medium()
                                    showingArchive = true
                                }) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "archivebox.fill")
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundColor(AppTheme.primary)

                                        Text("Arşivi açmak için dokunun veya yukarı kaydırın")
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(AppTheme.textMuted(isDark: repo.isDarkMode))

                                        Image(systemName: "chevron.up")
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundColor(AppTheme.primary)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(repo.isDarkMode ? Color(hex: "#1D1E22") : Color(hex: "#F3F1EE"))
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(AppTheme.border(isDark: repo.isDarkMode), lineWidth: 1)
                                    )
                                }
                                .buttonStyle(.scaleSpring(scale: 0.98))
                                .padding(.top, 14)
                                .padding(.bottom, 8)
                                .gesture(
                                    DragGesture(minimumDistance: 20)
                                        .onEnded { value in
                                            if value.translation.height < -25 {
                                                Haptics.medium()
                                                showingArchive = true
                                            }
                                        }
                                )
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 14)
                        .padding(.bottom, 100)
                    }
                    .refreshable {
                        Haptics.light()
                        await repo.syncWithCloud()
                        Haptics.success()
                    }
                }

                // MARK: - Floating Action Button (FAB) (58x58dp)
                fabMenuButton

                // MARK: - Side Navigation Drawer (Opens from RIGHT / .trailing)
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
            .navigationBarHidden(true)
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

    // MARK: - Header (DashboardHeader 1:1)
    private var headerSection: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center) {
                // Sol: "Ülgen" Başlık + "${activeProjectsCount} proje"
                VStack(alignment: .leading, spacing: 2) {
                    Text("Ülgen")
                        .font(.system(size: 26, weight: .bold, design: .serif))
                        .foregroundColor(AppTheme.primaryHeader(isDark: repo.isDarkMode))
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)

                    Text("\(repo.activeProjects.count) proje")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(AppTheme.textMuted(isDark: repo.isDarkMode))
                }

                Spacer()

                // Sağ: Tema, Bildirim ve Menü İkon Butonları (40x40dp Neumorphic Glass)
                HStack(spacing: 8) {
                    // Dark Mode Toggle (1:1 Android HeaderActionIconButton)
                    Button(action: {
                        Haptics.light()
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            repo.isDarkMode.toggle()
                        }
                    }) {
                        Image(systemName: repo.isDarkMode ? "sun.max.fill" : "moon.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(repo.isDarkMode ? Color(hex: "#FDE047") : Color(hex: "#1E293B"))
                            .frame(width: 40, height: 40)
                            .background(repo.isDarkMode ? Color(hex: "#292524") : Color.white)
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(repo.isDarkMode ? Color(hex: "#44403C") : Color(hex: "#E2DDD5"), lineWidth: 1))
                            .shadow(color: repo.isDarkMode ? Color.black.opacity(0.3) : Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
                    }
                    .buttonStyle(.scaleSpring(scale: 0.90))

                    // Notification Bell
                    Button(action: {
                        Haptics.light()
                        showingNotifPanel = true
                    }) {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: "bell.fill")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(repo.isDarkMode ? Color(hex: "#F1F5F9") : Color(hex: "#1E293B"))
                                .frame(width: 40, height: 40)
                                .background(repo.isDarkMode ? Color(hex: "#292524") : Color.white)
                                .cornerRadius(12)
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(repo.isDarkMode ? Color(hex: "#44403C") : Color(hex: "#E2DDD5"), lineWidth: 1))
                                .shadow(color: repo.isDarkMode ? Color.black.opacity(0.3) : Color.black.opacity(0.04), radius: 4, x: 0, y: 2)

                            if !repo.notifications.isEmpty {
                                Circle()
                                    .fill(Color(hex: "#EF4444"))
                                    .frame(width: 8, height: 8)
                                    .offset(x: -6, y: 6)
                            }
                        }
                    }
                    .buttonStyle(.scaleSpring(scale: 0.90))

                    // Hamburger Menu (Opens Side Drawer from RIGHT)
                    Button(action: {
                        Haptics.light()
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            isDrawerOpen.toggle()
                        }
                    }) {
                        Image(systemName: "line.3.horizontal")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(repo.isDarkMode ? Color(hex: "#F1F5F9") : Color(hex: "#1E293B"))
                            .frame(width: 40, height: 40)
                            .background(repo.isDarkMode ? Color(hex: "#292524") : Color.white)
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(repo.isDarkMode ? Color(hex: "#44403C") : Color(hex: "#E2DDD5"), lineWidth: 1))
                            .shadow(color: repo.isDarkMode ? Color.black.opacity(0.3) : Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
                    }
                    .buttonStyle(.scaleSpring(scale: 0.90))
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 12)
            .background(repo.isDarkMode ? AppTheme.cardSurfaceDark : AppTheme.bgLight)

            // Header Alt Çizgisi (1pt Hairline)
            Rectangle()
                .fill(AppTheme.border(isDark: repo.isDarkMode))
                .frame(height: 1)
        }
    }

    // MARK: - Search Bar Field
    private var searchBarField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16))
                .foregroundColor(AppTheme.textMuted(isDark: repo.isDarkMode))

            TextField("Proje veya görev ara...", text: $repo.searchQuery)
                .font(.system(size: 14))
                .foregroundColor(AppTheme.textBody(isDark: repo.isDarkMode))

            if !repo.searchQuery.isEmpty {
                Button(action: { repo.searchQuery = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(AppTheme.textMuted(isDark: repo.isDarkMode))
                }
            }
        }
        .padding(.horizontal, 14)
        .frame(height: 46)
        .background(repo.isDarkMode ? Color(hex: "#1D1E22") : Color(hex: "#F3F1EE"))
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(repo.isDarkMode ? Color(hex: "#2E3036") : Color(hex: "#DCD8D0"), lineWidth: 1))
        .shadow(color: repo.isDarkMode ? Color.black.opacity(0.2) : Color.black.opacity(0.03), radius: 4, x: 0, y: 1)
    }

    // MARK: - Controls Row (Sıralama Ölçütü & Filtreler)
    private var controlsRow: some View {
        HStack(spacing: 8) {
            // Sol: Sıralama Ölçütü Butonu
            Button(action: {
                Haptics.light()
                withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                    showSortPanel.toggle()
                }
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.up.arrow.down")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(showSortPanel || repo.sortOption != "custom" ? AppTheme.textHeading(isDark: repo.isDarkMode) : AppTheme.textMuted(isDark: repo.isDarkMode))

                    Text("Sıralama Ölçütü")
                        .font(.system(size: 13, weight: showSortPanel ? .bold : .semibold))
                        .foregroundColor(showSortPanel || repo.sortOption != "custom" ? AppTheme.textHeading(isDark: repo.isDarkMode) : AppTheme.textBody(isDark: repo.isDarkMode))
                        .lineLimit(1)

                    Spacer()

                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(AppTheme.textMuted(isDark: repo.isDarkMode))
                        .rotationEffect(.degrees(showSortPanel ? 180 : 0))
                }
                .padding(.horizontal, 12)
                .frame(height: 44)
                .background(showSortPanel ? (repo.isDarkMode ? Color(hex: "#26272B") : Color(hex: "#EAE6DF")) : AppTheme.card(isDark: repo.isDarkMode))
                .cornerRadius(16)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(showSortPanel ? (repo.isDarkMode ? Color(hex: "#52545E") : Color(hex: "#8C867B")) : AppTheme.borderSubtle(isDark: repo.isDarkMode), lineWidth: 1))
            }
            .frame(maxWidth: .infinity)
            .buttonStyle(.scaleSpring(scale: 0.97))

            // Sağ: Filtreler Butonu
            let activeFilters = (repo.selectedCategory != "all" ? 1 : 0) + (repo.selectedPriority != "all" ? 1 : 0)
            Button(action: {
                Haptics.light()
                withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                    showFilterPanel.toggle()
                }
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(showFilterPanel || activeFilters > 0 ? AppTheme.textHeading(isDark: repo.isDarkMode) : AppTheme.textMuted(isDark: repo.isDarkMode))

                    Text("Filtreler")
                        .font(.system(size: 13, weight: showFilterPanel ? .bold : .semibold))
                        .foregroundColor(showFilterPanel || activeFilters > 0 ? AppTheme.textHeading(isDark: repo.isDarkMode) : AppTheme.textBody(isDark: repo.isDarkMode))

                    if activeFilters > 0 {
                        Text("\(activeFilters)")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 18, height: 18)
                            .background(AppTheme.primary)
                            .clipShape(Circle())
                    }

                    Spacer()

                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(AppTheme.textMuted(isDark: repo.isDarkMode))
                        .rotationEffect(.degrees(showFilterPanel ? 180 : 0))
                }
                .padding(.horizontal, 12)
                .frame(height: 44)
                .background(showFilterPanel ? (repo.isDarkMode ? Color(hex: "#26272B") : Color(hex: "#EAE6DF")) : AppTheme.card(isDark: repo.isDarkMode))
                .cornerRadius(16)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(showFilterPanel ? (repo.isDarkMode ? Color(hex: "#52545E") : Color(hex: "#8C867B")) : AppTheme.borderSubtle(isDark: repo.isDarkMode), lineWidth: 1))
            }
            .frame(maxWidth: .infinity)
            .buttonStyle(.scaleSpring(scale: 0.97))
        }
    }

    // MARK: - Unified Dual Zipper Accordion Container (1:1 with DashboardScreen.kt)
    private var accordionContainer: some View {
        Group {
            if showSortPanel && showFilterPanel {
                HStack(alignment: .top, spacing: 8) {
                    sortOptionsPanel(isDual: true)
                        .frame(maxWidth: .infinity)
                    filterOptionsPanel(isDual: true)
                        .frame(maxWidth: .infinity)
                }
            } else if showSortPanel {
                sortOptionsPanel(isDual: false)
                    .frame(maxWidth: .infinity)
            } else if showFilterPanel {
                filterOptionsPanel(isDual: false)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(10)
        .background(repo.isDarkMode ? Color(hex: "#1D1E22") : Color(hex: "#F3F1EE"))
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppTheme.border(isDark: repo.isDarkMode), lineWidth: 1))
    }

    // MARK: - Sort Options Panel (2 Columns Layout 1:1)
    private func sortOptionsPanel(isDual: Bool) -> some View {
        VStack(spacing: 4) {
            // Row 0: Custom (Full width)
            sortOptionButton(id: "custom", label: isDual ? "Özel Sıralama" : "Özel Sıralama (Sürükle & Bırak)", isDual: isDual)

            // Row 1: Alpha A-Z & Z-A
            HStack(spacing: 4) {
                sortOptionButton(id: "alpha_asc", label: isDual ? "A → Z" : "Alfabetik (A → Z)", isDual: isDual)
                sortOptionButton(id: "alpha_desc", label: isDual ? "Z → A" : "Alfabetik (Z → A)", isDual: isDual)
            }

            // Row 2: Update Newest & Oldest
            HStack(spacing: 4) {
                sortOptionButton(id: "update_desc", label: isDual ? "Yeni → Eski" : "Güncelleme (Yeni → Eski)", isDual: isDual)
                sortOptionButton(id: "update_asc", label: isDual ? "Eski → Yeni" : "Güncelleme (Eski → Yeni)", isDual: isDual)
            }

            // Row 3: Priority Low & High
            HStack(spacing: 4) {
                sortOptionButton(id: "priority_asc", label: isDual ? "Düşük → Yüksek" : "Öncelik (Düşük → Yüksek)", isDual: isDual)
                sortOptionButton(id: "priority_desc", label: isDual ? "Yüksek → Düşük" : "Öncelik (Yüksek → Düşük)", isDual: isDual)
            }

            // Row 4: Deadline Near & Far
            HStack(spacing: 4) {
                sortOptionButton(id: "deadline_asc", label: isDual ? "Yakın → Uzak" : "Bitiş (Yakın → Uzak)", isDual: isDual)
                sortOptionButton(id: "deadline_asc_rev", label: isDual ? "Uzak → Yakın" : "Bitiş (Uzak → Yakın)", isDual: isDual)
            }
        }
    }

    private func sortOptionButton(id: String, label: String, isDual: Bool) -> some View {
        let isSelected = repo.sortOption == id
        return Button(action: {
            Haptics.light()
            repo.sortOption = id
        }) {
            Text(label)
                .font(.system(size: isDual ? 10.5 : 12, weight: isSelected ? .bold : .medium))
                .foregroundColor(isSelected ? (repo.isDarkMode ? Color(hex: "#111215") : .white) : AppTheme.textBody(isDark: repo.isDarkMode))
                .lineLimit(1)
                .frame(maxWidth: .infinity)
                .frame(height: 30)
                .background(isSelected ? (repo.isDarkMode ? Color(hex: "#E4E4E7") : Color(hex: "#26272B")) : (repo.isDarkMode ? Color(hex: "#26272B") : Color(hex: "#EAE6DF")))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isSelected ? Color.clear : (repo.isDarkMode ? Color(hex: "#383A42") : Color(hex: "#D5D0C5")), lineWidth: 1)
                )
        }
        .buttonStyle(.scaleSpring(scale: 0.96))
    }

    // MARK: - Filter Options Panel (Category + Priority Columns 1:1)
    private func filterOptionsPanel(isDual: Bool) -> some View {
        HStack(alignment: .top, spacing: 6) {
            categoryFilterColumn(isDual: isDual)
                .frame(maxWidth: .infinity)
            priorityFilterColumn(isDual: isDual)
                .frame(maxWidth: .infinity)
        }
    }

    private func categoryFilterColumn(isDual: Bool) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("KATEGORİ")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(AppTheme.textMuted(isDark: repo.isDarkMode))
                .padding(.leading, 2)
                .padding(.bottom, 1)

            ForEach(categories.filter { $0.id != "all" }, id: \.id) { cat in
                categoryItemButton(cat: cat, isDual: isDual)
            }
        }
    }

    private func categoryItemButton(cat: (id: String, label: String), isDual: Bool) -> some View {
        let isSel = repo.selectedCategory == cat.id
        let cColor = categoryColor(cat.id)
        return Button(action: {
            Haptics.light()
            repo.selectedCategory = (repo.selectedCategory == cat.id) ? "all" : cat.id
        }) {
            HStack(spacing: 4) {
                Image(systemName: categoryIconName(cat.id))
                    .font(.system(size: 11))
                    .foregroundColor(cColor)
                Text(cat.label)
                    .font(.system(size: isDual ? 10.5 : 11.5, weight: isSel ? .bold : .medium))
                    .foregroundColor(isSel ? (repo.isDarkMode ? Color(hex: "#FAF8F5") : Color(hex: "#1E293B")) : AppTheme.textBody(isDark: repo.isDarkMode))
                    .lineLimit(1)
                Spacer()
            }
            .padding(.horizontal, 6)
            .frame(height: 28)
            .background(isSel ? cColor.opacity(0.18) : (repo.isDarkMode ? Color(hex: "#26272B") : Color(hex: "#EAE6DF")))
            .cornerRadius(7)
            .overlay(
                RoundedRectangle(cornerRadius: 7)
                    .stroke(isSel ? cColor : (repo.isDarkMode ? Color(hex: "#383A42") : Color(hex: "#D5D0C5")), lineWidth: isSel ? 1.5 : 1)
            )
        }
        .buttonStyle(.scaleSpring(scale: 0.96))
    }

    private func priorityFilterColumn(isDual: Bool) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("ÖNCELİK")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(AppTheme.textMuted(isDark: repo.isDarkMode))
                .padding(.leading, 2)
                .padding(.bottom, 1)

            ForEach(priorities.filter { $0.id != "all" }, id: \.id) { prio in
                priorityItemButton(prio: prio, isDual: isDual)
            }

            if repo.selectedCategory != "all" || repo.selectedPriority != "all" {
                Button(action: {
                    Haptics.light()
                    repo.selectedCategory = "all"
                    repo.selectedPriority = "all"
                }) {
                    Text("Temizle")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Color(hex: "#EF4444"))
                        .frame(maxWidth: .infinity)
                        .frame(height: 24)
                        .background(Color(hex: "#EF4444").opacity(0.12))
                        .cornerRadius(6)
                }
                .buttonStyle(.scaleSpring(scale: 0.96))
            }
        }
    }

    private func priorityItemButton(prio: (id: String, label: String), isDual: Bool) -> some View {
        let isSel = repo.selectedPriority == prio.id
        let pColor = priorityColor(prio.id)
        let bars = priorityBarsCount(prio.id)
        return Button(action: {
            Haptics.light()
            repo.selectedPriority = (repo.selectedPriority == prio.id) ? "all" : prio.id
        }) {
            HStack(spacing: 5) {
                // Signal bars
                HStack(alignment: .bottom, spacing: 2) {
                    RoundedRectangle(cornerRadius: 1)
                        .fill(1 <= bars ? pColor : Color.gray.opacity(0.3))
                        .frame(width: 2.5, height: 5.5)
                    RoundedRectangle(cornerRadius: 1)
                        .fill(2 <= bars ? pColor : Color.gray.opacity(0.3))
                        .frame(width: 2.5, height: 8.0)
                    RoundedRectangle(cornerRadius: 1)
                        .fill(3 <= bars ? pColor : Color.gray.opacity(0.3))
                        .frame(width: 2.5, height: 10.5)
                    RoundedRectangle(cornerRadius: 1)
                        .fill(4 <= bars ? pColor : Color.gray.opacity(0.3))
                        .frame(width: 2.5, height: 13.0)
                }
                .frame(width: 14, height: 13, alignment: .bottom)

                Text(prio.label)
                    .font(.system(size: isDual ? 10.5 : 11.5, weight: isSel ? .bold : .medium))
                    .foregroundColor(isSel ? (repo.isDarkMode ? Color(hex: "#FAF8F5") : Color(hex: "#1E293B")) : AppTheme.textBody(isDark: repo.isDarkMode))
                    .lineLimit(1)
                Spacer()
            }
            .padding(.horizontal, 6)
            .frame(height: 28)
            .background(isSel ? pColor.opacity(0.18) : (repo.isDarkMode ? Color(hex: "#26272B") : Color(hex: "#EAE6DF")))
            .cornerRadius(7)
            .overlay(
                RoundedRectangle(cornerRadius: 7)
                    .stroke(isSel ? pColor : (repo.isDarkMode ? Color(hex: "#383A42") : Color(hex: "#D5D0C5")), lineWidth: isSel ? 1.5 : 1)
            )
        }
        .buttonStyle(.scaleSpring(scale: 0.96))
    }

    private func categoryIconName(_ id: String) -> String {
        switch id {
        case "ders": return "book.fill"
        case "proje": return "folder.fill"
        case "mesleki": return "briefcase.fill"
        case "hobi": return "paintpalette.fill"
        default: return "square.grid.2x2.fill"
        }
    }

    private func categoryColor(_ id: String) -> Color {
        switch id {
        case "ders": return Color(hex: "#3B82F6")
        case "proje": return Color(hex: "#10B981")
        case "mesleki": return Color(hex: "#8B5CF6")
        case "hobi": return Color(hex: "#F97316")
        default: return Color(hex: "#64748B")
        }
    }

    private func priorityBarsCount(_ id: String) -> Int {
        switch id {
        case "urgent": return 4
        case "high": return 3
        case "normal": return 2
        case "low": return 1
        default: return 2
        }
    }

    private func priorityColor(_ id: String) -> Color {
        switch id {
        case "urgent": return Color(hex: "#EF4444")
        case "high": return Color(hex: "#F97316")
        case "normal": return Color(hex: "#FBBF24")
        case "low": return Color(hex: "#10B981")
        default: return Color(hex: "#FBBF24")
        }
    }

    // MARK: - Section Header Row (1:1 with SectionHeaderRow in DashboardScreen.kt)
    private func sectionHeader(title: String, count: Int, icon: String?) -> some View {
        HStack {
            HStack(spacing: 6) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(repo.isDarkMode ? Color(hex: "#D6D3D1") : Color(hex: "#57534E"))
                }
                Text(title)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(repo.isDarkMode ? Color(hex: "#D6D3D1") : Color(hex: "#57534E"))
            }
            Spacer()
            Text("\(count)")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(AppTheme.textMuted(isDark: repo.isDarkMode))
        }
        .padding(.horizontal, 4)
        .padding(.top, 6)
        .padding(.bottom, 2)
    }

    // MARK: - FAB Menu Button (1:1 Android White Circle FAB)
    private var fabMenuButton: some View {
        Menu {
            Button(action: {
                Haptics.light()
                showingAddModal = true
            }) {
                Label("Yeni Proje Oluştur", systemImage: "plus.circle.fill")
            }

            Button(action: {
                Haptics.light()
                showingQrModal = true
            }) {
                Label("QR Kod Okut / Paylaş", systemImage: "qrcode.viewfinder")
            }
        } label: {
            ZStack {
                Circle()
                    .fill(repo.isDarkMode ? Color(hex: "#292524") : Color.white)
                    .frame(width: 56, height: 56)
                    .overlay(
                        Circle()
                            .stroke(repo.isDarkMode ? Color(hex: "#44403C") : Color(hex: "#E2DDD5"), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(repo.isDarkMode ? 0.35 : 0.12), radius: 6, x: 0, y: 3)

                Image(systemName: "plus")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(repo.isDarkMode ? Color(hex: "#FAF8F5") : Color(hex: "#1E293B"))
            }
        }
        .padding(.trailing, 20)
        .padding(.bottom, 24)
    }

    // MARK: - Empty State Card
    private var emptyStateCard: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray")
                .font(.system(size: 44))
                .foregroundColor(AppTheme.textMuted(isDark: repo.isDarkMode))
            Text("Proje Bulunamadı")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(AppTheme.textHeading(isDark: repo.isDarkMode))
            Text("Arama veya filtre kriterlerinize uygun proje yok.")
                .font(.system(size: 13))
                .foregroundColor(AppTheme.textMuted(isDark: repo.isDarkMode))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
        .neumorphicCard(isDark: repo.isDarkMode)
    }
}

// MARK: - ProjectCardView (1:1 with ProjectCard.kt)
public struct ProjectCardView: View {
    public var project: Project
    public var isDark: Bool
    public var onShare: () -> Void

    public var body: some View {
        let (completedTasks, totalTasks) = countTasks(project)
        let isCompleted = (project.progress == 100) && (totalTasks == 0 || completedTasks == totalTasks)
        let dateSummary = formatDateSummary(startDate: project.startDate, deadline: project.deadline, createdAt: project.createdAt)

        // Custom Colors Resolution (1:1 with ProjectCard.kt)
        let customBg = parseHexColor(project.customColors?.cardBg)
        let customBorder = parseHexColor(project.customColors?.borderColor ?? project.customColors?.border)
        let customText = parseHexColor(project.customColors?.textColor)
        let customProgress = parseHexColor(project.customColors?.progressBar)

        let isCardDark = customBg != nil ? true : isDark
        let cardBgColor = customBg ?? (isCompleted ? (isDark ? Color(hex: "#14241C") : Color(hex: "#F3FAF5")) : AppTheme.card(isDark: isDark))
        let cardBorderColor = customBorder ?? (isCompleted ? Color(hex: "#10B981").opacity(0.4) : AppTheme.borderSubtle(isDark: isDark))
        let cardBorderWidth: CGFloat = customBorder != nil ? 1.5 : 1.0

        let titleColor = customText ?? AppTheme.textHeading(isDark: isDark)
        let bodyColor = customText?.opacity(0.85) ?? AppTheme.textBody(isDark: isDark)
        let mutedColor = customText?.opacity(0.65) ?? AppTheme.textMuted(isDark: isDark)

        VStack(alignment: .leading, spacing: 0) {
            // 1. Üst Satır: Kategori İkonu + Başlık + Öncelik + Tutamaç + Pin + Menü
            HStack(alignment: .center, spacing: 10) {
                CategoryVectorIconView(categoryId: project.category, isDarkMode: isCardDark)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(project.title.isEmpty ? "İsimsiz Proje" : project.title)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(titleColor)
                            .lineLimit(1)
                            .layoutPriority(1)

                        if project.members.count >= 2 {
                            Text("\(project.members.count) Üye")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(mutedColor)
                        }
                    }

                    Spacer()

                    // Hücresel Veri Öncelik Çubukları (4 bars)
                    PrioritySignalBarsView(priority: project.priority, isDarkMode: isCardDark)
                        .padding(.trailing, 4)

                    // 6'lı Tutamaç (⠿)
                    SixDotDragHandleView(tint: mutedColor.opacity(0.55))

                    // Sabitleme İkonu (PushPin)
                    Button(action: {
                        Haptics.light()
                        ProjectRepository.shared.togglePin(id: project.id)
                    }) {
                        Image(systemName: project.pinned ? "pin.fill" : "pin")
                            .font(.system(size: 15))
                            .foregroundColor(project.pinned ? (customText ?? Color(hex: "#F59E0B")) : mutedColor.opacity(0.5))
                            .rotationEffect(.degrees(project.pinned ? 0 : 45))
                    }
                    .buttonStyle(.scaleSpring(scale: 0.88))

                    // Hızlı Aksiyon Menüsü (Arşiv, Paylaş, Sil)
                    Menu {
                        Button(action: {
                            Haptics.light()
                            ProjectRepository.shared.togglePin(id: project.id)
                        }) {
                            Label(project.pinned ? "Sabitlemeyi Kaldır" : "Başa Sabitle", systemImage: project.pinned ? "pin.slash" : "pin")
                        }

                        Button(action: {
                            Haptics.light()
                            ProjectRepository.shared.toggleArchive(id: project.id)
                        }) {
                            Label(project.archived ? "Arşivden Çıkar" : "Arşive Taşı", systemImage: "archivebox")
                        }

                        Button(action: onShare) {
                            Label("Paylaş ve Rapor Al", systemImage: "square.and.arrow.up")
                        }

                        Divider()

                        Button(role: .destructive, action: {
                            Haptics.heavy()
                            ProjectRepository.shared.deleteProject(id: project.id)
                        }) {
                            Label("Çöp Kutusuna Taşı", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(mutedColor.opacity(0.7))
                            .frame(width: 26, height: 26)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.scaleSpring(scale: 0.88))
                }

                // 2. Proje Açıklaması
                if !project.description.isEmpty {
                    Text(project.description)
                        .font(.system(size: 12.5))
                        .foregroundColor(bodyColor)
                        .lineLimit(2)
                        .padding(.top, 8)
                }

                // 3. Tactile Inset (Oyulmuş Yuva) İlerleme Çubuğu (7pt yükseklik)
                VStack(spacing: 5) {
                    HStack {
                        Text("İlerleme")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(mutedColor)

                        Spacer()

                        Text("%\(project.progress)")
                            .font(.system(size: 12.5, weight: .bold))
                            .foregroundColor(titleColor)
                    }

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(isCardDark ? Color.black.opacity(0.5) : Color(hex: "#EAEBE6"))
                                .overlay(Capsule().stroke(isCardDark ? Color.white.opacity(0.1) : Color.black.opacity(0.08), lineWidth: 0.5))

                            if let customProgress = customProgress {
                                Capsule()
                                    .fill(customProgress)
                                    .frame(width: max(0, min(geo.size.width * CGFloat(project.progress) / 100.0, geo.size.width)))
                            } else {
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: isCompleted ? [Color(hex: "#10B981"), Color(hex: "#059669")] : [AppTheme.primaryStart, AppTheme.primaryEnd],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: max(0, min(geo.size.width * CGFloat(project.progress) / 100.0, geo.size.width)))
                            }
                        }
                    }
                    .frame(height: 7)
                }
                .padding(.top, 12)

                // 4. İnce Ayırıcı Çizgi (0.8pt Hairline Divider)
                Rectangle()
                    .fill(isCardDark ? Color.white.opacity(0.1) : Color(hex: "#EBEBE5"))
                    .frame(height: 0.8)
                    .padding(.top, 11)
                    .padding(.bottom, 9)

                // 5. Alt Bilgi Satırı: Tarih Aralığı & Görev Sayısı
                HStack {
                    HStack(spacing: 5) {
                        Image(systemName: "calendar")
                            .font(.system(size: 11))
                            .foregroundColor(mutedColor)
                        Text(dateSummary)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(mutedColor)
                    }

                    Spacer()

                    if isCompleted {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 12))
                                .foregroundColor(Color(hex: "#10B981"))
                            Text("Tamamlandı")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(Color(hex: "#10B981"))
                        }
                    } else {
                        HStack(spacing: 5) {
                            Image(systemName: "checkmark.circle")
                                .font(.system(size: 11))
                                .foregroundColor(mutedColor)
                            Text("\(completedTasks)/\(totalTasks) görev")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(mutedColor)
                        }
                    }
                }
            }
        .padding(.horizontal, 16)
        .padding(.vertical, 15)
        .background(cardBgColor)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(cardBorderColor, lineWidth: cardBorderWidth)
        )
        .shadow(color: isCardDark ? Color.black.opacity(0.35) : Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
        .contextMenu {
            Button(action: {
                Haptics.light()
                ProjectRepository.shared.togglePin(id: project.id)
            }) {
                Label(project.pinned ? "Sabitlemeyi Kaldır" : "Başa Sabitle", systemImage: project.pinned ? "pin.slash" : "pin")
            }

            Button(action: {
                Haptics.light()
                ProjectRepository.shared.toggleArchive(id: project.id)
            }) {
                Label(project.archived ? "Arşivden Çıkar" : "Arşive Taşı", systemImage: "archivebox")
            }

            Button(action: onShare) {
                Label("Paylaş ve Rapor Al", systemImage: "square.and.arrow.up")
            }

            Divider()

            Button(role: .destructive, action: {
                Haptics.heavy()
                ProjectRepository.shared.deleteProject(id: project.id)
            }) {
                Label("Çöp Kutusuna Taşı", systemImage: "trash")
            }
        }
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

    private func formatDateSummary(startDate: String?, deadline: String?, createdAt: Int64) -> String {
        let start = formatShort(startDate) ?? "Belirtilmemiş"
        let end = formatShort(deadline) ?? "Belirtilmemiş"
        return "\(start) → \(end)"
    }

    private func formatShort(_ dateStr: String?) -> String? {
        guard let s = dateStr, !s.isEmpty else { return nil }
        let clean = String(s.prefix(10))
        if clean.contains("-") {
            let parts = clean.split(separator: "-")
            if parts.count == 3 {
                let y = String(parts[0].suffix(2))
                let m = parts[1]
                let d = parts[2]
                return "\(d)/\(m)/\(y)"
            }
        }
        return clean
    }
}
