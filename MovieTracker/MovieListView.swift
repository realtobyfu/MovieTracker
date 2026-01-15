//
//  ContentView.swift
//  MovieTracker
//
//  Created by Tobias Fu on 1/10/26.
//

import SwiftUI

enum Mode: Equatable {
    case discover
    case search(searchText: String)
}

struct MovieListView: View {
    
    private var service = MovieService()
    
    @State private var mode: Mode = .discover
    @State private var searchText: String = ""
    
    @State private var isLoading: Bool = false
    @State private var movies = [Movie]()
    @State private var errorMessage: String?
    @State private var currentPage: Int = 1
    @State private var totalPages: Int?
    
    @State private var loadedIDs = Set<Int>()
    
    var body: some View {
        NavigationStack {
            if isLoading {
                ProgressView()
            } else {
                List {
                    ForEach(movies) { movie in
                        NavigationLink(movie.title, value: movie)
                    }
                    
                    if currentPage < (totalPages ?? 0) {
                        ProgressView()
                        .task {
                            currentPage += 1
                            try? await loadPage(mode: mode, page: currentPage)
                        }
                    }
                }
                .navigationDestination(for: Movie.self) { movie in
                    MovieDetailView(movie: movie)
                }
            }
        }
        .navigationTitle("Movies")
        .searchable(text: $searchText, prompt: "Search Movies")
        .task(id: searchText) {
            if !searchText.isEmpty {
                mode = .search(searchText: searchText)
            } else {
                mode = .discover
            }

            print(".task(id: mode) is triggered")
            isLoading = true
            defer { isLoading = false }
            do {
//                if currentPage == 1 {
                try await resetAndLoad(mode: mode)
                    
            } catch {
                errorMessage = error.localizedDescription
                movies = []
            }
        }
    }
    
    func loadPage(mode: Mode, page: Int) async throws {
        let response = try? await service.performRequest(mode: mode, page: page)
        let newMovies: [Movie] = (response?.results.filter{ loadedIDs.insert($0.id).inserted }) ?? []
        movies.append(contentsOf: newMovies)
        totalPages = response?.totalPages
    }
    
    
    
    func resetAndLoad(mode: Mode) async throws {
        currentPage = 1
        loadedIDs.removeAll()
        movies.removeAll()
        let response = try? await service.performRequest(mode: mode, page: currentPage)
        let newMovies: [Movie] = (response?.results.filter{ loadedIDs.insert($0.id).inserted }) ?? []
        movies.append(contentsOf: newMovies)
        totalPages = response?.totalPages
    }

}




#Preview {
    MovieListView()
}
