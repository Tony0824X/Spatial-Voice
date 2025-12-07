//ClassPresentationView
import SwiftUI
import UniformTypeIdentifiers

struct ClassPresentationView: View {
    // 外部可傳入返回 / 下一步動作
    var onBack: (() -> Void)? = nil
    var onNext: (() -> Void)? = nil

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var session: PresentationSession   // ⬅️ 有結果 / QA 用

    // 控制是否進入 VR 設定頁
    @State private var showVRSetup = false

    // 位置與大小
    private let rowMaxWidth: CGFloat = 540
    private let buttonMaxWidth: CGFloat = 360
    private let topSpacing: CGFloat = 370
    private let bottomSpacing: CGFloat = 40

    var body: some View {
        ZStack {
            Image("Service1_pic1")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            // 中間：兩個等大的正方形按鈕
            VStack {
                Spacer(minLength: topSpacing)

                HStack(spacing: 30) {
                    MenuSquareButton(title: "VR", icon: "visionpro") {
                        // 進入 VR 設定頁
                        showVRSetup = true
                    }
                    .frame(maxWidth: buttonMaxWidth)

                    MenuSquareButton(title: "AR", icon: "arkit") {
                        // 之後要做 AR 設定可在這裡開另一個 view
                    }
                    .frame(maxWidth: buttonMaxWidth)
                }
                .frame(maxWidth: rowMaxWidth)
                .padding(.horizontal, 24)

                Spacer(minLength: bottomSpacing)
            }
        }
        // 左下 Back
        .overlay(alignment: .bottomLeading) {
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
        // （此頁 Next 不顯示，如要用把 .hidden() 拿掉）
        .overlay(alignment: .bottomTrailing) {
            Button(action: { onNext?() }) {
                Label("Next", systemImage: "chevron.right")
                    .font(.headline)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(.ultraThinMaterial, in: Capsule())
            }
            .buttonStyle(.plain)
            .padding(.trailing, 20)
            .padding(.bottom, 20)
            .hidden()
        }
        // 以全螢幕覆蓋方式呈現 VR 設定頁
        .fullScreenCover(isPresented: $showVRSetup) {
            VRSetupView(
                onBack: { showVRSetup = false },
                onNext: {
                    // 1) 關閉 VR 設定頁
                    showVRSetup = false
                    // 2) 把「下一步」往外層傳遞（如果你之後要用）
                    onNext?()
                }
            )
        }
        // 🔹 當 TwoScreenHUDView 按 End → session.showResult = true
        //    就會喺呢度先彈出 QASessionView，再入 PresentationResultView
        .fullScreenCover(isPresented: $session.showResult) {
            QASessionView()
                .environmentObject(session)
        }
    }
}

/// 透明底、彩色描邊的正方形按鈕
private struct MenuSquareButton: View {
    let title: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [.purple.opacity(0.95),
                                             .blue.opacity(0.95),
                                             .purple.opacity(0.95)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 6
                            )
                    )

                VStack(spacing: 10) {
                    Image(systemName: icon)
                        .font(.system(size: 92, weight: .bold))
                        .foregroundStyle(.white)

                    Text(title)
                        .font(.system(size: 68, weight: .heavy))
                        .kerning(1)
                        .foregroundStyle(.white)
                        .shadow(radius: 4)
                }
                .padding(18)
            }
        }
        .buttonStyle(.plain)
        .aspectRatio(1, contentMode: .fit)
        .hoverEffect(.lift)
        .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .accessibilityLabel(Text(title))
    }
}

#Preview {
    ClassPresentationView()
        .environmentObject(PresentationSession())
}
