//
//  MovieTrackerApp.swift
//  MovieTracker
//
//  Created by Tobias Fu on 1/10/26.
//

import SwiftUI
import SwiftData

@main
struct MovieTrackerApp: App {
    @State private var favoritesStore = FavoritesStore()
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(favoritesStore)
        }
    }
}
