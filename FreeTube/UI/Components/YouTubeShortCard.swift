import SwiftUI
import Kingfisher

/// Vertical Short card used in horizontal shorts shelves and Shorts tab
@available(iOS 17.0, *)
struct YouTubeShortCard: View {
    let video: Video
    var onTap: () -> Void = {}
    
    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .bottomLeading) {
                KFImage(video.thumbnailURL)
                    .placeholder {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(white: 0.15))
                    }
                    .resizable()
                    .aspectRatio(9/16, contentMode: .fill)
                    .frame(width: 145, height: 250)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        LinearGradient(
                            colors: [Color.clear, Color.black.opacity(0.8)],
                            startPoint: .center,
                            endPoint: .bottom
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    )
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(video.title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    if !video.viewCountString.isEmpty {
                        Text(video.viewCountString)
                            .font(.system(size: 11, weight: .regular))
                            .foregroundColor(.white.opacity(0.85))
                    }
                }
                .padding(10)
            }
            .frame(width: 145, height: 250)
        }
        .buttonStyle(.plain)
    }
}
