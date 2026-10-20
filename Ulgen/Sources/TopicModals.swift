import SwiftUI
import PhotosUI

// MARK: - Add Main Topic Sheet
public struct AddTopicSheet: View {
    public var projectId: String
    @ObservedObject var repo = ProjectRepository.shared
    @Environment(\.dismiss) private var dismiss

    @State private var title: String = ""
    @State private var description: String = ""

    public var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.bg(isDark: repo.isDarkMode).ignoresSafeArea()
                VStack(spacing: 16) {
                    TextField("Aşama Başlığı (Örn: Güç Katı PCB Tasarımı)", text: $title)
                        .font(.system(size: 15))
                        .padding(12)
                        .background(AppTheme.card(isDark: repo.isDarkMode))
                        .cornerRadius(10)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(AppTheme.border(isDark: repo.isDarkMode), lineWidth: 1))

                    TextField("Açıklama (opsiyonel)", text: $description, axis: .vertical)
                        .lineLimit(3...5)
                        .font(.system(size: 15))
                        .padding(12)
                        .background(AppTheme.card(isDark: repo.isDarkMode))
                        .cornerRadius(10)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(AppTheme.border(isDark: repo.isDarkMode), lineWidth: 1))

                    Spacer()
                }
                .padding(20)
            }
            .navigationTitle("Yeni Ana Aşama")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") { dismiss() }
                        .foregroundColor(AppTheme.primary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Ekle") {
                        repo.addMainTopic(projectId: projectId, title: title, description: description)
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .foregroundColor(AppTheme.primary)
                }
            }
        }
    }
}

// MARK: - Add Sub Topic Sheet
public struct AddSubTopicSheet: View {
    public var projectId: String
    public var mainTopicId: String
    @ObservedObject var repo = ProjectRepository.shared
    @Environment(\.dismiss) private var dismiss

    @State private var title: String = ""

    public var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.bg(isDark: repo.isDarkMode).ignoresSafeArea()
                VStack(spacing: 16) {
                    TextField("Alt Başlık (Örn: Gate Sürücü Devresi)", text: $title)
                        .font(.system(size: 15))
                        .padding(12)
                        .background(AppTheme.card(isDark: repo.isDarkMode))
                        .cornerRadius(10)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(AppTheme.border(isDark: repo.isDarkMode), lineWidth: 1))
                    Spacer()
                }
                .padding(20)
            }
            .navigationTitle("Yeni Alt Başlık")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") { dismiss() }
                        .foregroundColor(AppTheme.primary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Ekle") {
                        repo.addSubTopic(projectId: projectId, mainTopicId: mainTopicId, title: title)
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .foregroundColor(AppTheme.primary)
                }
            }
        }
    }
}

// MARK: - Add Item Sheet
public struct AddItemSheet: View {
    public var projectId: String
    public var mainTopicId: String
    public var subTopicId: String
    @ObservedObject var repo = ProjectRepository.shared
    @Environment(\.dismiss) private var dismiss

    @State private var title: String = ""
    @State private var quantity: Int = 1

    public var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.bg(isDark: repo.isDarkMode).ignoresSafeArea()
                VStack(spacing: 16) {
                    TextField("Görev / Bileşen (Örn: 100nF X7R Kapasitör)", text: $title)
                        .font(.system(size: 15))
                        .padding(12)
                        .background(AppTheme.card(isDark: repo.isDarkMode))
                        .cornerRadius(10)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(AppTheme.border(isDark: repo.isDarkMode), lineWidth: 1))

                    HStack {
                        Text("Başlangıç Adedi:")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AppTheme.textHeading(isDark: repo.isDarkMode))
                        Spacer()
                        Stepper("\(quantity)", value: $quantity, in: 1...999)
                    }
                    .padding(12)
                    .background(AppTheme.card(isDark: repo.isDarkMode))
                    .cornerRadius(10)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(AppTheme.border(isDark: repo.isDarkMode), lineWidth: 1))

                    Spacer()
                }
                .padding(20)
            }
            .navigationTitle("Yeni Görev / Parça")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") { dismiss() }
                        .foregroundColor(AppTheme.primary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Kaydet") {
                        repo.addItem(projectId: projectId, mainTopicId: mainTopicId, subTopicId: subTopicId, title: title, quantity: quantity)
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .foregroundColor(AppTheme.primary)
                }
            }
        }
    }
}

// MARK: - Add Note Sheet
public struct AddNoteSheet: View {
    public var projectId: String
    @ObservedObject var repo = ProjectRepository.shared
    @Environment(\.dismiss) private var dismiss

    @State private var noteContent: String = ""

    public var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.bg(isDark: repo.isDarkMode).ignoresSafeArea()
                VStack(spacing: 16) {
                    TextField("Mühendislik notu, ölçüm değeri veya devre gözlemi...", text: $noteContent, axis: .vertical)
                        .lineLimit(5...8)
                        .font(.system(size: 15))
                        .padding(12)
                        .background(AppTheme.card(isDark: repo.isDarkMode))
                        .cornerRadius(10)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(AppTheme.border(isDark: repo.isDarkMode), lineWidth: 1))
                    Spacer()
                }
                .padding(20)
            }
            .navigationTitle("Mühendislik Notu Ekle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") { dismiss() }
                        .foregroundColor(AppTheme.primary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Kaydet") {
                        repo.addNote(projectId: projectId, content: noteContent)
                        dismiss()
                    }
                    .disabled(noteContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .foregroundColor(AppTheme.primary)
                }
            }
        }
    }
}
