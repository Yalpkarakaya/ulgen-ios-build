import SwiftUI

public struct AddNewView: View {
    @ObservedObject var repo = ProjectRepository.shared
    @Environment(\.dismiss) private var dismiss

    @State private var title: String = ""
    @State private var description: String = ""
    @State private var category: String = "Donanım"
    @State private var priority: String = "medium"

    private let categories = ["Donanım", "Gömülü", "Yazılım", "Tasarım", "Diğer"]
    private let priorities = [
        ("Düşük", "low"),
        ("Orta", "medium"),
        ("Yüksek", "high")
    ]

    public var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.bg(isDark: repo.isDarkMode)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Title Field
                        VStack(alignment: .leading, spacing: 6) {
                            Text("PROJE BAŞLIĞI")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(AppTheme.textMuted(isDark: repo.isDarkMode))

                            TextField("Örn: 1MHz GaN Buck-Boost Güç Kartı", text: $title)
                                .font(.system(size: 15))
                                .foregroundColor(AppTheme.textBody(isDark: repo.isDarkMode))
                                .padding(12)
                                .background(AppTheme.card(isDark: repo.isDarkMode))
                                .cornerRadius(10)
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(AppTheme.border(isDark: repo.isDarkMode), lineWidth: 1))
                        }

                        // Description Field
                        VStack(alignment: .leading, spacing: 6) {
                            Text("AÇIKLAMA VE DETAYLAR")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(AppTheme.textMuted(isDark: repo.isDarkMode))

                            TextField("Proje hedefleri, devre topolojisi ve notlar...", text: $description, axis: .vertical)
                                .lineLimit(4...6)
                                .font(.system(size: 15))
                                .foregroundColor(AppTheme.textBody(isDark: repo.isDarkMode))
                                .padding(12)
                                .background(AppTheme.card(isDark: repo.isDarkMode))
                                .cornerRadius(10)
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(AppTheme.border(isDark: repo.isDarkMode), lineWidth: 1))
                        }

                        // Category Picker
                        VStack(alignment: .leading, spacing: 6) {
                            Text("KATEGORİ")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(AppTheme.textMuted(isDark: repo.isDarkMode))

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(categories, id: \.self) { cat in
                                        let isSel = category == cat
                                        Button(action: { category = cat }) {
                                            Text(cat)
                                                .font(.system(size: 13, weight: isSel ? .semibold : .regular))
                                                .foregroundColor(isSel ? .white : AppTheme.textBody(isDark: repo.isDarkMode))
                                                .padding(.horizontal, 14)
                                                .padding(.vertical, 8)
                                                .background(isSel ? AppTheme.primary : AppTheme.card(isDark: repo.isDarkMode))
                                                .cornerRadius(10)
                                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(isSel ? AppTheme.primary : AppTheme.border(isDark: repo.isDarkMode), lineWidth: 1))
                                        }
                                    }
                                }
                            }
                        }

                        // Priority Picker
                        VStack(alignment: .leading, spacing: 6) {
                            Text("ÖNCELİK")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(AppTheme.textMuted(isDark: repo.isDarkMode))

                            HStack(spacing: 10) {
                                ForEach(priorities, id: \.1) { (label, val) in
                                    let isSel = priority == val
                                    Button(action: { priority = val }) {
                                        Text(label)
                                            .font(.system(size: 13, weight: isSel ? .semibold : .regular))
                                            .foregroundColor(isSel ? .white : AppTheme.textBody(isDark: repo.isDarkMode))
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 10)
                                            .background(isSel ? AppTheme.primary : AppTheme.card(isDark: repo.isDarkMode))
                                            .cornerRadius(10)
                                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(isSel ? AppTheme.primary : AppTheme.border(isDark: repo.isDarkMode), lineWidth: 1))
                                    }
                                }
                            }
                        }

                        // Save Button
                        Button(action: {
                            guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                            repo.addProject(
                                title: title,
                                description: description,
                                category: category,
                                priority: priority
                            )
                            dismiss()
                        }) {
                            Text("Projeyi Oluştur")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                        ? Color.gray.opacity(0.4)
                                        : AppTheme.primary
                                )
                                .cornerRadius(12)
                        }
                        .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .padding(.top, 10)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Yeni Proje")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") { dismiss() }
                        .foregroundColor(AppTheme.primary)
                }
            }
        }
    }
}
