import SwiftUI
import Kingfisher
import OSLog
import UIKit

/// Root TabView replicating the authentic "Youtube giao diện" 5-tab shell,
/// persistent native YouTube mini-player & full-screen player, with NO login requirement.
@available(iOS 17.0, *)
struct RootView: View {
    @Environment(PlayerStateManager.self) private var player
    @State private var selectedTab: Tab = .home
    @State private var oldSelectedTab: Tab = .home
    @State private var isShowingCreateSheet = false
    @State private var thumbnail: UIImage?
    
    enum Tab: Int, Hashable {
        case home = 0
        case shorts = 1
        case add = 2
        case subscriptions = 3
        case library = 4
    }
    
    var body: some View {
        @Bindable var player = player
        
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                HomeView()
                    .tabItem {
                        if let _ = UIImage(named: selectedTab == .home ? "Home_Fill" : "Home") {
                            Image(selectedTab == .home ? "Home_Fill" : "Home")
                        } else {
                            Image(systemName: selectedTab == .home ? "house.fill" : "house")
                        }
                        Text("Trang chủ")
                    }
                    .tag(Tab.home)
                
                ShortView()
                    .tabItem {
                        if let _ = UIImage(named: selectedTab == .shorts ? "Short_Fill" : "Short") {
                            Image(selectedTab == .shorts ? "Short_Fill" : "Short")
                        } else {
                            Image(systemName: selectedTab == .shorts ? "play.square.stack.fill" : "play.square.stack")
                        }
                        Text("Shorts")
                    }
                    .tag(Tab.shorts)
                
                Color.black
                    .tabItem {
                        if let _ = UIImage(named: "Add") {
                            Image("Add")
                        } else {
                            Image(systemName: "plus.circle")
                        }
                    }
                    .tag(Tab.add)
                
                SubscriptionView()
                    .tabItem {
                        if let _ = UIImage(named: selectedTab == .subscriptions ? "Subscriptions_Fill" : "Subscriptions") {
                            Image(selectedTab == .subscriptions ? "Subscriptions_Fill" : "Subscriptions")
                        } else {
                            Image(systemName: selectedTab == .subscriptions ? "rectangle.stack.fill" : "rectangle.stack")
                        }
                        Text("Đăng ký")
                    }
                    .tag(Tab.subscriptions)
                
                LibraryView()
                    .tabItem {
                        if let _ = UIImage(named: selectedTab == .library ? "Library_Fill" : "Library") {
                            Image(selectedTab == .library ? "Library_Fill" : "Library")
                        } else {
                            Image(systemName: selectedTab == .library ? "folder.fill" : "folder")
                        }
                        Text("Bạn")
                    }
                    .tag(Tab.library)
            }
            .accentColor(.white)
            .onChange(of: selectedTab) { oldTab, newTab in
                if newTab == .add {
                    isShowingCreateSheet = true
                    selectedTab = oldTab
                } else {
                    oldSelectedTab = newTab
                }
            }
            
            // Native YouTube floating mini-player docked above tab bar
            if player.miniPlayerVisible && !player.fullScreenPresented, let video = player.currentVideo {
                miniPlayerBar(video: video)
                    .padding(.bottom, 49)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .fullScreenCover(isPresented: $player.fullScreenPresented) {
            FullScreenPlayer()
                .environment(player)
        }
        .sheet(isPresented: $isShowingCreateSheet) {
            createSheetView
                .presentationDetents([.fraction(0.42)])
                .preferredColorScheme(.dark)
        }
        .task {
            // Anonymous bootstrap — ensure visitor token is loaded for video streaming
            await YouTubeKitClient.shared.ensureVisitorData()
        }
        .onChange(of: player.currentVideo?.id, initial: true) {
            loadThumbnailForCurrentVideo()
        }
        .onChange(of: player.fullScreenPresented) { _, presented in
            updateStatusBarOverride(forFullScreenOpen: presented)
        }
    }
    
    // MARK: - Native Mini-Player Bar
    private func miniPlayerBar(video: Video) -> some View {
        VStack(spacing: 0) {
            // 2pt playback progress bar
            GeometryReader { geo in
                let pct = progressValue
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.white.opacity(0.18))
                        .frame(width: geo.size.width, height: 2)
                    Rectangle()
                        .fill(Color.red)
                        .frame(width: max(0, min(geo.size.width, geo.size.width * CGFloat(pct))), height: 2)
                }
            }
            .frame(height: 2)
            
            HStack(spacing: 12) {
                // Video thumbnail
                ZStack {
                    if let thumbnail {
                        Image(uiImage: thumbnail)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else if let url = video.thumbnailURL {
                        KFImage(url)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        Rectangle()
                            .fill(Color(white: 0.2))
                    }
                }
                .frame(width: 72, height: 42)
                .clipped()
                .cornerRadius(4)
                
                // Title and Channel Name
                VStack(alignment: .leading, spacing: 3) {
                    Text(video.title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Text(subtitleText.isEmpty ? video.channelName : subtitleText)
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
                
                Spacer(minLength: 4)
                
                // Play / Pause Button
                Button {
                    player.togglePlayPause()
                } label: {
                    Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                        .frame(width: 38, height: 38)
                }
                .buttonStyle(.plain)
                
                // Close Button
                Button {
                    player.pause()
                    withAnimation(.easeInOut(duration: 0.2)) {
                        player.miniPlayerVisible = false
                    }
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 38, height: 38)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .frame(height: 52)
        }
        .background(
            Color(white: 0.13)
                .shadow(color: .black.opacity(0.45), radius: 6, x: 0, y: -2)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            player.fullScreenPresented = true
        }
    }
    
    private var progressValue: Float {
        if case .downloading(let progress, _) = player.loadState {
            return Float(progress ?? 0)
        }
        guard player.duration > 0 else { return 0 }
        return Float(min(1, max(0, player.elapsed / player.duration)))
    }
    
    private var subtitleText: String {
        switch player.loadState {
        case .resolving:
            return "Đang tải video…"
        case .downloading(let progress, _):
            guard let progress else { return "Đang xử lý…" }
            return "Đang tải xuống \(Int(progress * 100))%"
        case .failed(let msg):
            return msg
        case .idle, .readyToPlay:
            return player.currentVideo?.channelName ?? ""
        }
    }
    
    // MARK: - Create Sheet View
    private var createSheetView: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Text("Tạo")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
                Button(action: { isShowingCreateSheet = false }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.gray)
                        .padding(6)
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 14)
            .padding(.bottom, 6)
            
            createRow(icon: "Short", fallback: "play.square.stack", text: "Tạo một video ngắn")
            createRow(icon: "Upload", fallback: "arrow.up.circle", text: "Tải video lên")
            createRow(icon: "Wave", fallback: "antenna.radiowaves.left.and.right", text: "Phát trực tiếp")
            createRow(icon: "Edit", fallback: "pencil.line", text: "Tạo bài đăng")
            
            Spacer()
        }
        .padding(.horizontal, 18)
        .background(Color(white: 0.12).ignoresSafeArea())
    }
    
    private func createRow(icon: String, fallback: String, text: String) -> some View {
        Button(action: { isShowingCreateSheet = false }) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color(white: 0.22))
                        .frame(width: 44, height: 44)
                    if let _ = UIImage(named: icon) {
                        Image(icon).resizable().frame(width: 22, height: 22)
                    } else {
                        Image(systemName: fallback).font(.system(size: 18)).foregroundColor(.white)
                    }
                }
                Text(text)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                Spacer()
            }
        }
        .buttonStyle(.plain)
    }
    
    private func updateStatusBarOverride(forFullScreenOpen open: Bool) {
        let scene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first(where: { $0.activationState == .foregroundActive })
            ?? UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first
        let window = scene?.windows.first(where: \.isKeyWindow) ?? scene?.windows.first
        window?.overrideUserInterfaceStyle = open ? .dark : .unspecified
    }
    
    private func loadThumbnailForCurrentVideo() {
        guard let current = player.currentVideo else {
            thumbnail = nil
            return
        }
        if let url = current.thumbnailURL {
            let key = url.absoluteString
            if let cached = KingfisherManager.shared.cache.retrieveImageInMemoryCache(forKey: key) {
                thumbnail = cached
                return
            }
            KingfisherManager.shared.retrieveImage(with: url) { result in
                if case .success(let value) = result {
                    Task { @MainActor in
                        if player.currentVideo?.id == current.id {
                            thumbnail = value.image
                        }
                    }
                }
            }
        }
    }
}
