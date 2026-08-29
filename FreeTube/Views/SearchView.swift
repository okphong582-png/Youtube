import SwiftUI
import SwiftData

/// Dedicated full-screen YouTube Search View with live autocomplete,
/// search history, and real search results displaying YouTubeVideoCard.
@available(iOS 17.0, *)
struct SearchView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(PlayerStateManager.self) private var player
    @Environment(\.modelContext) private var modelContext
    
    @State private var searchModel = SearchViewModel()
    @FocusState private var isFieldFocused: Bool
    
    @Query(sort: \SearchHistoryEntry.searchedAt, order: .reverse)
    private var history: [SearchHistoryEntry]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Custom Search Header
                searchBarHeader
                
                // Search Body
                Group {
                    if searchModel.isLoading && searchModel.results == nil {
                        VStack {
                            Spacer()
                            ProgressView()
                                .tint(.red)
                                .scaleEffect(1.3)
                            Spacer()
                        }
                    } else if let results = searchModel.results {
                        searchResultsList(results)
                    } else if !searchModel.suggestions.isEmpty {
                        suggestionsList
                    } else {
                        recentSearchesList
                    }
                }
            }
            .background(Color.black.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .onAppear {
                isFieldFocused = true
            }
        }
    }
    
    // MARK: - Search Bar Header
    private var searchBarHeader: some View {
        HStack(spacing: 12) {
            Button(action: {
                dismiss()
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.plain)
            
            HStack(spacing: 8) {
                TextField("Tìm kiếm HoàngHa", text: $searchModel.query)
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .focused($isFieldFocused)
                    .submitLabel(.search)
                    .onSubmit {
                        Task { await performSearch(searchModel.query) }
                    }
                
                if !searchModel.query.isEmpty {
                    Button(action: {
                        searchModel.query = ""
                        searchModel.clearResults()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                            .font(.system(size: 18))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(white: 0.16))
            .cornerRadius(20)
            
            Button(action: {
                Task { await performSearch(searchModel.query) }
            }) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.black)
    }
    
    // MARK: - Results List
    private func searchResultsList(_ results: SearchResult) -> some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if results.videos.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)
                        Text("Không tìm thấy kết quả phù hợp")
                            .font(.system(size: 16))
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 60)
                } else {
                    ForEach(results.videos) { video in
                        YouTubeVideoCard(video: video, onTap: {
                            player.load(video)
                        })
                        .onAppear {
                            if video.id == results.videos.last?.id {
                                Task { await searchModel.loadMore() }
                            }
                        }
                    }
                    
                    if searchModel.isLoading {
                        ProgressView()
                            .tint(.red)
                            .padding(.vertical, 16)
                    }
                }
            }
            .padding(.bottom, 80)
        }
    }
    
    // MARK: - Autocomplete Suggestions
    private var suggestionsList: some View {
        List {
            ForEach(searchModel.suggestions, id: \.text) { suggestion in
                HStack(spacing: 14) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                        .font(.system(size: 15))
                    
                    Text(suggestion.text)
                        .foregroundColor(.white)
                        .font(.system(size: 15))
                    
                    Spacer()
                    
                    Button(action: {
                        searchModel.query = suggestion.text
                    }) {
                        Image(systemName: "arrow.up.left")
                            .foregroundColor(.gray)
                            .font(.system(size: 14))
                    }
                    .buttonStyle(.plain)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    searchModel.query = suggestion.text
                    Task { await performSearch(suggestion.text) }
                }
                .listRowBackground(Color.black)
                .listRowSeparatorTint(Color(white: 0.15))
            }
        }
        .listStyle(.plain)
    }
    
    // MARK: - Recent Searches
    private var recentSearchesList: some View {
        List {
            if !history.isEmpty {
                Section(header:
                    HStack {
                        Text("Tìm kiếm gần đây")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white.opacity(0.7))
                        Spacer()
                    }
                    .padding(.vertical, 4)
                ) {
                    ForEach(history.prefix(10)) { entry in
                        HStack(spacing: 14) {
                            Image(systemName: "clock.arrow.circlepath")
                                .foregroundColor(.gray)
                                .font(.system(size: 15))
                            
                            Text(entry.query)
                                .foregroundColor(.white)
                                .font(.system(size: 15))
                            
                            Spacer()
                            
                            Button(action: {
                                modelContext.delete(entry)
                                try? modelContext.save()
                            }) {
                                Image(systemName: "xmark")
                                    .foregroundColor(.gray)
                                    .font(.system(size: 13))
                            }
                            .buttonStyle(.plain)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            searchModel.query = entry.query
                            Task { await performSearch(entry.query) }
                        }
                        .listRowBackground(Color.black)
                        .listRowSeparatorTint(Color(white: 0.15))
                    }
                }
            }
        }
        .listStyle(.plain)
    }
    
    // MARK: - Actions
    private func performSearch(_ text: String) async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        isFieldFocused = false
        
        if let existing = history.first(where: { $0.query == trimmed }) {
            existing.searchedAt = .now
        } else {
            modelContext.insert(SearchHistoryEntry(query: trimmed))
        }
        try? modelContext.save()
        
        await searchModel.submit()
    }
}
