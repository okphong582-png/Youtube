import SwiftUI
import Kingfisher

/// Subscriptions screen matching "Youtube giao diện",
/// showing channel avatars, category chips, and subscription feed videos.
@available(iOS 17.0, *)
struct SubscriptionView: View {
    @State private var homeModel = HomeViewModel()
    @State private var isShowingSearch = false
    @State private var selectedFilter = "Tất cả"
    @Environment(PlayerStateManager.self) private var player
    
    private let filters = ["Tất cả", "Hôm nay", "Tiếp tục xem", "Chưa xem", "Trực tiếp"]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Topbar
                topBar
                
                // Content
                ScrollView {
                    VStack(spacing: 14) {
                        // Online / Subscribed Channels Carousel
                        channelsCarousel
                        
                        // Filter Chips
                        filterChips
                        
                        // Videos
                        let videos = homeModel.sections.flatMap(\.videos)
                        if videos.isEmpty && homeModel.isLoading {
                            ProgressView().tint(.red).padding(.top, 40)
                        } else {
                            LazyVStack(spacing: 16) {
                                ForEach(videos) { video in
                                    YouTubeVideoCard(video: video, onTap: {
                                        player.load(video)
                                    })
                                }
                            }
                        }
                    }
                    .padding(.bottom, 80)
                }
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
    
    private var channelsCarousel: some View {
        let videos = homeModel.sections.flatMap(\.videos)
        let uniqueChannels = Array(Dictionary(grouping: videos, by: \.channelName).values.compactMap(\.first))
        
        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(uniqueChannels.prefix(10)) { video in
                    VStack(spacing: 6) {
                        ZStack(alignment: .bottomTrailing) {
                            if let thumb = video.channelThumbnailURL {
                                KFImage(thumb)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 56, height: 56)
                                    .clipShape(Circle())
                            } else {
                                Circle()
                                    .fill(Color(white: 0.2))
                                    .frame(width: 56, height: 56)
                                    .overlay(
                                        Text(String(video.channelName.prefix(1)).uppercased())
                                            .font(.system(size: 20, weight: .bold))
                                            .foregroundColor(.white)
                                    )
                            }
                            
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 10, height: 10)
                                .padding(2)
                                .background(Color.black)
                                .clipShape(Circle())
                        }
                        
                        Text(video.channelName)
                            .font(.system(size: 12))
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .frame(width: 68)
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 8)
        }
    }
    
    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(filters, id: \.self) { filter in
                    ChipWidget(
                        text: filter,
                        isActive: selectedFilter == filter,
                        action: { selectedFilter = filter }
                    )
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
        }
    }
}
