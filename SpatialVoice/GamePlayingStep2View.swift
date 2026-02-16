import SwiftUI

struct GamePlayingStep2View: View {
    @Binding var coins: Int

    var body: some View {
        ZStack {
            Image("Game_playing_step2")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            // 金幣 UI
            VStack {
                HStack {
                    Spacer()
                    HStack(spacing: 6) {
                        Image(systemName: "bitcoinsign.circle.fill")
                            .font(.title2)
                            .foregroundColor(.yellow)
                        Text("\(coins)")
                            .font(.title3.bold())
                            .foregroundColor(.white)
                    }
                    .padding(8)
                    .background(Color.black.opacity(0.6), in: RoundedRectangle(cornerRadius: 10))
                    .offset(y: 0)
                    .padding(.trailing, 28)
                }
                Spacer()
            }

            // Next 按鈕 改成導向 GamePlayingStep3View
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    NavigationLink(destination: GamePlayingStep3View(coins: $coins)) {

                        Text("Next")
                            .font(.headline.weight(.bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 22)
                            .padding(.vertical, 10)
                    }
                    .offset(y: -80)
                    .padding(.trailing, 32)
                }
            }
        }
    }
}

struct GamePlayingStep2View_Previews: PreviewProvider {
    @State static var previewCoins = 500

    static var previews: some View {
        GamePlayingStep2View(coins: $previewCoins)
            .previewLayout(.fixed(width: 800, height: 600))
    }
}
