import SwiftUI
import CoreImage.CIFilterBuiltins

public struct ExportShareView: View {
    public var project: Project
    @ObservedObject var repo = ProjectRepository.shared
    @Environment(\.dismiss) private var dismiss

    @State private var selectedTab: Int = 0 // 0: Rapor, 1: JSON, 2: QR Kod
    @State private var showShareSheet: Bool = false
    @State private var shareURL: URL? = nil

    private let context = CIContext()
    private let filter = CIFilter.qrCodeGenerator()

    public var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.bg(isDark: repo.isDarkMode).ignoresSafeArea()

                VStack(spacing: 14) {
                    // Tab Picker
                    Picker("Biçim", selection: $selectedTab) {
                        Text("Markdown Rapor").tag(0)
                        Text("Yedek JSON").tag(1)
                        Text("QR Paylaşım").tag(2)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal, 16)
                    .padding(.top, 10)

                    if selectedTab == 0 {
                        markdownPreview
                    } else if selectedTab == 1 {
                        jsonPreview
                    } else {
                        qrCodeSection
                    }
                }
            }
            .navigationTitle("Paylaş ve Rapor Al")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Kapat") { dismiss() }
                        .foregroundColor(AppTheme.primary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: triggerShare) {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .foregroundColor(AppTheme.primary)
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let url = shareURL {
                    ShareActivityView(activityItems: [url])
                }
            }
        }
    }

    private var markdownPreview: some View {
        let md = ReportExporter.shared.generateMarkdown(project: project)
        return ScrollView {
            Text(md)
                .font(.system(size: 13, design: .monospaced))
                .foregroundColor(AppTheme.textBody(isDark: repo.isDarkMode))
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppTheme.card(isDark: repo.isDarkMode))
                .cornerRadius(12)
                .padding(16)
        }
    }

    private var jsonPreview: some View {
        let json = ReportExporter.shared.generateJson(project: project)
        return ScrollView {
            Text(json)
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(AppTheme.textBody(isDark: repo.isDarkMode))
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppTheme.card(isDark: repo.isDarkMode))
                .cornerRadius(12)
                .padding(16)
        }
    }

    private var qrCodeSection: some View {
        VStack(spacing: 16) {
            Text("Diğer Cihazlardan Tara")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(AppTheme.textHeading(isDark: repo.isDarkMode))

            if let qrImage = generateQRCode(from: "ulgen://project/\(project.id)") {
                Image(uiImage: qrImage)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 220, height: 220)
                    .padding(16)
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(radius: 6)
            }

            Text("Proje Kimliği: \(project.id)")
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(AppTheme.textMuted(isDark: repo.isDarkMode))

            Spacer()
        }
        .padding(.top, 24)
    }

    private func triggerShare() {
        let content: String
        let filename: String
        if selectedTab == 0 {
            content = ReportExporter.shared.generateMarkdown(project: project)
            filename = "\(project.title.replacingOccurrences(of: " ", with: "_"))_Rapor.md"
        } else {
            content = ReportExporter.shared.generateJson(project: project)
            filename = "\(project.title.replacingOccurrences(of: " ", with: "_")).json"
        }

        if let fileURL = ReportExporter.shared.exportFile(content: content, filename: filename) {
            self.shareURL = fileURL
            self.showShareSheet = true
        }
    }

    private func generateQRCode(from string: String) -> UIImage? {
        filter.message = Data(string.utf8)
        if let outputImage = filter.outputImage,
           let cgImage = context.createCGImage(outputImage, from: outputImage.extent) {
            return UIImage(cgImage: cgImage)
        }
        return nil
    }
}

// MARK: - Native iOS UIActivityViewController Wrapper
public struct ShareActivityView: UIViewControllerRepresentable {
    public var activityItems: [Any]

    public func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    public func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
