//
//  ContentView.swift
//  MovieTracker
//
//  Created by Tobias Fu on 1/10/26.
//

import SwiftUI

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
                            await vm.loadPage()
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
            await vm.search()
        }
        .alert("Error", isPresented: $vm.showError) {
            Button("OK") {
                vm.errorMessage = nil
                vm.isLoading = false
            }
        } message: {
            Text(vm.errorMessage ?? "")
        }
    }
}

@MainActor @Observable
final class MovieListViewModel {
    nonisolated private let service: MovieServiceProtocol
    var mode: Mode = .discover
    var searchText: String = ""
    var isLoading: Bool = false
    var showError: Bool = false
    var movies = [Movie]()
    var errorMessage: String?
    var currentPage: Int = 1
    var totalPages: Int?
    private(set) var loadedIDs = Set<Int>()
    
    nonisolated init(service: MovieServiceProtocol = MovieService()) {
        self.service = service
    }
    
    func loadPage() async {
        currentPage += 1
        await fetchAndAppend()
    }

    func resetAndLoad() async {
        currentPage = 1
        loadedIDs.removeAll()
        movies.removeAll()
        await fetchAndAppend()
    }

    private func fetchAndAppend() async {
        do {
            let response = try await service.performRequest(mode: mode, page: currentPage)
            let newMovies = response.results.filter { loadedIDs.insert($0.id).inserted }
            movies.append(contentsOf: newMovies)
            totalPages = response.totalPages
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    
    
    func search() async {
        if !searchText.isEmpty {
            mode = .search(searchText: searchText)
        } else {
            mode = .discover
        }
        isLoading = true
        await resetAndLoad()
        isLoading = false
    }
}

#Preview {
    MovieListView()
}
