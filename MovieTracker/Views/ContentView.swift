//
//  ContentView.swift
//  MovieTracker
//
//  Created by Tobias Fu on 1/14/26.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            Tab("Discover", systemImage: "magnifyingglass") {
                MovieListView()
            }
            Tab("Favorites", systemImage: "star.fill") {
                FavoritesView()
            }
        }
    }
}

#Preview {
    ContentView()
}
