import Photos
import SwiftUI

struct PhotoPreview: View {
    @ObservedObject var viewModel: PhotoViewModel
    @State private var scale: CGFloat = 0.1
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
                        .frame(width: targetSize.width, height: targetSize.height)
                        .scaleEffect(scale)
                        .opacity(opacity)
                        .onTapGesture {
                            closePreview()
                        }
                }
                .ignoresSafeArea()
                .zIndex(1000)
                .onAppear {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        scale = 1.0
                        opacity = 1.0
                    }
                }
            }
        }
    }
    
    private func closePreview() {
        withAnimation(.spring(response: 0.3, dampingFraction: 1)) {
            scale = 0.1
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
