import Foundation
import UIKit

public class ReportExporter {
    public static let shared = ReportExporter()

    public func generateMarkdown(project: Project) -> String {
        var md = "# Proje Raporu: \(project.title)\n\n"
        md += "- **Kategori:** \(project.category)\n"
        md += "- **Öncelik:** \(project.priority.uppercased())\n"
        md += "- **İlerleme:** %\(project.progress)\n"
        md += "- **Açıklama:** \(project.description)\n"
        md += "- **Oluşturulma Tarihi:** \(Date(timeIntervalSince1970: Double(project.createdAt) / 1000).formatted())\n"
        md += "- **Son Güncelleme:** \(Date(timeIntervalSince1970: Double(project.lastUpdated) / 1000).formatted())\n\n"

        md += "## Aşamalar ve Görev Listesi\n\n"
        for (tIdx, topic) in project.mainTopics.enumerated() {
            md += "### \(tIdx + 1). \(topic.title)\n"
            if !topic.description.isEmpty {
                md += "\(topic.description)\n\n"
            }
            for sub in topic.subTopics {
                md += "#### \(sub.title)\n"
                for item in sub.items {
                    let status = item.completed ? "[x]" : "[ ]"
                    md += "- \(status) \(item.displayTitle) (Adet: \(item.quantity))\n"
                }
                md += "\n"
            }
        }

        if !project.notes.isEmpty {
            md += "## Mühendislik Notları\n\n"
            for note in project.notes {
                md += "- \(note.content) _(\(Date(timeIntervalSince1970: Double(note.createdAt) / 1000).formatted()))_\n"
            }
            md += "\n"
        }

        return md
    }

    public func generateJson(project: Project) -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        if let data = try? encoder.encode(project),
           let str = String(data: data, encoding: .utf8) {
            return str
        }
        return "{}"
    }

    public func exportFile(content: String, filename: String) -> URL? {
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent(filename)
        do {
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            return nil
        }
    }
}
