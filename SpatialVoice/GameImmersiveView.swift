import SwiftUI
import RealityKit
import RealityKitContent
import AVFoundation

struct GameImmersiveView: View {
    @State private var rootEntity: Entity?
    @State private var audioPlayer: AVAudioPlayer?

    @State private var tappedEntity: Entity?

    var body: some View {
        RealityView { content in
            do {
                let sceneEntity = try await Entity(
                    named: "Gameroom1",
                    in: realityKitContentBundle
                )

                // MARK: ─ 設定可互動 + 產生碰撞體
                for name in ["mha1","mha2","mha3","mha4"] {
                    if let e = sceneEntity.findEntity(named: name) {
                        print("🔍 找到角色:", name)
                        e.components.set(InputTargetComponent())
                        e.generateCollisionShapes(recursive: true)
                        startLoopingAnimation(on: e)
                    } else {
                        print("⚠️ 動畫主體不在場景裡:", name)
                    }
                }

                content.add(sceneEntity)
                rootEntity = sceneEntity

            } catch {
                print("❌ 載入 Gameroom1 失敗:", error)
            }
        }
        .gesture(
            TapGesture()
                .targetedToAnyEntity()
                .onEnded { value in
                    print("👉 TapGesture fired")
                    if let name = value.entity.name as String? {
                        print("🧍 命中 entity:", name)
                    }
                    tappedEntity = value.entity
                    handleTap(on: value.entity)
                }
        )
        .ignoresSafeArea()
    }

    // MARK: - Tap 點擊處理（往上找真正角色根節點）
    private func handleTap(on entity: Entity) {
        print("📌 handleTap called with:", entity.name)

        var current: Entity? = entity
        while let e = current {
            print("↗️ 檢查 entity:", e.name)
            if ["mha1","mha2","mha3","mha4"].contains(e.name) {
                print("🎯 找到對應角色:", e.name)
                playVoiceForCharacter(name: e.name)
                return
            }
            current = e.parent
        }
        print("❌ 沒有找到角色根節點!")
    }

    // MARK: - 依角色名字播放對應音檔
    private func playVoiceForCharacter(name: String) {
        switch name {
        case "mha1":
            print("📣 播放 tell_me_about_yourself")
            playVoice(named: "tell_me_about_yourself")
        case "mha2":
            print("📣 播放 why_do_you_want_to_work_here")
            playVoice(named: "why_do_you_want_to_work_here")
        case "mha3":
            print("📣 播放 why_do_you_want_this_position")
            playVoice(named: "why_do_you_want_this_position")
        case "mha4":
            print("📣 播放 why_are_you_leaving_current_job")
            playVoice(named: "why_are_you_leaving_current_job")
        default:
            print("❓ playVoiceForCharacter: 不支援的角色 \(name)")
        }
    }

    // MARK: - Audio 播放
    private func playVoice(named fileName: String) {
        print("🔊 playVoice called for:", "\(fileName).mp3")

        guard let url = Bundle.main.url(
            forResource: fileName,
            withExtension: "mp3"
        ) else {
            print("❌ 找不到音檔:", "\(fileName).mp3")
            return
        }

        print("🔗 音檔路徑:", url)

        do {
            let player = try AVAudioPlayer(contentsOf: url)
            audioPlayer = player
            player.volume = 1.0
            let success = player.play()
            print("🎧 audioPlayer.play() success:", success)
        } catch {
            print("❌ 播放失敗:", error)
        }
    }

    // MARK: - Animation Loop
    private func startLoopingAnimation(on character: Entity) {
        guard let animationResource = character.availableAnimations.first else {
            print("⚠️ \(character.name) 沒有可用動畫")
            return
        }

        Task.detached {
            while true {
                let duration: TimeInterval = await MainActor.run {
                    let controller = character.playAnimation(
                        animationResource,
                        transitionDuration: 0.0,
                        startsPaused: false
                    )
                    return controller.duration
                }
                try? await Task.sleep(
                    nanoseconds: UInt64(duration * 1_000_000_000)
                )
            }
        }
    }
}

#Preview {
    GameImmersiveView()
}
