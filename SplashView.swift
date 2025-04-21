import SwiftUI

struct SplashView: View {
    @State private var isActive = false

    var body: some View {
        ZStack {
            if isActive {
                RootView()
                    .transition(.opacity)
            } else {
                VStack(spacing: -8) {
                    Image("LOGO")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 160, height: 160)

                    Text("BOHEM")
                        .font(.system(size: 32, weight: .medium, design: .default))
                        .kerning(2)
                        .foregroundColor(.black)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                .padding(.bottom, 60) // Moves everything slightly higher
                .background(Color.white)
                .ignoresSafeArea()
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isActive = true
                }
            }
        }
    }
}
