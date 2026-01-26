//
//  FavoritesView.swift
//  MovieTracker
//
//  Created by Tobias Fu on 1/15/26.
//

import SwiftUI

struct FavoritesView: View {
    let store: FavoritesStore

    var body: some View {
        NavigationStack {
            if store.isLoading && store.favoriteMovies.isEmpty {
                ProgressView()
            } else {
                List {
                    ForEach(store.favoriteMovies) { movie in
                        NavigationLink(movie.title, value: movie)
                    }
                    // Pagination: load more when reaching end
                    if store.currentPage < (store.totalPages ?? 1) {
                        ProgressView()
                            .task {
                                await store.loadNextPage()
                            }
                    }
                }
                .navigationDestination(for: Movie.self) { movie in
                    MovieDetailView(movie: movie, favoritesStore: store)
                }
                .refreshable {
                    await store.refresh()
                }
            }
        }
        .navigationTitle("Favorites")
        .task {
            await store.loadFavorites()
        }
    }
}

#Preview {
    FavoritesView(store: FavoritesStore(service: MovieService()))
}
