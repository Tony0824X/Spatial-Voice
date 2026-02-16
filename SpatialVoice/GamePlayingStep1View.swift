import SwiftUI
import UniformTypeIdentifiers

struct GamePlayingStep1View: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showImporter: Bool = false
    @State private var uploadedFiles: [URL] = []
    @State private var coins: Int = 0

    private let allowedTypes: [UTType] = [.pdf]

    // layout config
    private let tableWidthRatio: CGFloat = 0.33
    private let tableOffsetY: CGFloat = 250

    var body: some View {
        NavigationStack {
            ZStack {
                // 背景
                Image("Game_playing_step1")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()

                // 金幣 UI
                VStack {
                    HStack {
                        Spacer()
                        HStack(spacing: 6) {
                            Image(systemName: "bitcoinsign.circle.fill")
                                .font(.title2).foregroundColor(.yellow)
                            Text("\(coins)")
                                .font(.title3.bold())
                                .foregroundColor(.white)
                        }
                        .padding(8)
                        .background(Color.black.opacity(0.6), in: RoundedRectangle(cornerRadius: 10))
                        .padding(.trailing, 28)
                        .padding(.top, 0)
                    }
                    Spacer()
                }

                // 主內容
                VStack(alignment: .leading, spacing: 6) {

                    Spacer().frame(height: tableOffsetY)

                    GeometryReader { geo in
                        VStack(alignment: .leading, spacing: 22) {

                            // Table Rows
                            VStack(spacing: 6) {
                                ForEach(0..<5, id: \.self) { idx in
                                    HStack {
                                        if idx < uploadedFiles.count {
                                            Image(systemName: "doc.text")
                                                .foregroundColor(.black)
                                            Text(uploadedFiles[idx].lastPathComponent)
                                                .foregroundColor(.black)
                                                .lineLimit(1)

                                            Spacer()

                                            Button {
                                                removeFile(uploadedFiles[idx])
                                            } label: {
                                                Image(systemName: "trash.fill")
                                                    .foregroundColor(.red)
                                            }
                                        } else {
                                            Text("No file").foregroundColor(.gray)
                                            Spacer()
                                        }
                                    }
                                    .padding()
                                    .frame(width: geo.size.width * tableWidthRatio, alignment: .leading)
                                    .background(Color.white)
                                    .cornerRadius(8)
                                }
                            }
                            .padding(.leading, 58)

                            // Upload 按鈕
                            Button {
                                showImporter = true
                            } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: "arrow.up.doc.fill")
                                    Text("Upload Job Description")
                                        .font(.headline.weight(.semibold))
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 18)
                                .padding(.vertical, 10)
                            }
                            .disabled(uploadedFiles.count >= 5)
                            .opacity(uploadedFiles.count >= 5 ? 0.5 : 1.0)
                            .padding(.leading, 58)

                        }
                    }
                    .frame(height: 300)

                    Spacer()
                }

            }
            // 🛠 解決上方遮罩模糊
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)

            // 只有 icon 的返回鍵
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.white)
                    }
                }
            }

            .overlay(alignment: .bottomTrailing) {
                NavigationLink(destination: GamePlayingStep2View(coins: $coins)) {
                    Text("Next")
                        .font(.headline.weight(.bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 22)
                        .padding(.vertical, 10)
                }
                .padding(.trailing, 32)
                .padding(.bottom, 68)
            }
            .fileImporter(
                isPresented: $showImporter,
                allowedContentTypes: allowedTypes,
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    if let pdf = urls.first {
                        addFile(pdf)
                    }
                case .failure:
                    break
                }
            }
        }
    }

    private func addFile(_ url: URL) {
        if uploadedFiles.count < 5 && !uploadedFiles.contains(url) {
            uploadedFiles.append(url)
            coins += 50
        }
    }

    private func removeFile(_ url: URL) {
        if let idx = uploadedFiles.firstIndex(of: url) {
            uploadedFiles.remove(at: idx)
            coins = max(coins - 50, 0)
        }
    }
}
