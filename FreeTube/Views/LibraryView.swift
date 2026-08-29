import SwiftUI
import SwiftData
import Kingfisher

/// Library screen matching "Youtube giao diện",
/// showing local watch history, downloads, and favorites with NO login prompt.
@available(iOS 17.0, *)
struct LibraryView: View {
    @Environment(PlayerStateManager.self) private var player
    @Environment(\.modelContext) private var modelContext
    
    @Query(sort: \WatchHistoryEntry.watchedAt, order: .reverse)
    private var history: [WatchHistoryEntry]
    
    @Query private var favorites: [FavoriteVideo]
    
    @State private var isShowingSearch = false
    @State private var downloads = DownloadManager.shared
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Topbar
                topBar
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        // History Section
                        historySection
                        
                        Divider().background(Color(white: 0.2))
                        
                        // Menu Section
                        menuSection
                        
                        Divider().background(Color(white: 0.2))
                        
                        // Playlists Section
                        playlistsSection
                    }
                    .padding(.bottom, 80)
                }
            }
            .background(Color.black.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .fullScreenCover(isPresented: $isShowingSearch) {
                SearchView()
            }
        }
    }
    
    private var topBar: some View {
        HStack(spacing: 16) {
            HoangHaLogoView()
            Spacer()
            
            Button(action: {}) {
                if let _ = UIImage(named: "Cast") {
                    Image("Cast").resizable().renderingMode(.template).frame(width: 22, height: 22).foregroundColor(.white)
                } else {
                    Image(systemName: "airplayvideo").font(.system(size: 18)).foregroundColor(.white)
                }
            }
            .buttonStyle(.plain)
            
            Button(action: {}) {
                if let _ = UIImage(named: "Notification") {
                    Image("Notification").resizable().renderingMode(.template).frame(width: 22, height: 22).foregroundColor(.white)
                } else {
                    Image(systemName: "bell").font(.system(size: 18)).foregroundColor(.white)
                }
            }
            .buttonStyle(.plain)
            
            Button(action: { isShowingSearch = true }) {
                if let _ = UIImage(named: "Search") {
                    Image("Search").resizable().renderingMode(.template).frame(width: 22, height: 22).foregroundColor(.white)
                } else {
                    Image(systemName: "magnifyingglass").font(.system(size: 18)).foregroundColor(.white)
                }
            }
            .buttonStyle(.plain)
            
            if let profileImg = UIImage(named: "profile") {
                Image(uiImage: profileImg)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 26, height: 26)
                    .clipShape(Circle())
            } else {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .frame(width: 26, height: 26)
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .padding(.horizontal, 14)
        .padding(.top, 6)
        .padding(.bottom, 10)
        .background(Color.black)
    }
    
    private var historySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Gần đây")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.top, 10)
            
            if history.isEmpty {
                Text("Chưa có video nào trong lịch sử xem.")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(history.prefix(10)) { item in
                            Button(action: {
                                playHistory(item)
                            }) {
                                VStack(alignment: .leading, spacing: 6) {
                                    ZStack(alignment: .bottomLeading) {
                                        KFImage(item.thumbnailURL)
                                            .placeholder {
                                                RoundedRectangle(cornerRadius: 8)
                                                    .fill(Color(white: 0.18))
                                            }
                                            .resizable()
                                            .aspectRatio(16/9, contentMode: .fill)
                                            .frame(width: 140, height: 80)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                        
                                        // Red watch progress line
                                        if item.duration > 0 {
                                            let progress = min(1.0, max(0.05, item.lastPosition / item.duration))
                                            GeometryReader { geo in
                                                VStack {
                                                    Spacer()
                                                    Rectangle()
                                                        .fill(Color.red)
                                                        .frame(width: geo.size.width * progress, height: 3)
                                                }
                                            }
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                        }
                                    }
                                    .frame(width: 140, height: 80)
                                    
                                    Text(item.title)
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(.white)
                                        .lineLimit(2)
                                        .frame(width: 140, alignment: .leading)
                                    
                                    Text(item.channelName)
                                        .font(.system(size: 11))
                                        .foregroundColor(.gray)
                                        .lineLimit(1)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 14)
                }
            }
        }
    }
    
    private var menuSection: some View {
        VStack(spacing: 18) {
            menuRow(iconName: "History", systemFallback: "clock.arrow.circlepath", title: "Lịch sử")
            menuRow(iconName: "Play", systemFallback: "play.rectangle", title: "Video của bạn")
            menuRow(
                iconName: "Download",
                systemFallback: "arrow.down.circle",
                title: "Tải xuống",
                subtitle: "\(downloads.activeTasks.count) đang tải",
                trailing: Image(systemName: "checkmark.circle.fill").foregroundColor(.blue)
            )
            menuRow(iconName: "Movie", systemFallback: "film", title: "Phim của bạn")
            menuRow(iconName: "Clock", systemFallback: "clock", title: "Xem sau", subtitle: "Lưu trữ cá nhân")
        }
        .padding(.horizontal, 14)
    }
    
    private func menuRow(
        iconName: String,
        systemFallback: String,
        title: String,
        subtitle: String = "",
        trailing: (some View)? = Optional<EmptyView>.none
    ) -> some View {
        HStack(spacing: 20) {
            if let _ = UIImage(named: iconName) {
                Image(iconName).resizable().frame(width: 24, height: 24)
            } else {
                Image(systemName: systemFallback).font(.system(size: 20)).foregroundColor(.white).frame(width: 24, height: 24)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15))
                    .foregroundColor(.white)
                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            if let trailing {
                trailing
            }
        }
    }
    
    private var playlistsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Danh sách phát")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
                Text("Đã thêm gần đây")
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
                Image(systemName: "chevron.down")
                    .font(.system(size: 11))
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 14)
            
            Button(action: {}) {
                HStack(spacing: 16) {
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.blue)
                    Text("Danh sách phát mới")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.blue)
                    Spacer()
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 4)
            }
            .buttonStyle(.plain)
            
            HStack(spacing: 16) {
                Image(systemName: "hand.thumbsup.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
                    .frame(width: 32, height: 32)
                    .background(Color(white: 0.18))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Video đã thích")
                        .font(.system(size: 15))
                        .foregroundColor(.white)
                    Text("\(favorites.count) video")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
                Spacer()
            }
            .padding(.horizontal, 14)
        }
    }
    
    private func playHistory(_ item: WatchHistoryEntry) {
        let video = Video(
            id: item.videoID,
            title: item.title,
            channelID: "",
            channelName: item.channelName,
            channelThumbnailURL: nil,
            thumbnailURL: item.thumbnailURL,
            duration: item.duration > 0 ? item.duration : nil,
            viewCount: nil,
            publishedAt: item.watchedAt,
            descriptionSnippet: nil,
            isLive: false,
            isShort: false
        )
        player.load(video)
    }
}
