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
    @State var vm = MovieListViewModel()
    
    var body: some View {
        NavigationStack {
            if vm.isLoading {
                ProgressView()
            } else {
                List {
                    ForEach(vm.movies) { movie in
                        NavigationLink(movie.title, value: movie)
                    }
                    
                    if vm.currentPage < (vm.totalPages ?? 0) {
                        ProgressView()
                        .task {
                            vm.currentPage += 1
                            try? await vm.loadPage()
                        }
                    }
                }
                .navigationDestination(for: Movie.self) { movie in
                    MovieDetailView(movie: movie)
                }
            }
        }
        .navigationTitle("Movies")
        .searchable(text: $vm.searchText, prompt: "Search Movies")
        .task(id: vm.searchText) {
            if !vm.searchText.isEmpty {
                vm.mode = .search(searchText: vm.searchText)
            } else {
                vm.mode = .discover
            }

            print(".task(id: mode) is triggered")
            vm.isLoading = true
            defer { vm.isLoading = false }
            do {
                try await vm.resetAndLoad()
                    
            } catch {
                vm.errorMessage = error.localizedDescription
                vm.movies = []
            }
        }
    }
}

@MainActor @Observable
final class MovieListViewModel {
    private(set) var service = MovieService()
    var mode: Mode = .discover
    var searchText: String = ""
    var isLoading: Bool = false
    var movies = [Movie]()
    var errorMessage: String?
    var currentPage: Int = 1
    var totalPages: Int?
    private(set) var loadedIDs = Set<Int>()
    
    func loadPage() async throws {
        let response = try? await service.performRequest(mode: mode, page: currentPage)
        let newMovies: [Movie] = (response?.results.filter{ loadedIDs.insert($0.id).inserted }) ?? []
        movies.append(contentsOf: newMovies)
        totalPages = response?.totalPages
    }
    
    func resetAndLoad() async throws {
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
