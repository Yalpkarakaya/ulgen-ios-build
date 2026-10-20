import SwiftUI

public struct AddNewView: View {
    @ObservedObject var repo = ProjectRepository.shared
    @Environment(\.dismiss) private var dismiss

    @State private var title: String = ""
    @State private var description: String = ""
    @State private var category: String = "proje"
    @State private var priority: String = "medium"
    @State private var startDate: Date = Date()
    @State private var deadline: Date = Calendar.current.date(byAdding: .month, value: 3, to: Date()) ?? Date()
    @State private var hasDeadline: Bool = true

    // 4-Tab Color Customization State
    @State private var selectedColorTab: Int = 0 // 0: Arkaplan, 1: Kenar, 2: İlerleme, 3: Yazı
    @State private var customBgHex: String = ""
    @State private var customBorderHex: String = ""
    @State private var customProgressHex: String = ""
    @State private var customTextHex: String = ""

    // 5-Step AI Roadmap Wizard State
    @State private var showAiWizard: Bool = false
    @State private var knownTopics: String = ""
    @State private var learningGoals: String = ""
    @State private var resources: String = ""
    @State private var finalGoals: String = ""
    @State private var extraInstructions: String = ""
    @State private var isGeneratingAiRoadmap: Bool = false

    private let categories: [(id: String, label: String)] = [
        ("proje", "Proje"),
        ("ders", "Ders"),
        ("mesleki", "Mesleki"),
        ("hobi", "Hobi"),
        ("diger", "Diğer")
    ]

    private let priorities: [(id: String, label: String)] = [
        ("low", "Düşük"),
        ("normal", "Orta"),
        ("high", "Yüksek"),
        ("urgent", "Acil")
    ]

    private let presetColors: [String] = [
        "#0D9488", "#2563EB", "#7C3AED", "#EA580C", "#DC2626",
        "#10B981", "#F59E0B", "#6B7280", "#1E1B18", "#FAF8F5"
    ]

    public var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.bg(isDark: repo.isDarkMode)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        // MARK: - Live Miniature Preview Card
                        livePreviewCard

                        // MARK: - Title Field
                        VStack(alignment: .leading, spacing: 6) {
                            Text("PROJE BAŞLIĞI")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(AppTheme.textMuted(isDark: repo.isDarkMode))

                            TextField("Örn: 1MHz GaN Buck-Boost Güç Kartı", text: $title)
                                .font(.system(size: 15))
                                .foregroundColor(AppTheme.textBody(isDark: repo.isDarkMode))
                                .padding(12)
                                .background(AppTheme.card(isDark: repo.isDarkMode))
                                .cornerRadius(12)
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppTheme.borderSubtle(isDark: repo.isDarkMode), lineWidth: 1))
                        }

                        // MARK: - Description Field
                        VStack(alignment: .leading, spacing: 6) {
                            Text("AÇIKLAMA VE DETAYLAR")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(AppTheme.textMuted(isDark: repo.isDarkMode))

                            TextField("Proje hedefleri, devre topolojisi ve notlar...", text: $description, axis: .vertical)
                                .lineLimit(3...5)
                                .font(.system(size: 14))
                                .foregroundColor(AppTheme.textBody(isDark: repo.isDarkMode))
                                .padding(12)
                                .background(AppTheme.card(isDark: repo.isDarkMode))
                                .cornerRadius(12)
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppTheme.borderSubtle(isDark: repo.isDarkMode), lineWidth: 1))
                        }

                        // MARK: - Category Picker
                        VStack(alignment: .leading, spacing: 6) {
                            Text("KATEGORİ")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(AppTheme.textMuted(isDark: repo.isDarkMode))

                            HStack(spacing: 8) {
                                ForEach(categories, id: \.id) { cat in
                                    let isSel = category == cat.id
                                    Button(action: {
                                        Haptics.light()
                                        category = cat.id
                                    }) {
                                        Text(cat.label)
                                            .font(.system(size: 12, weight: isSel ? .bold : .medium))
                                            .foregroundColor(isSel ? .white : AppTheme.textBody(isDark: repo.isDarkMode))
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 8)
                                            .background(isSel ? AppTheme.primary : AppTheme.card(isDark: repo.isDarkMode))
                                            .cornerRadius(10)
                                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(isSel ? AppTheme.primary : AppTheme.borderSubtle(isDark: repo.isDarkMode), lineWidth: 1))
                                    }
                                    .buttonStyle(.scaleSpring(scale: 0.94))
                                }
                            }
                        }

                        // MARK: - Priority Picker
                        VStack(alignment: .leading, spacing: 6) {
                            Text("ÖNCELİK")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(AppTheme.textMuted(isDark: repo.isDarkMode))

                            HStack(spacing: 8) {
                                ForEach(priorities, id: \.id) { prio in
                                    let isSel = priority == prio.id
                                    Button(action: {
                                        Haptics.light()
                                        priority = prio.id
                                    }) {
                                        HStack(spacing: 4) {
                                            PrioritySignalBarsView(priority: prio.id, isDarkMode: isSel ? false : repo.isDarkMode, isSmall: true)
                                            Text(prio.label)
                                                .font(.system(size: 12, weight: isSel ? .bold : .medium))
                                                .foregroundColor(isSel ? .white : AppTheme.textBody(isDark: repo.isDarkMode))
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 8)
                                        .background(isSel ? AppTheme.primary : AppTheme.card(isDark: repo.isDarkMode))
                                        .cornerRadius(10)
                                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(isSel ? AppTheme.primary : AppTheme.borderSubtle(isDark: repo.isDarkMode), lineWidth: 1))
                                    }
                                    .buttonStyle(.scaleSpring(scale: 0.94))
                                }
                            }
                        }

                        // MARK: - Dates Section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("TARİHLER")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(AppTheme.textMuted(isDark: repo.isDarkMode))

                            DatePicker("Başlangıç Tarihi", selection: $startDate, displayedComponents: .date)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(AppTheme.textBody(isDark: repo.isDarkMode))

                            Toggle("Hedef Bitiş Tarihi Var", isOn: $hasDeadline)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(AppTheme.textBody(isDark: repo.isDarkMode))

                            if hasDeadline {
                                DatePicker("Hedef Bitiş Tarihi", selection: $deadline, displayedComponents: .date)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(AppTheme.textBody(isDark: repo.isDarkMode))
                            }
                        }
                        .padding(14)
                        .neumorphicCard(isDark: repo.isDarkMode)

                        // MARK: - 4-Tab Color Customization Section
                        colorCustomizationSection

                        // MARK: - 5-Step AI Roadmap Wizard Button
                        Button(action: {
                            withAnimation(.spring()) { showAiWizard.toggle() }
                        }) {
                            HStack {
                                Image(systemName: "sparkles")
                                Text("5 Aşamalı AI Yol Haritası Sihirbazı")
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .rotationEffect(.degrees(showAiWizard ? 90 : 0))
                            }
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(AppTheme.primary)
                            .padding(14)
                            .background(AppTheme.primary.opacity(0.1))
                            .cornerRadius(12)
                        }
                        .buttonStyle(.scaleSpring(scale: 0.97))

                        if showAiWizard {
                            aiRoadmapWizardSection
                        }

                        // MARK: - Create Project Button
                        Button(action: createProject) {
                            Text("Projeyi Oluştur")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                        ? Color.gray.opacity(0.4)
                                        : AppTheme.primary
                                )
                                .cornerRadius(14)
                                .shadow(color: AppTheme.primary.opacity(0.3), radius: 6, x: 0, y: 3)
                        }
                        .buttonStyle(.scaleSpring(scale: 0.96))
                        .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .padding(.top, 10)
                        .padding(.bottom, 32)
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Yeni Proje")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") { dismiss() }
                        .foregroundColor(AppTheme.primary)
                        .buttonStyle(.scaleSpring(scale: 0.92))
                }
            }
        }
    }

    // MARK: - Live Preview Card
    private var livePreviewCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("CANLI ÖNİZLEME")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(AppTheme.textMuted(isDark: repo.isDarkMode))

            HStack(spacing: 10) {
                CategoryVectorIconView(categoryId: category, isDarkMode: repo.isDarkMode)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title.isEmpty ? "Proje Başlığı" : title)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(customTextHex.isEmpty ? AppTheme.textHeading(isDark: repo.isDarkMode) : Color(hex: customTextHex))
                        .lineLimit(1)

                    Text(description.isEmpty ? "Açıklama girilmedi..." : description)
                        .font(.system(size: 11))
                        .foregroundColor(AppTheme.textMuted(isDark: repo.isDarkMode))
                        .lineLimit(1)
                }

                Spacer()

                PrioritySignalBarsView(priority: priority, isDarkMode: repo.isDarkMode)
            }
        }
        .padding(14)
        .background(customBgHex.isEmpty ? AppTheme.card(isDark: repo.isDarkMode) : Color(hex: customBgHex))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(customBorderHex.isEmpty ? AppTheme.borderSubtle(isDark: repo.isDarkMode) : Color(hex: customBorderHex), lineWidth: 1)
        )
    }

    // MARK: - Color Customization Section (4-Tabs)
    private var colorCustomizationSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("ÖZEL RENK PALETİ (4 SEKME)")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(AppTheme.textMuted(isDark: repo.isDarkMode))

            // 4 Tabs: Arkaplan, Kenar, İlerleme, Yazı
            Picker("Renk Hedefi", selection: $selectedColorTab) {
                Text("Arkaplan").tag(0)
                Text("Kenar").tag(1)
                Text("İlerleme").tag(2)
                Text("Yazı").tag(3)
            }
            .pickerStyle(SegmentedPickerStyle())

            // Color Swatches
            HStack(spacing: 8) {
                ForEach(presetColors, id: \.self) { hex in
                    Button(action: {
                        Haptics.light()
                        applyColor(hex: hex)
                    }) {
                        Circle()
                            .fill(Color(hex: hex))
                            .frame(width: 26, height: 26)
                            .overlay(Circle().stroke(Color.white.opacity(0.5), lineWidth: 1))
                    }
                    .buttonStyle(.scaleSpring(scale: 0.88))
                }
            }
            .padding(.top, 4)
        }
        .padding(14)
        .neumorphicCard(isDark: repo.isDarkMode)
    }

    private func applyColor(hex: String) {
        switch selectedColorTab {
        case 0: customBgHex = hex
        case 1: customBorderHex = hex
        case 2: customProgressHex = hex
        case 3: customTextHex = hex
        default: break
        }
    }

    // MARK: - 5-Step AI Roadmap Wizard Section
    private var aiRoadmapWizardSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            wizardField(title: "1. Bildiğim Konular", text: $knownTopics, placeholder: "Örn: C++, STM32 GPIO, SPI")
            wizardField(title: "2. Öğrenmek İstediklerim", text: $learningGoals, placeholder: "Örn: CAN-FD, FreeRTOS RingBuffer")
            wizardField(title: "3. Mevcut Kaynaklarım", text: $resources, placeholder: "Örn: STM32G4 dev board, osiloskop")
            wizardField(title: "4. Nihai Hedeflerim", text: $finalGoals, placeholder: "Örn: 1Mbit/s telemetri veri kaydı")
            wizardField(title: "5. AI'ya Ek Talimatlar", text: $extraInstructions, placeholder: "Örn: Modüler HAL sürücüleri kullan")

            Button(action: generateAiRoadmap) {
                HStack(spacing: 6) {
                    if isGeneratingAiRoadmap {
                        ProgressView().tint(.white)
                    } else {
                        Image(systemName: "wand.and.stars")
                    }
                    Text(isGeneratingAiRoadmap ? "Yol Haritası Oluşturuluyor..." : "AI ile Aşamaları Oluştur")
                }
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(AppTheme.primary)
                .cornerRadius(10)
            }
            .buttonStyle(.scaleSpring(scale: 0.96))
            .disabled(isGeneratingAiRoadmap)
        }
        .padding(14)
        .neumorphicCard(isDark: repo.isDarkMode)
    }

    private func wizardField(title: String, text: Binding<String>, placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(AppTheme.textHeading(isDark: repo.isDarkMode))

            TextField(placeholder, text: text)
                .font(.system(size: 13))
                .padding(8)
                .background(repo.isDarkMode ? Color(hex: "#1E1B18") : Color.white)
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppTheme.borderSubtle(isDark: repo.isDarkMode), lineWidth: 1))
        }
    }

    private func generateAiRoadmap() {
        isGeneratingAiRoadmap = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            isGeneratingAiRoadmap = false
            Haptics.success()
        }
    }

    private func createProject() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let startStr = formatter.string(from: startDate)
        let deadlineStr = hasDeadline ? formatter.string(from: deadline) : nil

        var customColors: CustomColorConfig? = nil
        if !customBgHex.isEmpty || !customBorderHex.isEmpty || !customProgressHex.isEmpty || !customTextHex.isEmpty {
            customColors = CustomColorConfig(
                cardBg: customBgHex.isEmpty ? nil : customBgHex,
                border: customBorderHex.isEmpty ? nil : customBorderHex,
                progressBar: customProgressHex.isEmpty ? nil : customProgressHex,
                textColor: customTextHex.isEmpty ? nil : customTextHex
            )
        }

        repo.addProject(
            title: title,
            description: description,
            category: category,
            priority: priority,
            startDate: startStr,
            deadline: deadlineStr,
            customColors: customColors
        )
        dismiss()
    }
}
