import SwiftUI

/// Brand logo for HoàngHa — replaces the standard YouTube logo.
/// Displays YouTube's iconic red play button badge alongside "HoàngHa" typography.
struct HoangHaLogoView: View {
    var body: some View {
        HStack(spacing: 6) {
            ZStack {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(Color(red: 1.0, green: 0.0, blue: 0.0)) // YouTube Red
                    .frame(width: 28, height: 20)
                
                Image(systemName: "play.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 9, height: 9)
                    .foregroundColor(.white)
                    .offset(x: 0.5)
            }
            
            Text("HoàngHa")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .tracking(-0.4)
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        HoangHaLogoView()
    }
}
