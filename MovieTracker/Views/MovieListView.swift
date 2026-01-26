//
//  MovieListView.swift
//  MovieTracker
//
//  Created by Tobias Fu on 1/10/26.
//

import SwiftUI

struct MovieListView: View {
    @Bindable var viewModel: MovieListViewModel
    let favoritesStore: FavoritesStore

    var body: some View {
        NavigationStack {
            if viewModel.isLoading {
                ProgressView()
            } else {
                List {
                    ForEach(viewModel.movies) { movie in
                        NavigationLink(movie.title, value: movie)
                    }

                    if viewModel.currentPage < (viewModel.totalPages ?? 0) {
                        ProgressView()
                            .task {
                                await viewModel.loadPage()
                            }
                    }
                }
                .navigationDestination(for: Movie.self) { movie in
                    MovieDetailView(movie: movie, favoritesStore: favoritesStore)
                }
            }
        }
        .navigationTitle("Movies")
        .searchable(text: $viewModel.searchText, prompt: "Search Movies")
        .task(id: viewModel.searchText) {
            await viewModel.search()
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK") {
                viewModel.errorMessage = nil
                viewModel.isLoading = false
            }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
}

#Preview {
    let service = MovieService()
    MovieListView(
        viewModel: MovieListViewModel(service: service),
        favoritesStore: FavoritesStore(service: service)
    )
}
