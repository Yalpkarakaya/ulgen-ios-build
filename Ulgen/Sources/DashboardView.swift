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

                            // Connected Accordion: Sıralama Ölçütü
                            if showSortPanel {
                                sortAccordionPanel
                                    .transition(.opacity.combined(with: .move(edge: .top)))
                            }

                            // Connected Accordion: Filtreler
                            if showFilterPanel {
                                filterAccordionPanel
                                    .transition(.opacity.combined(with: .move(edge: .top)))
                            }

                            // Proje Kartları Listesi
                            if repo.filteredProjects.isEmpty {
                                emptyStateCard
                            } else {
                                LazyVStack(spacing: 14) {
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
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 14)
                        .padding(.bottom, 100)
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
                    // Dark Mode Toggle
                    Button(action: {
                        Haptics.light()
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            repo.isDarkMode.toggle()
                        }
                    }) {
                        Image(systemName: repo.isDarkMode ? "sun.max.fill" : "moon.stars.fill")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(repo.isDarkMode ? Color(hex: "#FDE047") : AppTheme.textHeading(isDark: false))
                            .frame(width: 40, height: 40)
                            .background(AppTheme.card(isDark: repo.isDarkMode))
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppTheme.borderSubtle(isDark: repo.isDarkMode), lineWidth: 1))
                            .shadow(color: repo.isDarkMode ? Color.black.opacity(0.3) : Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
                    }

                    // Notification Bell
                    Button(action: {
                        Haptics.light()
                        showingNotifPanel = true
                    }) {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: "bell")
                                .font(.system(size: 17, weight: .medium))
                                .foregroundColor(AppTheme.textHeading(isDark: repo.isDarkMode))
                                .frame(width: 40, height: 40)
                                .background(AppTheme.card(isDark: repo.isDarkMode))
                                .cornerRadius(12)
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppTheme.borderSubtle(isDark: repo.isDarkMode), lineWidth: 1))
                                .shadow(color: repo.isDarkMode ? Color.black.opacity(0.3) : Color.black.opacity(0.04), radius: 4, x: 0, y: 2)

                            if !repo.notifications.isEmpty {
                                Circle()
                                    .fill(Color(hex: "#EF4444"))
                                    .frame(width: 8, height: 8)
                                    .offset(x: -6, y: 6)
                            }
                        }
                    }

                    // Hamburger Menu (Opens Side Drawer from RIGHT)
                    Button(action: {
                        Haptics.light()
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            isDrawerOpen.toggle()
                        }
                    }) {
                        Image(systemName: "line.3.horizontal")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(AppTheme.textHeading(isDark: repo.isDarkMode))
                            .frame(width: 40, height: 40)
                            .background(AppTheme.card(isDark: repo.isDarkMode))
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppTheme.borderSubtle(isDark: repo.isDarkMode), lineWidth: 1))
                            .shadow(color: repo.isDarkMode ? Color.black.opacity(0.3) : Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
                    }
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

            TextField("Proje veya parça ara...", text: $repo.searchQuery)
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
        .background(AppTheme.card(isDark: repo.isDarkMode))
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppTheme.borderSubtle(isDark: repo.isDarkMode), lineWidth: 1))
        .shadow(color: repo.isDarkMode ? Color.black.opacity(0.2) : Color.black.opacity(0.03), radius: 4, x: 0, y: 1)
    }

    // MARK: - Controls Row (Sıralama Ölçütü & Filtreler)
    private var controlsRow: some View {
        HStack(spacing: 8) {
            // Sol: Sıralama Ölçütü Butonu
            Button(action: {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    showSortPanel.toggle()
                    if showSortPanel { showFilterPanel = false }
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

            // Sağ: Filtreler Butonu
            let activeFilters = (repo.selectedCategory != "all" ? 1 : 0) + (repo.selectedPriority != "all" ? 1 : 0)
            Button(action: {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    showFilterPanel.toggle()
                    if showFilterPanel { showSortPanel = false }
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
        }
    }

    // MARK: - Sort Accordion Panel (9 Sort Options 1:1)
    private var sortAccordionPanel: some View {
        VStack(spacing: 4) {
            ForEach(sortOptions, id: \.id) { opt in
                let isSelected = repo.sortOption == opt.id
                Button(action: {
                    Haptics.light()
                    repo.sortOption = opt.id
                    withAnimation { showSortPanel = false }
                }) {
                    HStack {
                        Text(opt.label)
                            .font(.system(size: 13, weight: isSelected ? .bold : .medium))
                            .foregroundColor(isSelected ? AppTheme.primary : AppTheme.textBody(isDark: repo.isDarkMode))

                        Spacer()

                        if isSelected {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(AppTheme.primary)
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(isSelected ? AppTheme.primary.opacity(0.1) : Color.clear)
                    .cornerRadius(8)
                }
            }
        }
        .padding(10)
        .background(repo.isDarkMode ? Color(hex: "#1D1E22") : Color(hex: "#F3F1EE"))
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppTheme.border(isDark: repo.isDarkMode), lineWidth: 1))
    }

    // MARK: - Filter Accordion Panel (Categories + Priorities)
    private var filterAccordionPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Kategori Seçimi
            VStack(alignment: .leading, spacing: 6) {
                Text("KATEGORİ")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(AppTheme.textMuted(isDark: repo.isDarkMode))

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(categories, id: \.id) { cat in
                            let isSel = repo.selectedCategory == cat.id
                            Button(action: {
                                Haptics.light()
                                repo.selectedCategory = (repo.selectedCategory == cat.id && cat.id != "all") ? "all" : cat.id
                            }) {
                                Text(cat.label)
                                    .font(.system(size: 12, weight: isSel ? .bold : .medium))
                                    .foregroundColor(isSel ? .white : AppTheme.textBody(isDark: repo.isDarkMode))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(isSel ? AppTheme.primary : (repo.isDarkMode ? Color(hex: "#26272B") : Color(hex: "#EAE6DF")))
                                    .cornerRadius(12)
                            }
                        }
                    }
                }
            }

            // Öncelik Seçimi
            VStack(alignment: .leading, spacing: 6) {
                Text("ÖNCELİK")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(AppTheme.textMuted(isDark: repo.isDarkMode))

                HStack(spacing: 6) {
                    ForEach(priorities, id: \.id) { prio in
                        let isSel = repo.selectedPriority == prio.id
                        Button(action: {
                            Haptics.light()
                            repo.selectedPriority = (repo.selectedPriority == prio.id && prio.id != "all") ? "all" : prio.id
                        }) {
                            Text(prio.label)
                                .font(.system(size: 12, weight: isSel ? .bold : .medium))
                                .foregroundColor(isSel ? .white : AppTheme.textBody(isDark: repo.isDarkMode))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 6)
                                .background(isSel ? AppTheme.primary : (repo.isDarkMode ? Color(hex: "#26272B") : Color(hex: "#EAE6DF")))
                                .cornerRadius(12)
                        }
                    }
                }
            }

            // Filtreleri Temizle
            if repo.selectedCategory != "all" || repo.selectedPriority != "all" {
                Button(action: {
                    Haptics.light()
                    repo.selectedCategory = "all"
                    repo.selectedPriority = "all"
                }) {
                    Text("Filtreleri Temizle")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color(hex: "#EF4444"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color(hex: "#EF4444").opacity(0.1))
                        .cornerRadius(10)
                }
            }
        }
        .padding(12)
        .background(repo.isDarkMode ? Color(hex: "#1D1E22") : Color(hex: "#F3F1EE"))
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppTheme.border(isDark: repo.isDarkMode), lineWidth: 1))
    }

    // MARK: - FAB Menu Button
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
                    .fill(
                        LinearGradient(
                            colors: [AppTheme.primaryStart, AppTheme.primaryEnd],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 58, height: 58)
                    .shadow(color: AppTheme.primary.opacity(0.4), radius: 8, x: 0, y: 4)

                Image(systemName: "plus")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
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

    @State private var dragOffset: CGFloat = 0

    public var body: some View {
        let (completedTasks, totalTasks) = countTasks(project)
        let isCompleted = (project.progress == 100) && (totalTasks == 0 || completedTasks == totalTasks)
        let dateSummary = formatDateSummary(startDate: project.startDate, deadline: project.deadline, createdAt: project.createdAt)

        ZStack {
            // Swipe Actions Background (Arşiv / Sil)
            HStack {
                if dragOffset > 20 {
                    HStack(spacing: 6) {
                        Image(systemName: "archivebox.fill")
                        Text("ARŞİV")
                            .font(.system(size: 12, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .frame(maxHeight: .infinity)
                    .background(Color(hex: "#048058"))
                    .cornerRadius(20)
                    Spacer()
                }

                if dragOffset < -20 {
                    Spacer()
                    HStack(spacing: 6) {
                        Image(systemName: "trash.fill")
                        Text("SİL")
                            .font(.system(size: 12, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .frame(maxHeight: .infinity)
                    .background(Color(hex: "#C72626"))
                    .cornerRadius(20)
                }
            }

            // Card Front Body
            VStack(alignment: .leading, spacing: 0) {
                // 1. Üst Satır: Kategori İkonu + Başlık + Öncelik + Tutamaç + Pin
                HStack(alignment: .center, spacing: 10) {
                    CategoryVectorIconView(categoryId: project.category, isDarkMode: isDark)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(project.title.isEmpty ? "İsimsiz Proje" : project.title)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(AppTheme.textHeading(isDark: isDark))
                            .lineLimit(1)

                        if project.members.count >= 2 {
                            Text("\(project.members.count) Üye")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(AppTheme.textMuted(isDark: isDark))
                        }
                    }

                    Spacer()

                    // Hücresel Veri Öncelik Çubukları (4 bars)
                    PrioritySignalBarsView(priority: project.priority, isDarkMode: isDark)
                        .padding(.trailing, 4)

                    // 6'lı Tutamaç (⠿)
                    Image(systemName: "line.3.horizontal")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(AppTheme.textMuted(isDark: isDark).opacity(0.4))
                        .rotationEffect(.degrees(90))

                    // Sabitleme İkonu (PushPin)
                    Button(action: {
                        Haptics.light()
                        ProjectRepository.shared.togglePin(id: project.id)
                    }) {
                        Image(systemName: project.pinned ? "pin.fill" : "pin")
                            .font(.system(size: 15))
                            .foregroundColor(project.pinned ? Color(hex: "#F59E0B") : AppTheme.textMuted(isDark: isDark).opacity(0.5))
                            .rotationEffect(.degrees(project.pinned ? 0 : 45))
                    }
                    .buttonStyle(PlainButtonStyle())
                }

                // 2. Proje Açıklaması
                if !project.description.isEmpty {
                    Text(project.description)
                        .font(.system(size: 12.5))
                        .foregroundColor(AppTheme.textBody(isDark: isDark))
                        .lineLimit(2)
                        .padding(.top, 8)
                }

                // 3. Tactile Inset (Oyulmuş Yuva) İlerleme Çubuğu (7pt yükseklik)
                VStack(spacing: 5) {
                    HStack {
                        Text("İlerleme")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(AppTheme.textMuted(isDark: isDark))

                        Spacer()

                        Text("%\(project.progress)")
                            .font(.system(size: 12.5, weight: .bold))
                            .foregroundColor(AppTheme.textHeading(isDark: isDark))
                    }

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(isDark ? Color.black.opacity(0.5) : Color(hex: "#EAEBE6"))
                                .overlay(Capsule().stroke(isDark ? Color.white.opacity(0.1) : Color.black.opacity(0.08), lineWidth: 0.5))

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
                    .frame(height: 7)
                }
                .padding(.top, 12)

                // 4. İnce Ayırıcı Çizgi (0.8pt Hairline Divider)
                Rectangle()
                    .fill(isDark ? Color(hex: "#262A32") : Color(hex: "#EBEBE5"))
                    .frame(height: 0.8)
                    .padding(.top, 11)
                    .padding(.bottom, 9)

                // 5. Alt Bilgi Satırı: Tarih Aralığı & Görev Sayısı
                HStack {
                    HStack(spacing: 5) {
                        Image(systemName: "calendar")
                            .font(.system(size: 11))
                            .foregroundColor(AppTheme.textMuted(isDark: isDark))
                        Text(dateSummary)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(AppTheme.textMuted(isDark: isDark))
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
                                .foregroundColor(AppTheme.textMuted(isDark: isDark))
                            Text("\(completedTasks)/\(totalTasks) görev")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(AppTheme.textMuted(isDark: isDark))
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 15)
            .background(isCompleted ? (isDark ? Color(hex: "#14241C") : Color(hex: "#F3FAF5")) : AppTheme.card(isDark: isDark))
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isCompleted ? Color(hex: "#10B981").opacity(0.4) : AppTheme.borderSubtle(isDark: isDark), lineWidth: 1)
            )
            .shadow(color: isDark ? Color.black.opacity(0.35) : Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
            .offset(x: dragOffset)
            .gesture(
                DragGesture()
                    .onChanged { val in
                        if abs(val.translation.width) > 10 {
                            dragOffset = val.translation.width
                        }
                    }
                    .onEnded { val in
                        if val.translation.width > 90 {
                            Haptics.medium()
                            ProjectRepository.shared.toggleArchive(id: project.id)
                        } else if val.translation.width < -90 {
                            Haptics.heavy()
                            ProjectRepository.shared.deleteProject(id: project.id)
                        }
                        withAnimation(.spring()) {
                            dragOffset = 0
                        }
                    }
            )
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
        return "\(start) ➔ \(end)"
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
