//
//  ContentView.swift
//  MovieTracker
//
//  Created by Tobias Fu on 1/14/26.
//

import SwiftUI

struct ContentView: View {
    let favoritesStore: FavoritesStore
    let movieListViewModel: MovieListViewModel

    var body: some View {
        TabView {
            Tab("Discover", systemImage: "magnifyingglass") {
                MovieListView(viewModel: movieListViewModel, favoritesStore: favoritesStore)
            }
            Tab("Favorites", systemImage: "star.fill") {
                FavoritesView(store: favoritesStore)
            }
        }
    }
}

#Preview {
    let service = MovieService()
    ContentView(
        favoritesStore: FavoritesStore(service: service),
        movieListViewModel: MovieListViewModel(service: service)
    )
}
