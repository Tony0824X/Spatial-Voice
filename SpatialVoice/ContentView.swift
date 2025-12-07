// ContentView.swift
import SwiftUI

// MARK: - Models

enum SVMenu: String, CaseIterable, Identifiable {
    case home = "Home"
    case games = "Games"
    case certificates = "Certificates"
    case progress = "History"
    case settings = "Setting"
    case profile = "Profile"

    var id: String { rawValue }
    var symbol: String {
        switch self {
        case .home: return "house.fill"
        case .games: return "gamecontroller.fill"
        case .certificates: return "checkmark.seal.fill"
        case .progress: return "clock.arrow.circlepath"
        case .settings: return "gearshape.fill"
        case .profile: return "person.crop.circle.fill"
        }
    }
}

enum SVCategory: String, CaseIterable, Identifiable {
    case academicPersonal = "Academic & Personal Development"
    case businessProfessional = "Business & Professional"
    case communityPublic    = "Public Education"
    case ceremonialOfficial = "Ceremonial & Official Occasions"

    var id: String { rawValue }
}

// 體驗標籤
enum SVExperience: String {
    case vr = "VR"
    case ar = "AR"
    case vrar = "VR / AR"
    var label: String { rawValue }
}

// 證書等級（標題 + 顏色）
enum CertLevel: Int, CaseIterable {
    case beginner = 0, intermediate = 1, advanced = 2
    var title: String {
        switch self {
        case .beginner:     return "Level 1 • Beginner"
        case .intermediate: return "Level 2 • Intermediate"
        case .advanced:     return "Level 3 • Advanced"
        }
    }
    var color: Color {
        switch self {
        case .beginner:     return .green
        case .intermediate: return .orange
        case .advanced:     return .red
        }
    }
}

struct SVCard: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let subtitle: String
    let imageName: String
    let category: SVCategory
    let experience: SVExperience?
}

// MARK: - Root

struct ContentView: View {
    // 🔹 注入 PresentationSession，比 Result / History 用
    @EnvironmentObject var session: PresentationSession

    @State private var selection: SVMenu? = .home
    @State private var selectedCard: SVCard?
    @State private var selectedCategory: SVCategory? = nil   // nil = 顯示全部

    // 控制是否進入 Class Presentation 體驗頁
    @State private var showClassPresentation = false

    private let cards: [SVCard] = [
        .init(title: "Class Presentation",
              subtitle: "You stand in front of the class and present your group project or research",
              imageName: "Home_pic1", category: .academicPersonal, experience: .vrar),
        .init(title: "Speech Contest",
              subtitle: "You give a prepared 5–15 minute speech in a competition",
              imageName: "Home_pic2", category: .academicPersonal, experience: .vr),

        .init(title: "Internal Company Briefing",
              subtitle: "You present project progress or data to your team or managers in a meeting room",
              imageName: "Home_pic3", category: .businessProfessional, experience: .ar),
        .init(title: "Present Product Launch",
              subtitle: "You introduce a new product on stage to customers, partners, or media",
              imageName: "Home_pic4", category: .businessProfessional, experience: .vrar),
        .init(title: "Conference Keynote or Talk",
              subtitle: "You give a 20–40 minute talk at a professional conference on a specific topic",
              imageName: "Home_pic5", category: .businessProfessional, experience: .vr),
        .init(title: "Training Session",
              subtitle: "Trainer, explaining concepts and demonstrating skills to participants",
              imageName: "Home_pic6", category: .businessProfessional, experience: .ar),
        .init(title: "Startup Pitch to Investors",
              subtitle: "You can pitch your startup to judges or investors",
              imageName: "Home_pic7", category: .businessProfessional, experience: .vrar),

        .init(title: "Community Talk",
              subtitle: "You are invited to give a talk at a school, library, NGO, or community centre",
              imageName: "Home_pic8", category: .communityPublic, experience: .vr),

        .init(title: "Ceremony Speech",
              subtitle: "Give an opening speech, thank-you speech, or wedding toast in front of all guests",
              imageName: "Home_pic9", category: .ceremonialOfficial, experience: .ar),
        .init(title: "Press Briefing",
              subtitle: "You stand at a podium and read a statement or answer questions from reporters",
              imageName: "Home_pic10", category: .ceremonialOfficial, experience: .vrar)
    ]

    var body: some View {
        NavigationSplitView {
            SidebarView(selection: $selection)
                .navigationSplitViewColumnWidth(280)
        } detail: {
            Group {
                switch selection {
                case .games:
                    GamesPageView()
                case .certificates:
                    CertificatesPageView()
                case .progress:
                    HistoryPageView()
                case .settings:
                    SettingsPageView()
                case .profile:
                    ProfilePageView()
                default:
                    MainPanelView(
                        cards: cards,
                        selection: $selection,
                        selectedCategory: $selectedCategory,
                        onTapCard: { selectedCard = $0 },
                        onOpenClassPresentation: { showClassPresentation = true }
                    )
                }
            }
            .navigationTitle("SpatialVoice")
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    Button(action: {}) { Label("Awards", systemImage: "rosette") }
                    Button(action: {}) { Label("Heart", systemImage: "heart") }
                }
            }
            .navigationSplitViewColumnWidth(min: 820, ideal: 980, max: 1200)
            // 以全螢幕覆蓋方式呈現，不會看到左側選單
            .fullScreenCover(isPresented: $showClassPresentation) {
                ClassPresentationView(
                    onBack: { showClassPresentation = false },
                    onNext: {
                        showClassPresentation = false
                        // TODO: 之後可以進到下一步（例如進入排練頁 / 錄製頁）
                    }
                )
                .environmentObject(session)
            }
        }
    }
}

// MARK: - Sidebar

private struct SidebarView: View {
    @Binding var selection: SVMenu?

    var body: some View {
        List(selection: $selection) {
            Section {
                HStack(spacing: 12) {
                    Image("Home_SpatialVoice_logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("SpatialVoice").font(.headline)
                        Text("v0.1 • visionOS")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section {
                ForEach(
                    [SVMenu.home, .games, .certificates, .progress, .settings, .profile],
                    id: \.self
                ) { item in
                    Label(item.rawValue, systemImage: item.symbol)
                        .tag(item)
                }
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("Menu")
    }
}

// MARK: - Home Main Panel

private struct MainPanelView: View {
    let cards: [SVCard]
    @Binding var selection: SVMenu?
    @Binding var selectedCategory: SVCategory?
    let onTapCard: (SVCard) -> Void
    // 點「Class Presentation」要打開體驗頁
    let onOpenClassPresentation: () -> Void

    private var filteredCards: [SVCard] {
        guard let cat = selectedCategory else { return cards }
        return cards.filter { $0.category == cat }
    }

    var body: some View {
        ScrollView {
            HStack {
                VStack(spacing: 24) {
                    header()

                    let columns = [GridItem(.adaptive(minimum: 300, maximum: 520), spacing: 20)]
                    LazyVGrid(columns: columns, spacing: 20) {
                        ForEach(filteredCards) { card in
                            MenuCardView(card: card)
                                .onTapGesture {
                                    if card.title == "Class Presentation" {
                                        onOpenClassPresentation()
                                    } else {
                                        onTapCard(card)
                                    }
                                }
                        }
                    }
                    .padding(.horizontal, 12)
                }
                .padding(.vertical, 20)
                .frame(maxWidth: 980)
            }
            .frame(maxWidth: .infinity)
        }
        .background(.clear)
    }

    private func header() -> some View {
        VStack(spacing: 12) {
            Text("Welcome to SpatialVoice")
                .font(.largeTitle.bold())
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 10) {
                ForEach(SVCategory.allCases) { cat in
                    Button {
                        selectedCategory = (selectedCategory == cat) ? nil : cat
                    } label: {
                        Text(cat.rawValue)
                            .font(.subheadline.weight(.semibold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                (selectedCategory == cat ? Color.accentColor.opacity(0.15) : Color.clear),
                                in: Capsule()
                            )
                            .overlay(
                                Capsule().strokeBorder(
                                    selectedCategory == cat ? Color.accentColor.opacity(0.6) : Color.secondary.opacity(0.25),
                                    lineWidth: 1
                                )
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 12)
    }
}

// MARK: - Home Card

private struct MenuCardView: View {
    let card: SVCard
    @State private var isFavorite = false

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 24, style: .continuous)

        ZStack {
            Image(card.imageName)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
        }
        .frame(minWidth: 300, maxWidth: 520, minHeight: 220, maxHeight: 320)
        .clipShape(shape)
        .overlay(
            LinearGradient(colors: [.clear, .black.opacity(0.18), .black.opacity(0.26)],
                           startPoint: .top, endPoint: .bottom)
                .clipShape(shape)
        )
        .overlay(alignment: .bottom) {
            GeometryReader { geo in
                let barH = max(60, min(geo.size.height * 0.27, 120))
                ZStack(alignment: .bottomLeading) {
                    Rectangle()
                        .fill(Color(.systemGray6).opacity(0.92))
                        .frame(height: barH)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(card.title)
                            .font(.title3.bold())
                            .foregroundStyle(.primary)
                        Text(card.subtitle)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 14)
                    .padding(.bottom, 12)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            }
            .allowsHitTesting(false)
            .clipShape(shape)
        }
        .overlay(alignment: .topLeading) {
            if let exp = card.experience {
                Text(exp.label)
                    .font(.headline.bold())
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .foregroundStyle(.white)
                    .background(Color.green.opacity(0.92), in: Capsule())
                    .padding(12)
                    .allowsHitTesting(false)
            }
        }
        .overlay(
            Button { isFavorite.toggle() } label: {
                Image(systemName: isFavorite ? "heart.fill" : "heart")
                    .font(.title2)
                    .padding(10)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(isFavorite ? .red : .white)
            .padding(10),
            alignment: .topTrailing
        )
        .overlay(shape.stroke(.white.opacity(0.08), lineWidth: 1))
        .contentShape(shape)
        .hoverEffect(.lift)
        .accessibilityLabel(Text(card.title))
    }
}

// MARK: - Games Page

private struct GamesPageView: View {
    private let heroImages = (1...3).map { "Game_pic1_\($0)" }
    private let listImages = (1...6).map { "Game_pic2_\($0)" }

    private func experience(for index: Int) -> SVExperience {
        switch index % 3 {
        case 0: return .vrar
        case 1: return .vr
        default: return .ar
        }
    }

    var body: some View {
        VStack(spacing: 18) {
            Text("Top 3 Games This Week")
                .font(.largeTitle.bold())
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(Array(heroImages.enumerated()), id: \.offset) { i, name in
                        HeroTile(imageName: name, experience: experience(for: i))
                    }
                }
                .padding(.horizontal, 12)
            }
            .frame(height: 260)

            GeometryReader { geo in
                ScrollView(.vertical) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("All Games")
                            .font(.title2.bold())
                            .padding(.horizontal, 12)

                        let cols = [GridItem(.adaptive(minimum: 320, maximum: 520), spacing: 16)]
                        LazyVGrid(columns: cols, spacing: 16) {
                            ForEach(Array(listImages.enumerated()), id: \.offset) { i, name in
                                GameTile(imageName: name, experience: experience(for: i))
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.bottom, 20)
                    }
                }
                .frame(height: geo.size.height)
            }
        }
        .padding(.vertical, 16)
        .frame(maxWidth: 980)
        .frame(maxWidth: .infinity, alignment: .center)
        .background(.clear)
    }
}

private struct HeroTile: View {
    let imageName: String
    let experience: SVExperience?
    @State private var isFavorite = false

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 22, style: .continuous)
        ZStack {
            Image(imageName)
                .resizable()
                .scaledToFill()
                .frame(width: 420, height: 240)
                .clipped()
        }
        .frame(width: 420, height: 240)
        .clipShape(shape)
        .overlay(alignment: .topLeading) {
            if let exp = experience {
                Text(exp.label)
                    .font(.headline.bold())
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .foregroundStyle(.white)
                    .background(Color.green.opacity(0.92), in: Capsule())
                    .padding(10)
                    .allowsHitTesting(false)
            }
        }
        .overlay(
            Button { isFavorite.toggle() } label: {
                Image(systemName: isFavorite ? "heart.fill" : "heart")
                    .font(.title2)
                    .padding(10)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(isFavorite ? .red : .white)
            .padding(10),
            alignment: .topTrailing
        )
        .overlay(shape.stroke(.white.opacity(0.08), lineWidth: 1))
        .contentShape(shape)
        .hoverEffect(.lift)
    }
}

private struct GameTile: View {
    let imageName: String
    let experience: SVExperience?
    @State private var isFavorite = false

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 22, style: .continuous)
        ZStack(alignment: .bottomLeading) {
            Image(imageName)
                .resizable()
                .scaledToFill()
                .frame(minHeight: 180, maxHeight: 260)
                .clipped()

            LinearGradient(colors: [.clear, .black.opacity(0.25), .black.opacity(0.35)],
                           startPoint: .top, endPoint: .bottom)
                .clipShape(shape)
        }
        .clipShape(shape)
        .overlay(alignment: .topLeading) {
            if let exp = experience {
                Text(exp.label)
                    .font(.headline.bold())
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .foregroundStyle(.white)
                    .background(Color.green.opacity(0.92), in: Capsule())
                    .padding(10)
                    .allowsHitTesting(false)
            }
        }
        .overlay(
            Button { isFavorite.toggle() } label: {
                Image(systemName: isFavorite ? "heart.fill" : "heart")
                    .font(.title2)
                    .padding(10)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(isFavorite ? .red : .white)
            .padding(10),
            alignment: .topTrailing
        )
        .overlay(shape.stroke(.white.opacity(0.08), lineWidth: 1))
        .contentShape(shape)
        .hoverEffect(.lift)
    }
}

// MARK: - Certificates Page

private struct CertificatesPageView: View {
    private let sec1 = (1...3).map { "Certificates_pic1_\($0)" }
    private let sec2 = (1...3).map { "Certificates_pic2_\($0)" }
    private let sec3 = (1...3).map { "Certificates_pic3_\($0)" }

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                Text("Certificates")
                    .font(.largeTitle.bold())
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 12)

                certificateRow(sectionTitle: "Story Telling", images: sec1)
                certificateRow(sectionTitle: "Connect with Audience", images: sec2)
                certificateRow(sectionTitle: "Body Language", images: sec3)
            }
            .padding(.vertical, 16)
            .frame(maxWidth: 980)
            .frame(maxWidth: .infinity, alignment: .center)
            .background(.clear)
        }
    }

    private func certificateRow(sectionTitle: String, images: [String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(sectionTitle)
                .font(.title3.bold())
                .padding(.horizontal, 12)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(Array(images.enumerated()), id: \.offset) { idx, name in
                        let level = CertLevel(rawValue: idx) ?? .beginner
                        CertificateTile(imageName: name, level: level)
                    }
                }
                .padding(.horizontal, 12)
            }
            .frame(height: 220)
        }
    }
}

private struct CertificateTile: View {
    let imageName: String
    let level: CertLevel
    @State private var isFavorite = false

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 20, style: .continuous)
        ZStack {
            Image(imageName)
                .resizable()
                .scaledToFill()
                .frame(width: 360, height: 200)
                .clipped()
        }
        .frame(width: 360, height: 200)
        .clipShape(shape)
        .overlay(
            Text(level.title)
                .font(.headline.bold())
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .foregroundStyle(.white)
                .background(level.color.opacity(0.95), in: Capsule())
                .padding(10)
                .allowsHitTesting(false),
            alignment: .topLeading
        )
        .overlay(
            Button { isFavorite.toggle() } label: {
                Image(systemName: isFavorite ? "heart.fill" : "heart")
                    .font(.title2)
                    .padding(10)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(isFavorite ? .red : .white)
            .padding(10),
            alignment: .topTrailing
        )
        .overlay(shape.stroke(.white.opacity(0.08), lineWidth: 1))
        .contentShape(shape)
        .hoverEffect(.lift)
    }
}

// MARK: - History Page

private enum HistoryTab: String, CaseIterable, Identifiable {
    case practice  = "Public Speaking Practice"
    case game      = "Game"
    case certificate = "Certificate"

    var id: String { rawValue }
}

private struct HistoryPageView: View {
    @EnvironmentObject private var session: PresentationSession
    @State private var selectedTab: HistoryTab = .practice

    var body: some View {
        VStack(spacing: 18) {
            Text("History")
                .font(.largeTitle.bold())
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12)

            tabSwitcher
                .padding(.horizontal, 12)

            ScrollView {
                VStack(spacing: 18) {
                    switch selectedTab {
                    case .practice:
                        if session.practiceRecords.isEmpty {
                            emptyHint(text: "No Class Presentation records yet.\nFinish a practice to see your AI scores here.")
                        } else {
                            ForEach(session.practiceRecords) { record in
                                PracticeHistoryRow(record: record)
                            }
                        }
                    case .game:
                        if session.gameRecords.isEmpty {
                            emptyHint(text: "No game records yet.")
                        } else {
                            ForEach(session.gameRecords) { record in
                                GameHistoryRow(record: record)
                            }
                        }
                    case .certificate:
                        if session.certificateRecords.isEmpty {
                            emptyHint(text: "No certificate records yet.")
                        } else {
                            ForEach(session.certificateRecords) { record in
                                CertificateHistoryRow(record: record)
                            }
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 20)
                .frame(maxWidth: 980)
            }
        }
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, alignment: .center)
        .background(
            LinearGradient(
                colors: [Color(red: 15/255, green: 10/255, blue: 45/255),
                         Color(red: 5/255, green: 5/255, blue: 25/255)],
                startPoint: .top,
                endPoint: .bottom
            )
            .opacity(0.85)
        )
    }

    private var tabSwitcher: some View {
        HStack(spacing: 10) {
            ForEach(HistoryTab.allCases) { tab in
                Button {
                    selectedTab = tab
                } label: {
                    Text(tab.rawValue)
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity)
                        .background(
                            selectedTab == tab
                            ? Color.white
                            : Color.white.opacity(0.05)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    selectedTab == tab
                                    ? Color.purple.opacity(0.7)
                                    : Color.white.opacity(0.15),
                                    lineWidth: 1.5
                                )
                        )
                        .foregroundStyle(
                            selectedTab == tab
                            ? Color(red: 35/255, green: 20/255, blue: 90/255)
                            : .white
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func emptyHint(text: String) -> some View {
        Text(text)
            .font(.footnote)
            .foregroundStyle(.white.opacity(0.7))
            .multilineTextAlignment(.center)
            .padding(.vertical, 40)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.black.opacity(0.25))
            )
    }
}

// MARK: - Practice History Row (Class Presentation)

private struct PracticeHistoryRow: View {
    let record: PracticeRecord   // 定義喺 PresentationSession.swift

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .short
        f.timeStyle = .short
        return f
    }()

    private var dateString: String {
        PracticeHistoryRow.dateFormatter.string(from: record.date)
    }

    private func scoreText(_ value: Double?) -> String {
        guard let v = value else { return "--" }
        return String(format: "%.1f", v)
    }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 26, style: .continuous)

        HStack(alignment: .top, spacing: 18) {
            // 左邊：時間 + icon
            VStack(spacing: 10) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(Color(red: 40/255, green: 40/255, blue: 80/255))
                    .padding(10)
                    .background(Color.white, in: Circle())

                Text(dateString)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color(red: 0.60, green: 0.05, blue: 0.05))
                    .multilineTextAlignment(.center)

            }
            .frame(width: 120)

            VStack(alignment: .leading, spacing: 10) {
                Text(record.scenarioTitle)
                    .font(.headline.weight(.heavy))
                    .foregroundStyle(Color(red: 35/255, green: 20/255, blue: 80/255))

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                    HistoryMetricChip(
                        title: "Verbal / Content",
                        value: scoreText(record.verbalScore)
                    )
                    HistoryMetricChip(
                        title: "Vocal Delivery",
                        value: record.vocalLabel
                    )
                    HistoryMetricChip(
                        title: "Non-verbal / Body Language",
                        value: record.nonverbalLabel
                    )
                    HistoryMetricChip(
                        title: "Visual Aids / Slides",
                        value: scoreText(record.visualScore)
                    )
                    HistoryMetricChip(
                        title: "Time Management",
                        value: scoreText(record.timeScore)
                    )
                    HistoryMetricChip(
                        title: "Audience Engagement",
                        value: scoreText(record.audienceScore)
                    )
                }
                .padding(.top, 4)
            }

            Spacer()

            VStack(spacing: 10) {
                Text("Share")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 8)
                    .background(Color.red, in: RoundedRectangle(cornerRadius: 14, style: .continuous))

                Text("Detail")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 8)
                    .background(Color(red: 215/255, green: 200/255, blue: 255/255),
                                in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
        .padding(16)
        .background(
            shape
                .fill(Color(red: 250/255, green: 248/255, blue: 255/255))
        )
        .overlay(
            shape
                .stroke(Color.purple.opacity(0.12), lineWidth: 2)
        )
    }
}

private struct HistoryMetricChip: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption2.weight(.semibold))
                .multilineTextAlignment(.center)
            Text(value)
                .font(.headline.weight(.bold))
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 8)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(red: 255/255, green: 234/255, blue: 150/255))
        )
        .foregroundStyle(Color(red: 70/255, green: 50/255, blue: 20/255))
    }
}

// MARK: - Game History Row（假資料 UI）

private struct GameHistoryRow: View {
    let record: GameRecord   // 定義喺 PresentationSession.swift

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }()

    private var dateString: String {
        GameHistoryRow.dateFormatter.string(from: record.date)
    }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 24, style: .continuous)

        HStack(spacing: 16) {
            Image(record.imageName)
                .resizable()
                .scaledToFill()
                .frame(width: 180, height: 110)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(record.title)
                        .font(.headline.weight(.heavy))
                        .foregroundStyle(.white)
                    Spacer()
                    Text(record.modeLabel)
                        .font(.caption.weight(.bold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.green, in: Capsule())
                        .foregroundStyle(.black)
                }

                Text(dateString)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))

                HStack(spacing: 8) {
                    Text("Best Score:")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.8))
                    Text("\(record.bestScore)")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.yellow)
                    Spacer()
                }
                .padding(.top, 2)
            }
        }
        .padding(14)
        .background(
            shape
                .fill(
                    LinearGradient(
                        colors: [Color(red: 80/255, green: 35/255, blue: 160/255),
                                 Color(red: 35/255, green: 15/255, blue: 85/255)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            shape.stroke(Color.white.opacity(0.15), lineWidth: 1)
        )
    }
}

// MARK: - Certificate History Row（假資料 UI）

private struct CertificateHistoryRow: View {
    let record: CertificateRecord   // 定義喺 PresentationSession.swift

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f
    }()

    private var dateString: String {
        CertificateHistoryRow.dateFormatter.string(from: record.date)
    }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 24, style: .continuous)

        HStack(spacing: 16) {
            Image(record.imageName)
                .resizable()
                .scaledToFill()
                .frame(width: 170, height: 110)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            VStack(alignment: .leading, spacing: 6) {
                Text(record.trackTitle)
                    .font(.headline.weight(.heavy))
                Text(record.levelTitle)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.blue)

                Text(dateString)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                Text("View")
                    .font(.subheadline.weight(.bold))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.blue.opacity(0.1), in: Capsule())
                Text("Share")
                    .font(.subheadline.weight(.bold))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.green.opacity(0.12), in: Capsule())
            }
        }
        .padding(14)
        .background(
            shape
                .fill(Color(.systemBackground).opacity(0.96))
        )
        .overlay(
            shape.stroke(Color(.separator).opacity(0.4), lineWidth: 1)
        )
    }
}

// MARK: - Settings Page

private struct SettingsPageView: View {
    @State private var query: String = ""

    private struct SettingItem: Identifiable {
        let id = UUID()
        let icon: String
        let title: String
        let subtitle: String
    }

    private let items: [SettingItem] = [
        .init(icon: "laptopcomputer", title: "System", subtitle: "Display, notifications"),
        .init(icon: "printer.fill", title: "Devices", subtitle: "Bluetooth, Apple Devices"),
        .init(icon: "globe", title: "Network & Internet", subtitle: "Wi-Fi, airplane mode"),
        .init(icon: "paintbrush.fill", title: "Personalization", subtitle: "Background, colors"),
        .init(icon: "person.crop.circle", title: "Accounts", subtitle: "Sign-in, sync settings"),
        .init(icon: "character.book.closed.fill", title: "Language", subtitle: "Region")
    ]

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text("Settings")
                    .font(.largeTitle.bold())
                Spacer()
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                    TextField("Find a setting", text: $query)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                .frame(maxWidth: 420)
            }
            .padding(.horizontal, 12)

            let cols = [GridItem(.adaptive(minimum: 260, maximum: 320), spacing: 24)]
            LazyVGrid(columns: cols, spacing: 24) {
                ForEach(items.filter { query.isEmpty ? true :
                    ($0.title + " " + $0.subtitle).localizedCaseInsensitiveContains(query)
                }) { item in
                    SettingTile(icon: item.icon, title: item.title, subtitle: item.subtitle)
                }
            }
            .padding(.horizontal, 12)

            Spacer(minLength: 0)
        }
        .padding(.vertical, 16)
        .frame(maxWidth: 980)
        .frame(maxWidth: .infinity, alignment: .center)
        .background(.clear)
    }
}

private struct SettingTile: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        Button(action: {}) {
            HStack(alignment: .top, spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(.systemGray6))
                        .frame(width: 56, height: 56)
                    Image(systemName: icon)
                        .imageScale(.large)
                        .font(.title2)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.thinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.white.opacity(0.06), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .hoverEffect(.lift)
    }
}

// MARK: - Profile Page

private struct ProfilePageView: View {
    @State private var fullName: String = ""
    @State private var nickName: String = ""
    @State private var gender: String = ""
    @State private var country: String = ""
    @State private var language: String = ""
    @State private var timeZone: String = ""

    private let genders = ["Female", "Male", "Non-binary", "Prefer not to say"]
    private let countries = ["Hong Kong", "Taiwan", "Japan", "United States", "United Kingdom"]
    private let languages = ["English", "繁體中文", "日本語"]
    private let timeZones = ["GMT+8 (HKT/TST)", "GMT+9 (JST)", "GMT+0 (UTC)"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack(alignment: .center, spacing: 16) {
                    Image("Profile_pic1")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 56, height: 56)
                        .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 2) {
                        Text(fullName.isEmpty ? "Tony HO" : fullName)
                            .font(.headline)
                        Text("tony030824@gmail.com")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Button {
                        // 編輯示意
                    } label: {
                        Text("Edit")
                            .font(.callout.weight(.semibold))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.top, 6)

                let col = [GridItem(.flexible(minimum: 260), spacing: 20),
                           GridItem(.flexible(minimum: 260), spacing: 20)]
                LazyVGrid(columns: col, spacing: 16) {
                    LabeledTextField(title: "Full Name", text: $fullName, placeholder: "HO")
                    LabeledTextField(title: "Nick Name", text: $nickName, placeholder: "Chun Chit")

                    LabeledMenu(title: "Gender", selection: $gender, placeholder: "Male",
                                options: genders, systemIcon: "chevron.down")
                    LabeledMenu(title: "Country", selection: $country, placeholder: "Hong Kong, China",
                                options: countries, systemIcon: "chevron.down")

                    LabeledMenu(title: "Language", selection: $language, placeholder: "English",
                                options: languages, systemIcon: "chevron.down")
                    LabeledMenu(title: "Time Zone", selection: $timeZone, placeholder: "GMT+8 (HKT/TST)",
                                options: timeZones, systemIcon: "chevron.down")
                }
                .padding(.horizontal, 12)

                VStack(alignment: .leading, spacing: 12) {
                    Text("My Devices")
                        .font(.headline)

                    deviceRow(icon: "iphone", title: "iPhone", subtitle: "iPhone 15 Pro")
                    deviceRow(icon: "laptopcomputer", title: "Macbook", subtitle: "Macbook M2 1TB")
                    deviceRow(icon: "visionpro", title: "Vision Pro", subtitle: "Vision Pro 512 GB")

                    Button {
                        // 登出示意
                    } label: {
                        HStack {
                            Image(systemName: "power.circle.fill")
                            Text("Log Out")
                                .font(.callout.weight(.semibold))
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 12)

                Spacer(minLength: 12)
            }
            .padding(.vertical, 16)
            .frame(maxWidth: 980)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(.clear)
    }

    private func deviceRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(Color(.systemGray6))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline)
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(.thinMaterial))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color.white.opacity(0.06), lineWidth: 1))
    }
}

// 共用：上方有標題的輸入框
private struct LabeledTextField: View {
    let title: String
    @Binding var text: String
    let placeholder: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.footnote).foregroundStyle(.secondary)
            TextField(placeholder, text: $text)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
    }
}

// 共用：上方有標題的選單（右側有小箭頭）
private struct LabeledMenu: View {
    let title: String
    @Binding var selection: String
    let placeholder: String
    let options: [String]
    let systemIcon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.footnote).foregroundStyle(.secondary)
            HStack {
                Menu {
                    ForEach(options, id: \.self) { opt in
                        Button(opt) { selection = opt }
                    }
                } label: {
                    HStack {
                        Text(selection.isEmpty ? placeholder : selection)
                            .foregroundStyle(selection.isEmpty ? .secondary : .primary)
                        Spacer()
                        Image(systemName: systemIcon)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ContentView()
        .environmentObject(PresentationSession())
}
