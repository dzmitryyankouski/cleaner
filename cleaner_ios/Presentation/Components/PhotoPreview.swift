import Photos
import SwiftUI

struct PhotoPreview: View {
    @ObservedObject var viewModel: PhotoViewModel
    @State private var animatedFrame: CGRect = .zero
    @State private var opacity: Double = 0
    
    private let targetSize = CGSize(width: 300, height: 400)

    var body: some View {
        Group {
            if viewModel.previewPhoto != nil {
                ZStack {
                    Color.black
                        .opacity(opacity * 0.8)
                        .ignoresSafeArea()
                        .onTapGesture {
                            closePreview()
                        }

                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .cornerRadius(16)
                        .frame(width: animatedFrame.width, height: animatedFrame.height)
                        .position(
                            x: animatedFrame.midX,
                            y: animatedFrame.midY
                        )
                        .opacity(opacity)
                        .onTapGesture {
                            closePreview()
                        }
                }
                .ignoresSafeArea()
                .zIndex(1000)
                .onAppear {
                    animatedFrame = viewModel.previewSourceFrame
                    
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        let screenSize = UIScreen.main.bounds
                        let targetX = (screenSize.width - targetSize.width) / 2
                        let targetY = (screenSize.height - targetSize.height) / 2
                        
                        animatedFrame = CGRect(
                            x: targetX,
                            y: targetY,
                            width: targetSize.width,
                            height: targetSize.height
                        )
                        opacity = 1.0
                    }
                }
            }
        }
    }
    
    private func closePreview() {
        withAnimation(.spring(response: 0.3, dampingFraction: 1)) {
            // Анимируем обратно к исходной позиции
            animatedFrame = viewModel.previewSourceFrame
        }
        
        // Отдельная анимация для opacity с правильным timing
        withAnimation(.easeOut(duration: 0.25)) {
            opacity = 0
        }
        
        // Очищаем после завершения анимации (должно быть больше чем duration анимации)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            viewModel.clearPreviewPhoto()
        }
    }
}
