import SwiftUI
import Kingfisher

/// Full-screen vertical Shorts feed matching "Youtube giao diện",
/// backed by real trending/short videos and playback.
@available(iOS 17.0, *)
struct ShortView: View {
    @State private var homeModel = HomeViewModel()
    @State private var isShowingSearch = false
    @Environment(PlayerStateManager.self) private var player
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                let videos = homeModel.sections.flatMap(\.videos)
                
                if videos.isEmpty && homeModel.isLoading {
                    ProgressView().tint(.red).scaleEffect(1.2)
                } else if !videos.isEmpty {
                    TabView {
                        ForEach(videos) { video in
                            ShortPage(video: video, onPlay: {
                                player.load(video)
                            })
                            .rotationEffect(.degrees(-90))
                            .frame(
                                width: UIScreen.main.bounds.width,
                                height: UIScreen.main.bounds.height
                            )
                        }
                    }
                    .frame(
                        width: UIScreen.main.bounds.height,
                        height: UIScreen.main.bounds.width
                    )
                    .rotationEffect(.degrees(90), anchor: .topLeading)
                    .offset(x: UIScreen.main.bounds.width)
                    .tabViewStyle(.page(indexDisplayMode: .never))
                }
                
                // Top controls overlay
                VStack {
                    HStack(spacing: 20) {
                        Text("Shorts")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Button(action: { isShowingSearch = true }) {
                            if let _ = UIImage(named: "Search_bold") {
                                Image("Search_bold").resizable().frame(width: 22, height: 22)
                            } else {
                                Image(systemName: "magnifyingglass").font(.system(size: 20, weight: .bold)).foregroundColor(.white)
                            }
                        }
                        .buttonStyle(.plain)
                        
                        Button(action: {}) {
                            if let _ = UIImage(named: "Camera_bold") {
                                Image("Camera_bold").resizable().frame(width: 22, height: 22)
                            } else {
                                Image(systemName: "camera.fill").font(.system(size: 20, weight: .bold)).foregroundColor(.white)
                            }
                        }
                        .buttonStyle(.plain)
                        
                        Button(action: {}) {
                            if let _ = UIImage(named: "More_bold") {
                                Image("More_bold").resizable().frame(width: 22, height: 22)
                            } else {
                                Image(systemName: "ellipsis").font(.system(size: 20, weight: .bold)).foregroundColor(.white)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 48)
                    
                    Spacer()
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .fullScreenCover(isPresented: $isShowingSearch) {
                SearchView()
            }
            .task {
                if homeModel.sections.isEmpty {
                    await homeModel.load()
                }
            }
        }
    }
}

@available(iOS 17.0, *)
private struct ShortPage: View {
    let video: Video
    let onPlay: () -> Void
    
    @State private var isLiked = false
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Video Thumbnail / Tap to play
            Button(action: onPlay) {
                ZStack {
                    KFImage(video.thumbnailURL)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .clipped()
                    
                    // Play icon overlay hint
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 54))
                        .foregroundColor(.white.opacity(0.85))
                        .shadow(radius: 8)
                }
            }
            .buttonStyle(.plain)
            
            // Bottom gradient overlay
            LinearGradient(
                colors: [Color.clear, Color.black.opacity(0.85)],
                startPoint: .center,
                endPoint: .bottom
            )
            .allowsHitTesting(false)
            
            // Interaction row
            HStack(alignment: .bottom) {
                // Video Info
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 10) {
                        if let channelThumb = video.channelThumbnailURL {
                            KFImage(channelThumb)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 34, height: 34)
                                .clipShape(Circle())
                        } else {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 34, height: 34)
                        }
                        
                        Text(video.channelName)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Text("Đăng ký")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.black)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.white)
                            .cornerRadius(16)
                    }
                    
                    Text(video.title)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .lineLimit(2)
                    
                    HStack(spacing: 6) {
                        Image(systemName: "music.note")
                            .font(.system(size: 12))
                            .foregroundColor(.white)
                        Text("Âm thanh gốc - \(video.channelName)")
                            .font(.system(size: 13))
                            .foregroundColor(.white)
                            .lineLimit(1)
                    }
                }
                .padding(.bottom, 60)
                
                Spacer()
                
                // Action Buttons
                VStack(spacing: 22) {
                    Button(action: { isLiked.toggle() }) {
                        VStack(spacing: 4) {
                            Image(systemName: isLiked ? "hand.thumbsup.fill" : "hand.thumbsup")
                                .font(.system(size: 24))
                                .foregroundColor(isLiked ? .red : .white)
                            Text(isLiked ? "1" : "Thích")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.white)
                        }
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: {}) {
                        VStack(spacing: 4) {
                            Image(systemName: "hand.thumbsdown")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                            Text("Không thích")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.white)
                        }
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: {}) {
                        VStack(spacing: 4) {
                            Image(systemName: "ellipsis.bubble.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                            Text("Bình luận")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.white)
                        }
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: {
                        if let url = URL(string: "https://www.youtube.com/watch?v=\(video.id)") {
                            UIPasteboard.general.string = url.absoluteString
                        }
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: "arrowshape.turn.up.right.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                            Text("Chia sẻ")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.white)
                        }
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: onPlay) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 22))
                            .foregroundColor(.white)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.bottom, 60)
            }
            .padding(.horizontal, 16)
        }
    }
}
