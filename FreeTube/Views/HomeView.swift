import SwiftUI

/// Main YouTube Home Feed screen matching "Youtube giao diện",
/// powered by real YouTube data via `HomeViewModel` and FreeTube's player engine.
@available(iOS 17.0, *)
struct HomeView: View {
    @State private var homeModel = HomeViewModel()
    @State private var isShowingSearch = false
    @State private var selectedChip = "Tất cả"
    @Environment(PlayerStateManager.self) private var player
    
    private let categories = [
        "Tất cả", "Âm nhạc", "Trò chơi", "Tin tức", "Giải trí", "Học tập", "Podcasts"
    ]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Top Navigation Bar
                customTopBar
                
                // Horizontal Filter Chips
                chipsScrollView
                
                // Main Content List
                contentList
            }
            .background(Color.black.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .fullScreenCover(isPresented: $isShowingSearch) {
                SearchView()
            }
            .task {
                if homeModel.sections.isEmpty {
                    await homeModel.load()
                }
            }
            .refreshable {
                await homeModel.refresh()
            }
        }
    }
    
    // MARK: - Top Navigation Bar
    private var customTopBar: some View {
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
            
            Button(action: {
                isShowingSearch = true
            }) {
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
    
    // MARK: - Chips
    private var chipsScrollView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                // Explore Button
                HStack {
                    if let _ = UIImage(named: "Explore") {
                        Image("Explore").resizable().frame(width: 20, height: 20)
                    } else {
                        Image(systemName: "safari").font(.system(size: 16)).foregroundColor(.white)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(white: 0.18))
                .cornerRadius(8)
                .padding(.leading, 14)
                
                ForEach(categories, id: \.self) { category in
                    ChipWidget(
                        text: category,
                        isActive: selectedChip == category,
                        action: {
                            selectedChip = category
                        }
                    )
                }
            }
            .padding(.trailing, 14)
            .padding(.vertical, 6)
        }
        .background(Color.black)
    }
    
    // MARK: - Content List
    private var contentList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if homeModel.isLoading && homeModel.sections.isEmpty {
                    VStack {
                        Spacer(minLength: 40)
                        ProgressView().tint(.red).scaleEffect(1.2)
                        Spacer(minLength: 40)
                    }
                }
                
                let allVideos = homeModel.sections.flatMap(\.videos)
                
                // First 2 videos
                ForEach(Array(allVideos.prefix(2))) { video in
                    YouTubeVideoCard(video: video, onTap: {
                        player.load(video)
                    })
                }
                
                // Shorts Shelf (if we have more than 4 videos, use some as shorts preview)
                if allVideos.count >= 4 {
                    shortsShelf(Array(allVideos.dropFirst(2).prefix(4)))
                }
                
                // Remaining videos
                ForEach(Array(allVideos.dropFirst(4))) { video in
                    YouTubeVideoCard(video: video, onTap: {
                        player.load(video)
                    })
                    .onAppear {
                        if video.id == allVideos.last?.id {
                            Task { await homeModel.loadMore() }
                        }
                    }
                }
                
                if homeModel.isLoading && !homeModel.sections.isEmpty {
                    ProgressView().tint(.red).padding(.vertical, 16)
                }
            }
            .padding(.bottom, 80)
        }
    }
    
    // MARK: - Shorts Shelf
    private func shortsShelf(_ videos: [Video]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                if let _ = UIImage(named: "Short_Color") {
                    Image("Short_Color").resizable().frame(width: 22, height: 22)
                } else {
                    Image(systemName: "play.square.stack.fill").foregroundColor(.red).font(.system(size: 20))
                }
                
                Text("Shorts")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 14)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(videos) { video in
                        YouTubeShortCard(video: video, onTap: {
                            player.load(video)
                        })
                    }
                }
                .padding(.horizontal, 14)
            }
        }
        .padding(.vertical, 10)
    }
}
