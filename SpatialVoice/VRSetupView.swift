import SwiftUI
import UniformTypeIdentifiers
import PDFKit
import RealityKit
import Vision
import UIKit

struct VRSetupView: View {
    var onBack: (() -> Void)? = nil
    var onNext: (() -> Void)? = nil

    @Environment(\.dismiss) private var dismiss
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    @EnvironmentObject private var session: PresentationSession

    // —— 狀態：目前是否已經開始練習（顯示 PresentationHUDView） —— //
    @State private var isRunning: Bool = false

    // —— State: Background 單選 —— //
    private let backgrounds = ["Service2_pic1", "Service2_pic2", "Service2_pic3", "Service2_pic4"]
    @State private var selectedBackground: String? = nil

    // —— State: Language —— //
    private let languages: [LanguageItem] = [
        .init(id: "en",      flag: "🇬🇧", name: "English"),
        .init(id: "zh-Hans", flag: "🇨🇳", name: "Mandarin Chinese"),
        .init(id: "hk",      flag: "🇭🇰", name: "Cantonese"),
        .init(id: "es",      flag: "🇪🇸", name: "Spanish"),
        .init(id: "fr",      flag: "🇫🇷", name: "French"),
        .init(id: "ar",      flag: "🇸🇦", name: "Arabic"),
        .init(id: "bn",      flag: "🇧🇩", name: "Bengali"),
        .init(id: "ru",      flag: "🇷🇺", name: "Russian"),
        .init(id: "pt",      flag: "🇵🇹", name: "Portuguese"),
        .init(id: "ur",      flag: "🇵🇰", name: "Urdu")
    ]
    @State private var selectedLanguageID: String? = nil

    // —— State: 人數 & 時間 —— //
    enum Crowd: String, CaseIterable {
        case few    = "Few Audiences"
        case normal = "Normal Audiences"
        case many   = "Many Audiences"
    }
    @State private var crowd: Crowd = .normal

    @State private var minutes: Int = 5

    // —— State: 上載 —— //
    private enum UploadTarget {
        case slides
        case script
        case marking
    }

    @State private var currentUploadTarget: UploadTarget? = nil
    @State private var showImporter = false

    // 支援 pdf + pptx
    private let allowedFileTypes: [UTType] = {
        var list: [UTType] = [UTType.pdf]
        if let pptx = UTType(filenameExtension: "pptx", conformingTo: .data) {
            list.append(pptx)
        }
        return list
    }()

    // MARK: - Body

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if isRunning {
                // 已經開始 → 顯示 HUD
                PresentationHUDView(
                    onBackToClass: {
                        Task {
                            await dismissImmersiveSpace()
                            if let onBack {
                                onBack()
                            } else {
                                dismiss()
                            }
                        }
                    }
                )
            } else {
                // 尚未開始 → GET READY 設定畫面
                setupContent
            }
        }
        // 左下 Back（只在設定畫面顯示）
        .overlay(alignment: .bottomLeading) {
            if !isRunning {
                Button {
                    if let onBack { onBack() } else { dismiss() }
                } label: {
                    Label("Back", systemImage: "chevron.left")
                        .font(.headline)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(.ultraThinMaterial, in: Capsule())
                }
                .buttonStyle(.plain)
                .padding(.leading, 20)
                .padding(.bottom, 20)
            }
        }
        // 右下 Next
        .overlay(alignment: .bottomTrailing) {
            if !isRunning {
                Button {
                    session.durationMinutes = minutes
                    isRunning = true

                    Task {
                        await openSelectedImmersiveScene()
                    }
                } label: {
                    Label("Next", systemImage: "chevron.right")
                        .font(.headline)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(.ultraThinMaterial, in: Capsule())
                }
                .buttonStyle(.plain)
                .padding(.trailing, 20)
                .padding(.bottom, 20)
            }
        }
        // File Importer
        .fileImporter(
            isPresented: $showImporter,
            allowedContentTypes: allowedFileTypes,
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let picked = urls.first else { return }
                do {
                    // ✅ 匯入時立即 copy 到 App sandbox（並處理 security-scoped URL）
                    let localURL = try copyToAppSandbox(originalURL: picked)
                    handleImportedFile(url: localURL)
                } catch {
                    print("❌ Failed to copy imported file: \(error)")
                    currentUploadTarget = nil
                }

            case .failure(let error):
                print("❌ fileImporter failed: \(error)")
                currentUploadTarget = nil
            }
        }
    }

    // MARK: - GET READY 內容

    private var setupContent: some View {
        VStack(spacing: 24) {
            Text("GET READY")
                .font(.system(size: 48, weight: .heavy))
                .kerning(2)
                .foregroundStyle(.white)
                .padding(.top, 20)

            HStack(alignment: .top, spacing: 24) {
                // 左側：Background + ControlBar
                VStack(spacing: 18) {
                    PanelBox(title: "Background") {
                        GridBackgroundPicker(
                            images: backgrounds,
                            selected: $selectedBackground
                        )
                        .frame(maxWidth: 880)
                    }

                    ControlBar(
                        crowd: $crowd,
                        minutes: $minutes,
                        onUpload: {
                            currentUploadTarget = .marking
                            showImporter = true
                        }
                    )
                    .padding(.top, 6)
                }

                // 右側：Script + Slides + Language
                SidePanel(
                    selectedLanguageID: $selectedLanguageID,
                    languages: languages,
                    onUploadScript: {
                        currentUploadTarget = .script
                        showImporter = true
                    },
                    onUploadSlides: {
                        currentUploadTarget = .slides
                        showImporter = true
                    }
                )
                .frame(width: 320)
            }
            .frame(maxWidth: 1220)

            Spacer(minLength: 12)
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Immersive Space Helper

    private func immersiveSpaceID(for background: String) -> String {
        switch background {
        case "Service2_pic1": return "ClassPresent1"
        case "Service2_pic2": return "ClassPresent2"
        case "Service2_pic3": return "ClassPresent3"
        case "Service2_pic4": return "ClassPresent4"
        default:              return "ClassPresent1"
        }
    }

    private func openSelectedImmersiveScene() async {
        let bg = selectedBackground ?? backgrounds.first ?? "Service2_pic1"
        let spaceID = immersiveSpaceID(for: bg)
        _ = await openImmersiveSpace(id: spaceID)
    }

    // MARK: - File Importer handling + OCR

    /// ✅ 匯入檔案時，把 security-scoped URL copy 到 App sandbox，再用 sandbox URL
    private func copyToAppSandbox(originalURL: URL) throws -> URL {
        let fm = FileManager.default

        // 使用 Application Support 目錄存放內部檔案
        let appSupport = try fm.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )

        let destURL = appSupport.appendingPathComponent(originalURL.lastPathComponent)

        // 如已有同名檔案，先刪除再覆蓋
        if fm.fileExists(atPath: destURL.path) {
            try fm.removeItem(at: destURL)
        }

        // 由於 originalURL 來自 fileImporter，有 security scope，要先取得存取權
        let started = originalURL.startAccessingSecurityScopedResource()
        defer {
            if started {
                originalURL.stopAccessingSecurityScopedResource()
            }
        }

        try fm.copyItem(at: originalURL, to: destURL)
        return destURL
    }

    private func handleImportedFile(url: URL) {
        switch currentUploadTarget {
        case .slides:
            session.slidesURL = url
            extractTextAsync(from: url) { text in
                session.slidesText = text
            }
        case .script:
            session.scriptURL = url
            extractTextAsync(from: url) { text in
                session.scriptText = text
            }
        case .marking:
            session.markingSchemeURL = url
            extractTextAsync(from: url) { text in
                // ⚠️ 對應 PresentationSession 裏面的 markingText
                session.markingText = text
            }
        case .none:
            break
        }
        currentUploadTarget = nil
    }

    private func extractTextAsync(from url: URL, completion: @escaping (String) -> Void) {
        Task.detached {
            let text = extractText(from: url)
            await MainActor.run {
                completion(text)
            }
        }
    }
}

// MARK: - Text Extraction Helper（global function）

func extractText(from url: URL) -> String {
    var result = ""

    // 1) 如果係 PDF，先試 PDFKit 直接拿文字
    if url.pathExtension.lowercased() == "pdf",
       let doc = PDFDocument(url: url) {

        var all: [String] = []
        for index in 0..<doc.pageCount {
            if let page = doc.page(at: index),
               let pageText = page.string,
               !pageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                all.append(pageText)
            }
        }

        if !all.isEmpty {
            result = all.joined(separator: "\n\n")
            return result
        }

        // 如果 PDF 無可見文字（可能係掃描），用 OCR 處理每一頁
        var ocrPieces: [String] = []
        for index in 0..<doc.pageCount {
            guard let page = doc.page(at: index) else { continue }

            let pageBounds = page.bounds(for: .mediaBox)
            let scale: CGFloat = 2.0
            let pageSize = CGSize(width: pageBounds.width * scale, height: pageBounds.height * scale)

            let imgRenderer = UIGraphicsImageRenderer(size: pageSize)
            let image = imgRenderer.image { ctx in
                UIColor.white.set()
                ctx.fill(CGRect(origin: .zero, size: pageSize))

                let context = ctx.cgContext
                context.saveGState()
                context.translateBy(x: 0, y: pageSize.height)
                context.scaleBy(x: scale, y: -scale)
                page.draw(with: .mediaBox, to: context)
                context.restoreGState()
            }

            if let ocrText = ocrImage(image) {
                ocrPieces.append(ocrText)
            }
        }

        if !ocrPieces.isEmpty {
            result = ocrPieces.joined(separator: "\n\n")
            return result
        }
    }

    // 2) 非 PDF 檔（例如單張圖片）
    if let image = UIImage(contentsOfFile: url.path) {
        if let ocrText = ocrImage(image) {
            result = ocrText
        }
    }

    return result
}

private func ocrImage(_ image: UIImage) -> String? {
    guard let cgImage = image.cgImage else { return nil }

    let request = VNRecognizeTextRequest()
    request.recognitionLevel = .accurate
    request.usesLanguageCorrection = true

    let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

    do {
        try handler.perform([request])
        let observations = request.results ?? []
        let strings: [String] = observations.compactMap { obs in
            obs.topCandidates(1).first?.string
        }
        if strings.isEmpty { return nil }
        return strings.joined(separator: "\n")
    } catch {
        print("❌ OCR failed: \(error)")
        return nil
    }
}

// MARK: - 下面小組件（原樣保留）

private struct SidePanel: View {
    @EnvironmentObject private var session: PresentationSession
    @Binding var selectedLanguageID: String?
    let languages: [LanguageItem]
    let onUploadScript: () -> Void
    let onUploadSlides: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            PanelBox(title: "Script") {
                if session.scriptURL == nil {
                    Button(action: onUploadScript) {
                        HStack(spacing: 10) {
                            Image(systemName: "icloud.and.arrow.up")
                                .font(.title2.bold())
                            Text("UPLOAD")
                                .font(.headline.weight(.heavy))
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(.ultraThinMaterial, in: Capsule())
                    }
                    .buttonStyle(.plain)
                } else {
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2.bold())
                        Text("Success")
                            .font(.headline.weight(.heavy))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color.green.opacity(0.9), in: Capsule())
                    .foregroundStyle(.white)
                }
            }
            .frame(maxWidth: .infinity)

            PanelBox(title: "PowerPoint") {
                if session.slidesURL == nil {
                    Button(action: onUploadSlides) {
                        HStack(spacing: 10) {
                            Image(systemName: "doc.on.doc")
                                .font(.title2.bold())
                            Text("UPLOAD")
                                .font(.headline.weight(.heavy))
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(.ultraThinMaterial, in: Capsule())
                    }
                    .buttonStyle(.plain)
                } else {
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2.bold())
                        Text("Success")
                            .font(.headline.weight(.heavy))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color.green.opacity(0.9), in: Capsule())
                    .foregroundStyle(.white)
                }
            }
            .frame(maxWidth: .infinity)

            PanelBox(title: "LANGUAGE") {
                ScrollView(.vertical, showsIndicators: true) {
                    VStack(spacing: 10) {
                        ForEach(languages) { item in
                            let isSel = (selectedLanguageID == item.id)
                            Button {
                                selectedLanguageID = item.id
                            } label: {
                                HStack(spacing: 10) {
                                    Text(item.flag).font(.title2)
                                    Text(item.name).font(.subheadline.weight(.semibold))
                                    Spacer()
                                }
                                .padding(10)
                                .frame(maxWidth: .infinity)
                                .background(.black.opacity(0.25),
                                            in: RoundedRectangle(cornerRadius: 12))
                                .overlay {
                                    if isSel {
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(neonGradient, lineWidth: 4)
                                    } else {
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 2)
                }
                .frame(maxHeight: 260)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(10)
        .background(.black.opacity(0.25),
                    in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
}

private struct GridBackgroundPicker: View {
    let images: [String]
    @Binding var selected: String?

    private let columns = [
        GridItem(.flexible(), spacing: 18),
        GridItem(.flexible(), spacing: 18)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 18) {
            ForEach(images, id: \.self) { name in
                let isSel = (selected == name)
                Button {
                    selected = name
                } label: {
                    let shape = RoundedRectangle(cornerRadius: 16, style: .continuous)

                    ZStack {
                        Image(name)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 220)
                            .clipShape(shape)
                    }
                    .overlay {
                        if isSel {
                            shape.stroke(neonGradient, lineWidth: 6)
                        } else {
                            shape.stroke(Color.white.opacity(0.15), lineWidth: 2)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }
}

private struct ControlBar: View {
    @Binding var crowd: VRSetupView.Crowd
    @Binding var minutes: Int
    let onUpload: () -> Void

    private let minuteOptions = Array(5...15)

    var body: some View {
        HStack(spacing: 22) {
            Menu {
                ForEach(VRSetupView.Crowd.allCases, id: \.self) { c in
                    Button(c.rawValue) { crowd = c }
                }
            } label: {
                ControlChip(icon: "person.badge.plus", title: crowd.rawValue)
                    .frame(maxWidth: .infinity)
            }
            .menuStyle(.borderlessButton)

            Menu {
                ForEach(minuteOptions, id: \.self) { m in
                    Button("\(m) MINS") { minutes = m }
                }
            } label: {
                ControlChip(icon: "clock", title: "\(minutes) MINS")
                    .frame(maxWidth: .infinity)
            }
            .menuStyle(.borderlessButton)

            Button(action: onUpload) {
                ControlChip(icon: "doc.badge.plus", title: "Marking Scheme")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.plain)
        }
        .padding(.leading, 80)
    }
}

private struct PanelBox<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline.weight(.heavy))
                .foregroundStyle(.white.opacity(0.9))
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.black.opacity(0.28), in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(neonGradient, lineWidth: 3))
    }
}

private struct ControlChip: View {
    let icon: String
    let title: String
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon).font(.headline)
            Text(title).font(.headline.weight(.semibold))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial, in: Capsule())
    }
}

struct LanguageItem: Identifiable {
    let id: String
    let flag: String
    let name: String
}

private var neonGradient: LinearGradient {
    LinearGradient(
        colors: [.purple, .blue, .purple],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

#Preview {
    VRSetupView()
        .environmentObject(PresentationSession())
}
