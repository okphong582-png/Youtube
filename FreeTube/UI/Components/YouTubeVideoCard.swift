import SwiftUI
import Kingfisher

/// Full-width video card matching the exact aesthetics of "Youtube giao diện",
/// backed by real data from `Video`, with Kingfisher async image loading,
/// duration badge, channel avatar, and interactive tap playback.
@available(iOS 17.0, *)
struct YouTubeVideoCard: View {
    let video: Video
    var onTap: () -> Void = {}
    
    private var metadataSubtitle: String {
        let parts = [video.channelName, video.viewCountString, video.publishedRelative ?? ""]
            .filter { !$0.isEmpty }
        return parts.joined(separator: " · ")
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Thumbnail with duration overlay
            Button(action: onTap) {
                ZStack(alignment: .bottomTrailing) {
                    KFImage(video.thumbnailURL)
                        .placeholder {
                            Rectangle()
                                .fill(Color(white: 0.15))
                                .aspectRatio(16/9, contentMode: .fit)
                        }
                        .resizable()
                        .aspectRatio(16/9, contentMode: .fill)
                        .frame(maxWidth: .infinity)
                        .clipped()
                    
                    if !video.durationString.isEmpty {
                        Text(video.durationString)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color.black.opacity(0.85))
                            .cornerRadius(4)
                            .padding(.trailing, 10)
                            .padding(.bottom, 10)
                    }
                }
            }
            .buttonStyle(.plain)
            
            // Channel avatar, Title & Metadata
            HStack(alignment: .top, spacing: 14) {
                Button(action: onTap) {
                    Group {
                        if let channelThumb = video.channelThumbnailURL {
                            KFImage(channelThumb)
                                .placeholder {
                                    Circle().fill(Color.gray.opacity(0.3))
                                }
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 38, height: 38)
                                .clipShape(Circle())
                        } else {
                            ZStack {
                                Circle()
                                    .fill(Color.red.opacity(0.8))
                                    .frame(width: 38, height: 38)
                                Text(String(video.channelName.prefix(1)).uppercased())
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                }
                .buttonStyle(.plain)
                
                Button(action: onTap) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(video.title)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.white)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                            .lineSpacing(2)
                        
                        Text(metadataSubtitle)
                            .font(.system(size: 12))
                            .foregroundColor(Color.white.opacity(0.6))
                            .lineLimit(1)
                    }
                }
                .buttonStyle(.plain)
                
                Spacer(minLength: 0)
                
                VideoMoreActionsMenu(video: video)
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)
            .padding(.bottom, 18)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
        .background(Color.black)
    }
}
