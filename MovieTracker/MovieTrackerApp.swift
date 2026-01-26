//
//  MovieTrackerApp.swift
//  MovieTracker
//
//  Created by Tobias Fu on 1/10/26.
//

import SwiftUI
import SwiftData
import SafeDICore

@main
struct MovieTrackerApp: App {
    let dependencies = AppDependencies()

    var body: some Scene {
        WindowGroup {
            ContentView(
                favoritesStore: dependencies.favoritesStore,
                movieListViewModel: dependencies.movieListViewModel
            )
        }
    }
}
