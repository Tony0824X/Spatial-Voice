// ClassPresentationImmersiveView.swift
import SwiftUI
import RealityKit
import RealityKitContent

struct ClassPresentationImmersiveView: View {
    /// 對應 ImmersiveSpace 的場景名，例如 "ClassPresent1"
    let sceneName: String

    @EnvironmentObject private var session: PresentationSession

    // 用來存住 root entity，之後可以再搵返 Model4_QA ~ Model8_QA
    @State private var rootEntity: Entity?

    var body: some View {
        RealityView { content in
            do {
                // 1. 載入整個場景（包含 Model1 / Model2 / Model3 / Model4_QA...Model8_QA）
                let entity = try await Entity(
                    named: sceneName,
                    in: realityKitContentBundle
                )
                content.add(entity)
                rootEntity = entity

                // 2. Presentation 階段角色：即刻播 Loop（Model1 ~ Model3）
                if let model1 = entity.findEntity(named: "Model1") {
                    startLoopingAnimation(on: model1)
                } else {
                    print("⚠️ Cannot find entity named 'Model1' in scene \(sceneName)")
                }

                if let model2 = entity.findEntity(named: "Model2") {
                    startLoopingAnimation(on: model2)
                } else {
                    print("⚠️ Cannot find entity named 'Model2' in scene \(sceneName)")
                }

                if let model3 = entity.findEntity(named: "Model3") {
                    startLoopingAnimation(on: model3)
                } else {
                    print("⚠️ Cannot find entity named 'Model3' in scenes \(sceneName)")
                }
                
                if let model9 = entity.findEntity(named: "Model9") {
                    startLoopingAnimation(on: model9)
                } else {
                    print("⚠️ Cannot find entity named 'Model9' in scene \(sceneName)")
                }
                
                if let model10 = entity.findEntity(named: "Model10") {
                    startLoopingAnimation(on: model10)
                } else {
                    print("⚠️ Cannot find entity named 'Model10' in scene \(sceneName)")
                }

                // 3. Q&A 角色（Model4_QA ~ Model8_QA）：
                //    只係確認有冇搵到，但唔即刻播動畫，
                //    真正開始播係等到 session.showResult == true（即按咗 End → 進入 Q&A Session）
                if entity.findEntity(named: "Model4_QA") == nil {
                    print("⚠️ Cannot find entity named 'Model4_QA' in scene \(sceneName)")
                }
                if entity.findEntity(named: "Model5_QA") == nil {
                    print("⚠️ Cannot find entity named 'Model5_QA' in scene \(sceneName)")
                }
                if entity.findEntity(named: "Model6_QA") == nil {
                    print("⚠️ Cannot find entity named 'Model6_QA' in scene \(sceneName)")
                }
                if entity.findEntity(named: "Model7_QA") == nil {
                    print("⚠️ Cannot find entity named 'Model7_QA' in scene \(sceneName)")
                }
                if entity.findEntity(named: "Model8_QA") == nil {
                    print("⚠️ Cannot find entity named 'Model8_QA' in scene \(sceneName)")
                }

                // 如果此刻已經係 Q&A 模式（例如 re-enter immersive space），
                // 就即刻幫 Q&A models 開始 loop。
                if session.showResult {
                    startQALoopsIfNeeded()
                }

            } catch {
                print("❌ Failed to load scene \(sceneName): \(error)")
            }
        }
        .ignoresSafeArea()   // 令 3D 場景鋪滿視野
        // 當 user 喺 HUD 撳 End → session.showResult 由 false → true，
        // 呢度就會收到變化，然後幫 Q&A models 播 loop animation。
        .onChange(of: session.showResult) { newValue in
            if newValue {
                startQALoopsIfNeeded()
            }
        }
    }

    // MARK: - Q&A Models Loop Logic

    /// 喺 Q&A Session 開始時，幫 Model4_QA ~ Model8_QA 開始 loop 動畫
    private func startQALoopsIfNeeded() {
        guard let entity = rootEntity else { return }

        if let m4 = entity.findEntity(named: "Model4_QA") {
            startLoopingAnimation(on: m4)
        }
        if let m5 = entity.findEntity(named: "Model5_QA") {
            startLoopingAnimation(on: m5)
        }
        if let m6 = entity.findEntity(named: "Model6_QA") {
            startLoopingAnimation(on: m6)
        }
        if let m7 = entity.findEntity(named: "Model7_QA") {
            startLoopingAnimation(on: m7)
        }
        if let m8 = entity.findEntity(named: "Model8_QA") {
            startLoopingAnimation(on: m8)
        }
    }

    // MARK: - 動畫控制（原本的函數保持不變）

    /// 讓指定角色 entity 不斷播放它的第一個動畫，無限 loop
    private func startLoopingAnimation(on character: Entity) {
        // 先拿到 Reality Composer Pro / USDZ 裏設定好的動畫
        guard let animationResource = character.availableAnimations.first else {
            print("⚠️ '\(character.name)' has no availableAnimations")
            return
        }

        // 用 Task 做一個無限 loop
        Task.detached {
            while true {
                // 一定要喺 MainActor 上 play 動畫，因為 Entity 唔係 Sendable
                let duration: TimeInterval = await MainActor.run {
                    let controller = character.playAnimation(
                        animationResource,
                        transitionDuration: 0.0,
                        startsPaused: false
                    )
                    // 由 AnimationPlaybackController 拎 duration
                    return controller.duration
                }

                // 等到呢次動畫播完，再立即播下一次（無間斷）
                try? await Task.sleep(
                    nanoseconds: UInt64(duration * 1_000_000_000)
                )
            }
        }
    }
}
