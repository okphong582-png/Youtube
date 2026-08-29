import SwiftUI
import LNPopupUI
import Kingfisher
import OSLog
import UIKit

/// Root TabView replicating the authentic "Youtube giao diện" 5-tab shell,
/// persistent LNPopupUI mini-player & full-screen player, with NO login requirement.
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
        .sheet(isPresented: $isShowingCreateSheet) {
            createSheetView
                .presentationDetents([.fraction(0.42)])
                .preferredColorScheme(.dark)
        }
        .popup(
            isBarPresented: $player.miniPlayerVisible,
            isPopupOpen: $player.fullScreenPresented
        ) {
            PopupContentWrapper(thumbnail: thumbnail)
        }
        .popupInteractionStyle(UIViewController.PopupInteractionStyle.drag)
        .popupCloseButtonStyle(LNPopupCloseButton.Style.none)
        .popupBarStyle(LNPopupBar.Style.prominent)
        .popupBarProgressViewStyle(.bottom)
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
            let key = KingfisherManager.shared.cacheKey(for: url)
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

/// Hosts the popup's `FullScreenPlayer` and all of its `popup*(...)` metadata modifiers.
@available(iOS 17.0, *)
struct PopupContentWrapper: View {
    @Environment(PlayerStateManager.self) private var player
    let thumbnail: UIImage?
    
    @State private var progress: Float = 0
    @State private var subtitleText: String = ""
    
    var body: some View {
        FullScreenPlayer()
            .popupTitle(player.currentVideo?.title ?? "", subtitle: subtitleText)
            .popupImage(image)
            .popupProgress(progress)
            .popupBarButtons {
                ToolbarItemGroup(placement: .popupBar) {
                    Button {
                        player.togglePlayPause()
                    } label: {
                        Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                            .foregroundStyle(Color.primary)
                    }
                    Button {
                        player.playNext()
                    } label: {
                        Image(systemName: "forward.fill")
                            .foregroundStyle(Color.primary)
                    }
                }
            }
            .onChange(of: player.elapsed, initial: true) { _, _ in
                refreshProgress()
            }
            .onChange(of: player.duration) { _, _ in
                refreshProgress()
            }
            .onChange(of: player.loadState, initial: true) { _, _ in
                refreshProgress()
                subtitleText = computedSubtitle
            }
            .onChange(of: player.currentVideo?.id, initial: true) { _, _ in
                subtitleText = computedSubtitle
            }
    }
    
    private func refreshProgress() {
        let next = Self.progress(for: player)
        if abs(next - progress) > 0.001 {
            progress = next
        }
    }
    
    static func progress(for player: PlayerStateManager) -> Float {
        if case .downloading(let progress, _) = player.loadState {
            return Float(progress ?? 0)
        }
        guard player.duration > 0 else { return 0 }
        return Float(min(1, max(0, player.elapsed / player.duration)))
    }
    
    private var computedSubtitle: String {
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
    
    private var image: Image {
        switch player.loadState {
        case .resolving, .downloading:
            return Image(systemName: "arrow.down.circle.fill")
        default:
            if let thumbnail {
                return Image(uiImage: thumbnail)
            }
            return Image(systemName: "play.rectangle.fill")
        }
    }
}
