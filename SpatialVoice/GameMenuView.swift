// GameMenuView.swift
import SwiftUI

struct GameMenuView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace

    // 控制切去 GamePlayingView
    @State private var showPlaying = false

    var body: some View {
        ZStack {
            // 背景圖：你已經放好嘅 Game_pic1_Menu
            Image("Game_pic1_Menu")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            // 兩個 Mode Button（用你而家個位置設定）
            VStack {
                Spacer()                      // 往下推一段距離

                HStack(spacing: 50) {        // 調整兩個圈之間距離
                    ModeCircleButton(
                        title: "Story\nMode",
                        systemIcon: "book.fill",      // 書本代表 Story Mode
                        action: { /* 暫時冇功能 */ }
                    )

                    ModeCircleButton(
                        title: "Challenge\nMode",
                        systemIcon: "flag.checkered", // 旗幟代表 Challenge Mode
                        action: {
                            // 👉 按 Challenge 時：
                            // 1. 顯示 GamePlayingView（2D）
                            showPlaying = true
                        }
                    )
                }
                .padding(.bottom, 140)        // 再微調高度
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 120)       // 控制整個 HStack 向右 / 向左
            }
        }
        // 左下角 Back
        .overlay(alignment: .bottomLeading) {
            Button {
                dismiss()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                    Text("Back")
                }
                .font(.headline)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial, in: Capsule())
            }
            .buttonStyle(.plain)
            .padding(.leading, 24)
            .padding(.bottom, 24)
        }
        // 全屏彈出 GamePlayingView
        .fullScreenCover(isPresented: $showPlaying) {
            GamePlayingStep1View()
        }
    }
}

private struct ModeCircleButton: View {
    let title: String
    let systemIcon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                // 實心背景圓（不透明）
                Circle()
                    .fill(Color.white)
                    .frame(width: 220, height: 220)

                // 外圈黑色邊框
                Circle()
                    .stroke(.black, lineWidth: 8)
                    .frame(width: 220, height: 220)

                VStack(spacing: 16) {
                    Image(systemName: systemIcon)
                        .font(.system(size: 70, weight: .bold))
                        .foregroundStyle(.black)

                    Text(title)
                        .font(.system(size: 30, weight: .black))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.black)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    GameMenuView()
}
